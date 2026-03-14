import { useState, useCallback } from 'react';
import type { Tile, GameState, AgariResult } from '../mahjong-bridge';
import {
  startGame, drawTile, discardTile, advanceTurn,
  checkTsumoAgari, checkRon, getTenpaiTiles, nextRound,
  kazeToJa
} from '../mahjong-bridge';
import { PlayerHand } from './PlayerHand';
import { Kawa } from './Kawa';
import { GameInfo } from './GameInfo';
import { AgariDialog } from './AgariDialog';
import { TileView } from './TileView';

const HUMAN_SEAT = 0;

export function GameBoard() {
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

    // 最初のツモ
    setTimeout(() => {
      const drawn = drawTile();
      if (drawn) {
        setState(drawn);
        if (drawn.current_turn === HUMAN_SEAT) {
          setMessage('牌を選んで捨ててください');
          const waits = getTenpaiTiles();
          setTenpaiTiles(waits);
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

    // CPU のロン判定 → 鳴きスキップ → 次の手番
    setTimeout(() => processAfterDiscard(newState), 300);
  }, [state]);

  const processAfterDiscard = useCallback((currentState: GameState) => {
    // 簡易版: CPUのロン判定
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

    // 鳴きなし → 次の手番
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

    // ツモ
    const drawn = drawTile();
    if (!drawn) {
      setMessage('流局');
      return;
    }
    setState(drawn);

    if (drawn.current_turn === HUMAN_SEAT) {
      // 人間のターン
      setMessage('牌を選んで捨ててください');
      const waits = getTenpaiTiles();
      setTenpaiTiles(waits);

      // ツモ和了チェック
      const tsumoResult = checkTsumoAgari();
      if (tsumoResult) {
        setMessage('ツモ和了できます！');
      }
    } else {
      // CPUのターン
      setMessage(`${kazeToJa(drawn.players[drawn.current_turn].jikaze)}家の番...`);

      setTimeout(() => {
        // CPUツモ和了チェック
        const tsumoResult = checkTsumoAgari();
        if (tsumoResult) {
          setState(tsumoResult.state);
          setAgariResult(tsumoResult);
          setAgariWinner(`${kazeToJa(drawn.players[drawn.current_turn].jikaze)}家`);
          return;
        }

        // CPU打牌（最初の牌を捨てる簡易AI）
        const cpuPlayer = drawn.players[drawn.current_turn];
        if (cpuPlayer.hand.length > 0) {
          const tileToDiscard = cpuPlayer.hand[0];
          const afterDiscard = discardTile(tileToDiscard);
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
      <div className="flex flex-col items-center justify-center min-h-screen gap-8">
        <h1 className="text-5xl font-bold text-amber-300">麻雀</h1>
        <p className="text-green-300">日本式リーチ麻雀</p>
        <button
          onClick={handleStart}
          className="px-8 py-4 bg-yellow-500 hover:bg-yellow-400 text-green-950 text-xl font-bold rounded-xl transition shadow-lg"
        >
          ゲーム開始
        </button>
      </div>
    );
  }

  // プレイヤーの表示順: 対面(2) → 右(3) → 左(1) → 自分(0)
  const seatOrder = [2, 3, 1, 0];
  const seatLabels = ['対面', '右', '左', 'あなた'];

  const canTsumo = state.phase === 'waiting_discard'
    && state.current_turn === HUMAN_SEAT
    && checkTsumoAgari() !== null;

  return (
    <div className="flex flex-col min-h-screen p-4 gap-4">
      <GameInfo state={state} />

      {message && (
        <div className="text-center py-2 text-green-200 text-sm">{message}</div>
      )}

      {/* 対面 */}
      <div className="flex flex-col items-center gap-2">
        <PlayerHand
          player={state.players[seatOrder[0]]}
          isCurrentTurn={state.current_turn === seatOrder[0]}
          isHuman={false}
        />
        <Kawa tiles={state.players[seatOrder[0]].kawa} />
      </div>

      {/* 左右 */}
      <div className="flex justify-between items-start">
        <div className="flex flex-col items-center gap-2">
          <PlayerHand
            player={state.players[seatOrder[2]]}
            isCurrentTurn={state.current_turn === seatOrder[2]}
            isHuman={false}
          />
          <Kawa tiles={state.players[seatOrder[2]].kawa} />
        </div>
        <div className="flex flex-col items-center gap-2">
          <PlayerHand
            player={state.players[seatOrder[1]]}
            isCurrentTurn={state.current_turn === seatOrder[1]}
            isHuman={false}
          />
          <Kawa tiles={state.players[seatOrder[1]].kawa} />
        </div>
      </div>

      {/* 自分 */}
      <div className="mt-auto">
        <Kawa tiles={state.players[HUMAN_SEAT].kawa} />
        <div className="mt-2">
          <PlayerHand
            player={state.players[HUMAN_SEAT]}
            isCurrentTurn={state.current_turn === HUMAN_SEAT}
            isHuman
            onDiscard={handleDiscard}
            selectedTile={selectedTile}
            onSelectTile={setSelectedTile}
          />
        </div>

        {/* テンパイ表示 */}
        {tenpaiTiles.length > 0 && (
          <div className="mt-2 flex items-center justify-center gap-2">
            <span className="text-sm text-green-300">待ち:</span>
            {tenpaiTiles.map((t, i) => (
              <TileView key={i} tile={t} small />
            ))}
          </div>
        )}

        {/* アクションボタン */}
        <div className="flex justify-center gap-3 mt-3">
          {canTsumo && (
            <button
              onClick={handleTsumo}
              className="px-6 py-2 bg-red-600 hover:bg-red-500 text-white font-bold rounded-lg transition"
            >
              ツモ
            </button>
          )}
        </div>
      </div>

      {/* 和了ダイアログ */}
      {agariResult && (
        <AgariDialog
          result={agariResult}
          winnerName={agariWinner}
          onClose={handleAgariClose}
        />
      )}
    </div>
  );
}
