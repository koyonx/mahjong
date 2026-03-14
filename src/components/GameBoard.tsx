import { useState, useCallback } from 'react';
import type { Tile, GameState, AgariResult } from '../mahjong-bridge';
import {
  startGame, drawTile, discardTile, advanceTurn,
  checkTsumoAgari, checkRon, getTenpaiTiles, nextRound,
  declareRiichi, aiDecide, kazeToJa
} from '../mahjong-bridge';
import { PlayerHand } from './PlayerHand';
import { Kawa } from './Kawa';
import { CenterPanel } from './CenterPanel';
import { AgariDialog } from './AgariDialog';
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
        setState(drawn);
        if (drawn.current_turn === HUMAN_SEAT) {
          setMessage('牌を選んで捨ててください');
          setTenpaiTiles(getTenpaiTiles());
        }
      }
    }, 300);
  }, []);

  const handleDiscard = useCallback((tile: Tile) => {
    if (!state || state.phase !== 'waiting_discard') return;
    if (state.current_turn !== HUMAN_SEAT) return;
    const newState = discardTile(tile);
    if (!newState) return;
    setState(newState);
    setSelectedTile(null);
    setTenpaiTiles([]);
    setMessage('');
    setTimeout(() => processAfterDiscard(newState), 300);
  }, [state]);

  const processAfterDiscard = useCallback((currentState: GameState) => {
    for (let i = 0; i < 4; i++) {
      if (i === currentState.current_turn) continue;
      const ronResult = checkRon(i);
      if (ronResult) {
        setState(ronResult.state);
        setAgariResult(ronResult);
        setAgariWinner(`${kazeToJa(currentState.players[i].jikaze)}家`);
        return;
      }
    }
    const advanced = advanceTurn();
    if (!advanced) return;
    processTurn(advanced);
  }, []);

  const processTurn = useCallback((currentState: GameState) => {
    setState(currentState);
    if (currentState.phase === 'round_end' || currentState.phase === 'game_end') {
      setMessage(currentState.phase === 'game_end' ? 'ゲーム終了' : '流局');
      return;
    }
    const drawn = drawTile();
    if (!drawn) { setMessage('流局'); return; }
    setState(drawn);
    if (drawn.current_turn === HUMAN_SEAT) {
      setMessage('牌を選んで捨ててください');
      setTenpaiTiles(getTenpaiTiles());
      const tsumoResult = checkTsumoAgari();
      if (tsumoResult) setMessage('ツモ和了できます！');
    } else {
      setMessage(`${kazeToJa(drawn.players[drawn.current_turn].jikaze)}家の番...`);
      setTimeout(() => {
        const aiAction = aiDecide(drawn.current_turn);
        if (!aiAction) return;
        if (aiAction.action === 'tsumo') {
          const tsumoResult = checkTsumoAgari();
          if (tsumoResult) {
            setState(tsumoResult.state);
            setAgariResult(tsumoResult);
            setAgariWinner(`${kazeToJa(drawn.players[drawn.current_turn].jikaze)}家`);
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

  const handleAgariClose = useCallback(() => {
    setAgariResult(null);
    const next = nextRound(false);
    if (next) {
      setState(next);
      if (next.phase === 'game_end') {
        setMessage('ゲーム終了');
      } else {
        setMessage('次の局を開始します');
        setTimeout(() => {
          const drawn = drawTile();
          if (drawn) {
            setState(drawn);
            if (drawn.current_turn === HUMAN_SEAT) {
              setMessage('牌を選んで捨ててください');
              setTenpaiTiles(getTenpaiTiles());
            } else {
              processTurn(drawn);
            }
          }
        }, 500);
      }
    }
  }, [processTurn]);

  const handleTsumo = useCallback(() => {
    const result = checkTsumoAgari();
    if (result) {
      setState(result.state);
      setAgariResult(result);
      setAgariWinner(`${kazeToJa(state!.players[HUMAN_SEAT].jikaze)}家（あなた）`);
    }
  }, [state]);

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

  const topSeat = 2, rightSeat = 3, leftSeat = 1;
  const canTsumo = state.phase === 'waiting_discard' && state.current_turn === HUMAN_SEAT && checkTsumoAgari() !== null;

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

      {message && (
        <div style={{ textAlign: 'center', padding: '4px 0', color: '#8a8', fontSize: 12, flexShrink: 0 }}>
          {message}
        </div>
      )}

      <div style={{ flex: 1, position: 'relative', minHeight: 0 }}>
        {/* 対面 */}
        <div style={{ position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
          <PlayerHand player={state.players[topSeat]} isCurrentTurn={state.current_turn === topSeat} isHuman={false} compact />
          <Kawa tiles={state.players[topSeat].kawa} compact />
        </div>

        {/* 左 */}
        <div style={{ position: 'absolute', left: 8, top: '50%', transform: 'translateY(-50%)', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
          <PlayerHand player={state.players[leftSeat]} isCurrentTurn={state.current_turn === leftSeat} isHuman={false} compact />
          <Kawa tiles={state.players[leftSeat].kawa} compact />
        </div>

        {/* 右 */}
        <div style={{ position: 'absolute', right: 8, top: '50%', transform: 'translateY(-50%)', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
          <PlayerHand player={state.players[rightSeat]} isCurrentTurn={state.current_turn === rightSeat} isHuman={false} compact />
          <Kawa tiles={state.players[rightSeat].kawa} compact />
        </div>

        {/* 中央パネル */}
        <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)' }}>
          <CenterPanel state={state} mySeat={HUMAN_SEAT} />
        </div>
      </div>

      {/* 自分 */}
      <div style={{ flexShrink: 0, padding: '8px 16px 12px', background: 'linear-gradient(0deg, rgba(0,0,0,0.4), transparent)' }}>
        <Kawa tiles={state.players[HUMAN_SEAT].kawa} />
        <div style={{ marginTop: 8 }}>
          <PlayerHand
            player={state.players[HUMAN_SEAT]}
            isCurrentTurn={state.current_turn === HUMAN_SEAT}
            isHuman
            onDiscard={handleDiscard}
            selectedTile={selectedTile}
            onSelectTile={setSelectedTile}
          />
        </div>
        {tenpaiTiles.length > 0 && (
          <div style={{ marginTop: 6, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
            <span style={{ fontSize: 11, color: '#8a8' }}>待ち:</span>
            {tenpaiTiles.map((t, i) => <TileView key={i} tile={t} small />)}
          </div>
        )}
        {canTsumo && (
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 8 }}>
            <button onClick={handleTsumo} style={{
              padding: '8px 24px', background: '#c41e3a', border: 'none', borderRadius: 6,
              color: '#fff', fontWeight: 700, fontSize: 15, cursor: 'pointer',
              boxShadow: '0 2px 8px rgba(196,30,58,0.4)',
            }}>ツモ</button>
          </div>
        )}
      </div>

      {agariResult && <AgariDialog result={agariResult} winnerName={agariWinner} onClose={handleAgariClose} />}
    </div>
  );
}
