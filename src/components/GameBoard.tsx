import { useState, useCallback } from 'react';
import type { Tile, GameState, AgariResult } from '../mahjong-bridge';
import {
  startGame, drawTile, discardTile, advanceTurn,
  checkTsumoAgari, canRon, checkRon, getTenpaiTiles, nextRound,
  declareRiichi, aiDecide, kazeToJa,
  canPon, doPon, canChi, doChi,
  canMinkan, doMinkan, canAnkan, doAnkan, canKakan, doKakan,
  canDeclareRiichi, riichiDiscardCandidates, riichiDiscardWithWaits,
  canKyuushu, declareKyuushu,
  aiShouldPon, aiShouldChi,
  getWaitCounts, getShanten, getDangerTiles,
  type RiichiDiscardOption,
} from '../mahjong-bridge';
import { PlayerHand } from './PlayerHand';
import { Kawa } from './Kawa';
import { CenterPanel } from './CenterPanel';
import { DoraDisplay } from './DoraDisplay';
import { AgariDialog } from './AgariDialog';
import { ScoreTransition } from './ScoreTransition';
import { AssistSettings, loadAssistConfig, type AssistConfig } from './AssistSettings';
import { AssistDisplay } from './AssistDisplay';
import { SoundSettings } from './SoundSettings';
import { useSound } from '../hooks/useSound';
import { saveMatch } from '../hooks/useMatchHistory';
import { TileView } from './TileView';

const HUMAN_SEAT = 0;

interface GameBoardProps {
  onBack?: () => void;
}

export function GameBoard({ onBack }: GameBoardProps) {
  const [state, setState] = useState<GameState | null>(null);
  const [selectedTile, setSelectedTile] = useState<number | null>(null);
  const [agariResult, setAgariResult] = useState<AgariResult | null>(null);
  const [agariWinner, setAgariWinner] = useState<string>('');
  const [tenpaiTiles, setTenpaiTiles] = useState<Tile[]>([]);
  const [message, setMessage] = useState<string>('');
  const [callInfo, setCallInfo] = useState<{ canPon: boolean; chiOptions: Tile[][]; canMinkan: boolean; canRon: boolean } | null>(null);
  const [riichiMode, setRiichiMode] = useState(false);
  const [chiSelectMode, setChiSelectMode] = useState(false);
  const [assistConfig, setAssistConfig] = useState<AssistConfig>(loadAssistConfig());
  const [showAssistSettings, setShowAssistSettings] = useState(false);
  const [showSoundSettings, setShowSoundSettings] = useState(false);
  const { playTsumo: playTsumoSound, playRon: playRonSound } = useSound();
  const [scoreTransition, setScoreTransition] = useState<{
    before: { jikaze: string; score: number }[];
    after: { jikaze: string; score: number }[];
    reason: string;
    oyaWon: boolean;
  } | null>(null);

  const handleStart = useCallback(() => {
    const newState = startGame();
    setState(newState);
    setSelectedTile(null);
    setAgariResult(null);
    setTenpaiTiles([]);
    setMessage('ゲーム開始！');
    setTimeout(() => {
      const drawn = drawTile();
      if (drawn) {
        handleTurnAfterDraw(drawn);
      }
    }, 300);
  }, []);

  const [riichiCandidates, setRiichiCandidates] = useState<Tile[]>([]);
  const [riichiOptions, setRiichiOptions] = useState<RiichiDiscardOption[]>([]);

  const handleRiichi = useCallback(() => {
    const candidates = riichiDiscardCandidates(HUMAN_SEAT);
    const options = riichiDiscardWithWaits(HUMAN_SEAT);
    setRiichiMode(true);
    setRiichiCandidates(candidates);
    setRiichiOptions(options);
    setMessage('リーチ！ 捨てる牌を選んでください');
  }, []);

  const isTileInCandidates = (tile: Tile, candidates: Tile[]) =>
    candidates.some(c => c.kind === tile.kind && c.suit === tile.suit && c.number === tile.number);

  const handleDiscard = useCallback((tile: Tile) => {
    if (!state || state.phase !== 'waiting_discard') return;
    if (state.current_turn !== HUMAN_SEAT) return;

    // リーチ後は操作不可（自動ツモ切り）
    if (state.players[HUMAN_SEAT].is_riichi) return;

    if (riichiMode) {
      // リーチ宣言時: 候補牌のみ捨てられる
      if (!isTileInCandidates(tile, riichiCandidates)) return;
      const riichiState = declareRiichi();
      if (riichiState) setState(riichiState);
      setRiichiMode(false);
      setRiichiCandidates([]);
      setRiichiOptions([]);
    }

    const newState = discardTile(tile);
    if (!newState) return;
    setState(newState);
    setSelectedTile(null);
    setTenpaiTiles([]);
    setMessage('');
    setTimeout(() => processAfterDiscard(newState), 300);
  }, [state, riichiMode, riichiCandidates]);

  const continueAfterCalls = useCallback(() => {
    setCallInfo(null);
    const advanced = advanceTurn();
    if (!advanced) return;
    processTurn(advanced);
  }, []);

  const processAfterDiscard = useCallback((currentState: GameState) => {
    // CPUのロン判定（自動）
    for (let i = 0; i < 4; i++) {
      if (i === currentState.current_turn) continue;
      if (i === HUMAN_SEAT) continue; // 人間は後で選択させる
      const ronResult = checkRon(i);
      if (ronResult) {
        playRonSound();
        setState(ronResult.state);
        setAgariResult(ronResult);
        setAgariWinner(`${kazeToJa(currentState.players[i].jikaze)}家`);
        setLastAgariWasDealerWin(currentState.players[i].jikaze === 'ton');
        return;
      }
    }

    // CPUの鳴き判断（Hard AIのみ）
    for (let i = 0; i < 4; i++) {
      if (i === currentState.current_turn) continue;
      if (i === HUMAN_SEAT) continue;
      // CPUのポン判断
      if (canPon(i) && aiShouldPon(i)) {
        const ponState = doPon(i);
        if (ponState) {
          setState(ponState);
          setMessage(`${kazeToJa(currentState.players[i].jikaze)}家がポン`);
          // ポン後はCPUが打牌
          setTimeout(() => {
            const aiAction = aiDecide(i);
            if (aiAction?.tile) {
              const afterDiscard = discardTile(aiAction.tile);
              if (afterDiscard) {
                setState(afterDiscard);
                setTimeout(() => processAfterDiscard(afterDiscard), 300);
              }
            }
          }, 500);
          return;
        }
      }
    }

    // 人間のロン・ポン・チー・明槓判定
    if (currentState.current_turn !== HUMAN_SEAT) {
      const humanCanRon = canRon(HUMAN_SEAT);

      const ponAvail = canPon(HUMAN_SEAT);
      const chiOptions = canChi(HUMAN_SEAT);
      const minkanAvail = canMinkan(HUMAN_SEAT);
      if (humanCanRon || ponAvail || chiOptions.length > 0 || minkanAvail) {
        setCallInfo({ canPon: ponAvail, chiOptions, canMinkan: minkanAvail, canRon: humanCanRon });
        setMessage(humanCanRon ? 'ロンしますか？' : '鳴きますか？');
        return;
      }
    }

    const advanced = advanceTurn();
    if (!advanced) return;
    processTurn(advanced);
  }, []);

  const [lastAgariWasDealerWin, setLastAgariWasDealerWin] = useState(false);

  /** 点数移行を表示した後に次の局へ */
  const showScoreAndAdvance = useCallback((reason: string, oyaWon: boolean, currentState?: GameState) => {
    const s = currentState ?? state;
    if (!s) return;
    const before = s.players.map(p => ({ jikaze: p.jikaze, score: p.score }));
    const wasAgari = reason === '和了';
    const next = nextRound(oyaWon, wasAgari);
    if (!next) return;
    const after = next.players.map(p => ({ jikaze: p.jikaze, score: p.score }));

    const hasChange = before.some((b, i) => b.score !== after[i]?.score);
    if (hasChange) {
      setScoreTransition({ before, after, reason, oyaWon });
      setTimeout(() => {
        setScoreTransition(null);
        startNextRound(next);
      }, 2500);
    } else {
      startNextRound(next);
    }
  }, [state]);

  const startNextRound = useCallback((next: GameState) => {
    setState(next);
    if (next.phase === 'game_end') {
      setMessage('ゲーム終了');
      // 対局結果を保存
      const sorted = [...next.players].sort((a, b) => b.score - a.score);
      saveMatch({
        id: Date.now().toString(),
        date: new Date().toLocaleString('ja-JP'),
        mode: 'single',
        players: next.players.map(p => ({ name: `${p.jikaze}家`, score: p.score, jikaze: p.jikaze })),
        winner: `${sorted[0].jikaze}家`,
      });
      return;
    }
    setMessage('次の局を開始します');
    setTimeout(() => {
      const drawn = drawTile();
      if (drawn) {
        handleTurnAfterDraw(drawn);
      }
    }, 500);
  }, []);

  /** ドロー済みの状態からCPU/人間のターン処理 */
  const handleTurnAfterDraw = useCallback((drawnState: GameState) => {
    setState(drawnState);
    // 流局チェック
    if (drawnState.phase === 'round_end' || drawnState.phase === 'game_end') {
      if (drawnState.phase === 'game_end') {
        setMessage('ゲーム終了');
      } else {
        setMessage('流局');
        const ds = drawnState;
        setTimeout(() => showScoreAndAdvance('流局', false, ds), 2000);
      }
      return;
    }
    if (drawnState.current_turn === HUMAN_SEAT) {
      const player = drawnState.players[HUMAN_SEAT];

      // リーチ済み: ツモ和了チェック → 自動ツモ切り
      if (player.is_riichi) {
        const tsumoResult = checkTsumoAgari();
        if (tsumoResult) {
          setMessage('ツモ和了できます！');
          // ツモ和了はボタンで選択させる（スキップも可能）
          return;
        }
        // 自動ツモ切り
        setMessage('リーチ中...');
        setTimeout(() => {
          const tsumoTile = player.tsumo;
          if (tsumoTile) {
            const newState = discardTile(tsumoTile);
            if (newState) {
              setState(newState);
              setTimeout(() => processAfterDiscard(newState), 300);
            }
          }
        }, 500);
        return;
      }

      setMessage('牌を選んで捨ててください');
      setTenpaiTiles(getTenpaiTiles());
      const tsumoResult = checkTsumoAgari();
      if (tsumoResult) setMessage('ツモ和了できます！');
      // 九種九牌チェック
      if (canKyuushu(HUMAN_SEAT)) setMessage('九種九牌で流局できます');
    } else {
      setMessage(`${kazeToJa(drawnState.players[drawnState.current_turn].jikaze)}家の番...`);
      setTimeout(() => {
        const aiAction = aiDecide(drawnState.current_turn);
        if (!aiAction) return;
        if (aiAction.action === 'tsumo') {
          const tsumoResult = checkTsumoAgari();
          if (tsumoResult) {
            playTsumoSound();
            setState(tsumoResult.state);
            setAgariResult(tsumoResult);
            setAgariWinner(`${kazeToJa(drawnState.players[drawnState.current_turn].jikaze)}家`);
            setLastAgariWasDealerWin(drawnState.players[drawnState.current_turn].jikaze === 'ton');
            return;
          }
        }
        if (aiAction.action === 'riichi') {
          const riichiState = declareRiichi();
          if (riichiState) setState(riichiState);
        }
        if (aiAction.tile) {
          const afterDiscard = discardTile(aiAction.tile);
          if (afterDiscard) {
            setState(afterDiscard);
            setTimeout(() => processAfterDiscard(afterDiscard), 300);
          }
        }
      }, 500);
    }
  }, [processAfterDiscard]);

  /** ツモ→ターン処理（鳴き/ロン後の次ターンから呼ばれる） */
  const processTurn = useCallback((currentState: GameState) => {
    setState(currentState);
    if (currentState.phase === 'round_end' || currentState.phase === 'game_end') {
      if (currentState.phase === 'game_end') {
        setMessage('ゲーム終了');
      } else {
        setMessage('流局');
        const cs = currentState;
        setTimeout(() => showScoreAndAdvance('流局', false, cs), 2000);
      }
      return;
    }
    const drawn = drawTile();
    if (!drawn) {
      setMessage('流局');
      const cs = currentState;
      setTimeout(() => showScoreAndAdvance('流局', false, cs), 2000);
      return;
    }
    handleTurnAfterDraw(drawn);
  }, [handleTurnAfterDraw]);

  const handlePon = useCallback(() => {
    const newState = doPon(HUMAN_SEAT);
    if (newState) {
      setState(newState);
      setCallInfo(null);
      setMessage('ポン！ 牌を捨ててください');
      setTenpaiTiles(getTenpaiTiles());
    }
  }, []);

  const handleChi = useCallback((tiles: Tile[]) => {
    if (tiles.length === 2) {
      const newState = doChi(HUMAN_SEAT, tiles[0], tiles[1]);
      if (newState) {
        setState(newState);
        setCallInfo(null);
        setChiSelectMode(false);
        setMessage('チー！ 牌を捨ててください');
        setTenpaiTiles(getTenpaiTiles());
      }
    }
  }, []);

  const handleMinkan = useCallback(() => {
    const newState = doMinkan(HUMAN_SEAT);
    if (newState) {
      setState(newState);
      setCallInfo(null);
      setMessage('カン！');
      // カン後はツモ（嶺上牌）
      setTimeout(() => {
        const drawn = drawTile();
        if (drawn) {
          setState(drawn);
          setMessage('牌を捨ててください');
          setTenpaiTiles(getTenpaiTiles());
        }
      }, 300);
    }
  }, []);

  const handleAnkan = useCallback((tile: Tile) => {
    const newState = doAnkan(HUMAN_SEAT, tile);
    if (newState) {
      setState(newState);
      setMessage('暗槓！');
      setTimeout(() => {
        const drawn = drawTile();
        if (drawn) {
          setState(drawn);
          setMessage('牌を捨ててください');
          setTenpaiTiles(getTenpaiTiles());
        }
      }, 300);
    }
  }, []);

  const handleKakan = useCallback((tile: Tile) => {
    const newState = doKakan(HUMAN_SEAT, tile);
    if (newState) {
      setState(newState);
      setMessage('加槓！');
      setTimeout(() => {
        const drawn = drawTile();
        if (drawn) {
          setState(drawn);
          setMessage('牌を捨ててください');
          setTenpaiTiles(getTenpaiTiles());
        }
      }, 300);
    }
  }, []);

  const handleRon = useCallback(() => {
    const ronResult = checkRon(HUMAN_SEAT);
    if (ronResult) {
      playRonSound();
      setState(ronResult.state);
      setAgariResult(ronResult);
      setAgariWinner(`${kazeToJa(state!.players[HUMAN_SEAT].jikaze)}家（あなた）`);
      setLastAgariWasDealerWin(state!.players[HUMAN_SEAT].jikaze === 'ton');
      setCallInfo(null);
    }
  }, [state, playRonSound]);

  const handleSkipCall = useCallback(() => {
    setCallInfo(null);
    setChiSelectMode(false);
    setMessage('');
    continueAfterCalls();
  }, [continueAfterCalls]);

  const handleAgariClose = useCallback(() => {
    setAgariResult(null);
    showScoreAndAdvance('和了', lastAgariWasDealerWin);
    setLastAgariWasDealerWin(false);
  }, [showScoreAndAdvance, lastAgariWasDealerWin]);

  const handleTsumo = useCallback(() => {
    const result = checkTsumoAgari();
    if (result) {
      playTsumoSound();
      setState(result.state);
      setAgariResult(result);
      setAgariWinner(`${kazeToJa(state!.players[HUMAN_SEAT].jikaze)}家（あなた）`);
      setLastAgariWasDealerWin(state!.players[HUMAN_SEAT].jikaze === 'ton');
    }
  }, [state, playTsumoSound]);

  if (!state) {
    return (
      <div style={{
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        minHeight: '100vh', gap: 32, background: '#0d1a0f',
      }}>
        <h1 style={{ fontSize: 48, fontWeight: 700, color: '#e8c44a' }}>麻雀</h1>
        <p style={{ color: '#6a8a6a' }}>日本式リーチ麻雀</p>
        <button onClick={handleStart} style={{
          padding: '16px 32px', background: '#e8c44a', border: 'none', borderRadius: 12,
          color: '#1a1a0a', fontSize: 20, fontWeight: 700, cursor: 'pointer',
        }}>ゲーム開始</button>
        {onBack && (
          <button onClick={onBack} style={{
            color: '#6a8a6a', background: 'none', border: 'none', cursor: 'pointer', fontSize: 14,
          }}>戻る</button>
        )}
      </div>
    );
  }

  // 麻雀の席順: 右=下家, 対面, 左=上家
  const rightSeat = (HUMAN_SEAT + 1) % 4;
  const topSeat = (HUMAN_SEAT + 2) % 4;
  const leftSeat = (HUMAN_SEAT + 3) % 4;
  const canTsumo = state.phase === 'waiting_discard' && state.current_turn === HUMAN_SEAT && checkTsumoAgari() !== null;
  const isMyTurn = state.phase === 'waiting_discard' && state.current_turn === HUMAN_SEAT;
  const ankanTiles = isMyTurn ? canAnkan(HUMAN_SEAT) : [];
  const kakanTiles = isMyTurn ? canKakan(HUMAN_SEAT) : [];
  const showKyuushu = isMyTurn && canKyuushu(HUMAN_SEAT);
  const canRiichi = isMyTurn && canDeclareRiichi(HUMAN_SEAT);

  return (
    <div style={{
      width: '100vw', height: '100vh', overflow: 'hidden',
      background: 'linear-gradient(180deg, #3a2a1a 0%, #1a2a1a 30%, #0a1a0e 100%)',
      display: 'flex', flexDirection: 'column', position: 'relative',
    }}>
      {onBack && (
        <button onClick={onBack} style={{
          position: 'absolute', top: 8, right: 8, zIndex: 30,
          width: 32, height: 32, display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: 'rgba(0,0,0,0.4)', border: '1px solid #555', borderRadius: 4,
          color: '#aaa', fontSize: 16, cursor: 'pointer',
        }}>✕</button>
      )}

      {/* ドラ表示（左上） */}
      <DoraDisplay indicators={state.dora_indicators ?? []} />

      {/* 補助設定ボタン */}
      <button onClick={() => setShowAssistSettings(!showAssistSettings)} style={{
        position: 'absolute', top: 8, left: 80, zIndex: 30,
        padding: '4px 8px', background: 'rgba(0,0,0,0.4)', border: '1px solid #555',
        borderRadius: 4, color: '#aaa', fontSize: 11, cursor: 'pointer',
      }}>補助</button>
      {showAssistSettings && (
        <AssistSettings config={assistConfig} onChange={setAssistConfig} onClose={() => setShowAssistSettings(false)} />
      )}

      {/* サウンド設定ボタン */}
      <button onClick={() => setShowSoundSettings(!showSoundSettings)} style={{
        position: 'absolute', top: 8, left: 120, zIndex: 30,
        padding: '4px 8px', background: 'rgba(0,0,0,0.4)', border: '1px solid #555',
        borderRadius: 4, color: '#aaa', fontSize: 11, cursor: 'pointer',
      }}>音</button>
      {showSoundSettings && (
        <SoundSettings onClose={() => setShowSoundSettings(false)} />
      )}

      {message && (
        <div style={{ textAlign: 'center', padding: '4px 0', color: '#8a8', fontSize: 12, flexShrink: 0 }}>
          {message}
        </div>
      )}

      <div style={{ flex: 1, position: 'relative', minHeight: 0 }}>
        {/* 対面（上）: 手牌は横 */}
        <div style={{ position: 'absolute', top: 4, left: '50%', transform: 'translateX(-50%)' }}>
          <PlayerHand player={state.players[topSeat]} isCurrentTurn={state.current_turn === topSeat} isHuman={false} compact />
        </div>

        {/* 左: 手牌は縦 */}
        <div style={{ position: 'absolute', left: 4, top: '50%', transform: 'translateY(-50%)' }}>
          <PlayerHand player={state.players[leftSeat]} isCurrentTurn={state.current_turn === leftSeat} isHuman={false} compact vertical />
        </div>

        {/* 右: 手牌は縦 */}
        <div style={{ position: 'absolute', right: 4, top: '50%', transform: 'translateY(-50%)' }}>
          <PlayerHand player={state.players[rightSeat]} isCurrentTurn={state.current_turn === rightSeat} isHuman={false} compact vertical />
        </div>

        {/* 中央: パネル + 四方の捨て牌 */}
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: 'translate(-50%, -50%)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
        }}>
          <Kawa tiles={state.players[topSeat].kawa} />
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Kawa tiles={state.players[leftSeat].kawa} direction="vertical" />
            <CenterPanel state={state} mySeat={HUMAN_SEAT} />
            <Kawa tiles={state.players[rightSeat].kawa} direction="vertical" />
          </div>
          <Kawa tiles={state.players[HUMAN_SEAT].kawa} />
        </div>
      </div>

      {/* 自分 */}
      <div style={{ flexShrink: 0, padding: '8px 16px 12px', background: 'linear-gradient(0deg, rgba(0,0,0,0.4), transparent)' }}>
        <div>
          <PlayerHand
            player={state.players[HUMAN_SEAT]}
            isCurrentTurn={state.current_turn === HUMAN_SEAT}
            isHuman
            onDiscard={handleDiscard}
            selectedTile={selectedTile}
            onSelectTile={setSelectedTile}
            disabledTiles={riichiMode ? riichiCandidates : undefined}
          />
        </div>
        {/* リーチモード: 各候補の待ち牌を表示 */}
        {/* ゲームプレイ補助 */}
        {!riichiMode && state.current_turn === HUMAN_SEAT && (
          <AssistDisplay
            config={assistConfig}
            shanten={getShanten(HUMAN_SEAT)}
            waitCounts={getWaitCounts(HUMAN_SEAT)}
            dangerTiles={getDangerTiles(HUMAN_SEAT)}
          />
        )}
        {riichiMode && riichiOptions.length > 0 ? (
          <div style={{ marginTop: 6 }}>
            {/* 選択中の牌の待ちをハイライト、未選択時は全候補表示 */}
            {(() => {
              const allHand = state.players[HUMAN_SEAT].hand ?? [];
              const tsumo = state.players[HUMAN_SEAT].tsumo;
              // 選択された牌を特定
              let selectedDiscard: Tile | null = null;
              if (selectedTile !== null) {
                if (selectedTile < allHand.length) {
                  selectedDiscard = allHand[selectedTile];
                } else if (tsumo) {
                  selectedDiscard = tsumo;
                }
              }
              const filtered = selectedDiscard
                ? riichiOptions.filter(o =>
                    o.discard.kind === selectedDiscard!.kind &&
                    o.discard.suit === selectedDiscard!.suit &&
                    o.discard.number === selectedDiscard!.number
                  )
                : riichiOptions;
              return (
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'center' }}>
                  {filtered.map((opt, i) => (
                    <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                      <TileView tile={opt.discard} small />
                      <span style={{ fontSize: 11, color: '#888' }}>→ 待ち:</span>
                      {opt.waits.map((w, j) => <TileView key={j} tile={w} small />)}
                    </div>
                  ))}
                </div>
              );
            })()}
          </div>
        ) : tenpaiTiles.length > 0 ? (
          <div style={{ marginTop: 6, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
            <span style={{ fontSize: 11, color: '#8a8' }}>待ち:</span>
            {tenpaiTiles.map((t, i) => <TileView key={i} tile={t} small />)}
          </div>
        ) : null}
        {/* アクションボタン */}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 8, marginTop: 8 }}>
          {canTsumo && (
            <button onClick={handleTsumo} style={{
              padding: '8px 24px', background: '#c41e3a', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
              boxShadow: '0 2px 8px rgba(196,30,58,0.4)',
            }}>ツモ</button>
          )}
          {showKyuushu && (
            <button onClick={() => {
              const newState = declareKyuushu();
              if (newState) {
                setState(newState);
                setMessage('九種九牌 — 流局');
                setTimeout(() => showScoreAndAdvance('流局', false, newState), 2000);
              }
            }} style={{
              padding: '8px 24px', background: '#8a6a2a', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
            }}>九種九牌</button>
          )}
          {canRiichi && !riichiMode && (
            <button onClick={handleRiichi} style={{
              padding: '8px 24px', background: '#d4a030', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
              boxShadow: '0 2px 8px rgba(212,160,48,0.4)',
            }}>リーチ</button>
          )}
          {ankanTiles.map((t, i) => (
            <button key={`ankan-${i}`} onClick={() => handleAnkan(t)} style={{
              padding: '8px 24px', background: '#5a3a8a', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
            }}>暗槓</button>
          ))}
          {kakanTiles.map((t, i) => (
            <button key={`kakan-${i}`} onClick={() => handleKakan(t)} style={{
              padding: '8px 24px', background: '#8a5a2a', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
            }}>加槓</button>
          ))}
          {callInfo?.canRon && (
            <button onClick={handleRon} style={{
              padding: '8px 24px', background: '#c41e3a', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
              boxShadow: '0 2px 8px rgba(196,30,58,0.4)',
            }}>ロン</button>
          )}
          {callInfo?.canMinkan && (
            <button onClick={handleMinkan} style={{
              padding: '8px 24px', background: '#8a5a2a', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
            }}>カン</button>
          )}
          {callInfo?.canPon && (
            <button onClick={handlePon} style={{
              padding: '8px 24px', background: '#2a6aaa', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
            }}>ポン</button>
          )}
          {callInfo && callInfo.chiOptions.length > 0 && !chiSelectMode && (
            <button onClick={() => setChiSelectMode(true)} style={{
              padding: '8px 24px', background: '#2a8a4a', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
            }}>チー</button>
          )}
          {callInfo && (
            <button onClick={handleSkipCall} style={{
              padding: '8px 24px', background: '#555', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
            }}>スキップ</button>
          )}
        </div>

        {/* チー候補選択 */}
        {chiSelectMode && callInfo && callInfo.chiOptions.length > 0 && (
          <div style={{
            display: 'flex', justifyContent: 'center', gap: 12, marginTop: 8,
            padding: '8px 12px', background: 'rgba(0,0,0,0.3)', borderRadius: 8,
          }}>
            {callInfo.chiOptions.map((opt, i) => (
              <button key={i} onClick={() => handleChi(opt)} style={{
                display: 'flex', gap: 2, padding: '4px 6px',
                background: 'rgba(42,138,74,0.3)', border: '2px solid #2a8a4a',
                borderRadius: 6, cursor: 'pointer', alignItems: 'center',
              }}>
                {opt.map((t, j) => (
                  <TileView key={j} tile={t} small />
                ))}
              </button>
            ))}
            <button onClick={() => setChiSelectMode(false)} style={{
              padding: '8px 16px', background: '#555', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 12, cursor: 'pointer',
            }}>戻る</button>
          </div>
        )}
      </div>

      {agariResult && <AgariDialog result={agariResult} winnerName={agariWinner} onClose={handleAgariClose} />}

      {scoreTransition && (
        <ScoreTransition
          beforeScores={scoreTransition.before}
          afterScores={scoreTransition.after}
          reason={scoreTransition.reason}
        />
      )}
    </div>
  );
}
