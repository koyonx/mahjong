import { useState, useCallback } from 'react';
import type { Tile, GameState, AgariResult } from '../mahjong-bridge';
import {
  startGame, drawTile, discardTile, advanceTurn,
  checkTsumoAgari, checkRon, getTenpaiTiles, nextRound,
  declareRiichi, aiDecide, kazeToJa
} from '../mahjong-bridge';
import { PlayerHand } from './PlayerHand';
import { Kawa } from './Kawa';
import { GameInfo } from './GameInfo';
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
    if (!drawn) {
      setMessage('流局');
      return;
    }
    setState(drawn);

    if (drawn.current_turn === HUMAN_SEAT) {
      setMessage('牌を選んで捨ててください');
      const waits = getTenpaiTiles();
      setTenpaiTiles(waits);

      const tsumoResult = checkTsumoAgari();
      if (tsumoResult) {
        setMessage('ツモ和了できます！');
      }
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
      <div className="flex flex-col items-center justify-center min-h-screen gap-8">
        <h1 className="text-5xl font-bold text-amber-300">麻雀</h1>
        <p className="text-green-300">日本式リーチ麻雀</p>
        <button
          onClick={handleStart}
          className="px-8 py-4 bg-yellow-500 hover:bg-yellow-400 text-green-950 text-xl font-bold rounded-xl transition shadow-lg"
        >
          ゲーム開始
        </button>
        {onBack && (
          <button onClick={onBack} className="text-green-400 hover:text-green-300 text-sm">
            戻る
          </button>
        )}
      </div>
    );
  }

  const topSeat = 2;
  const rightSeat = 3;
  const leftSeat = 1;

  const canTsumo = state.phase === 'waiting_discard'
    && state.current_turn === HUMAN_SEAT
    && checkTsumoAgari() !== null;

  return (
    <div className="relative flex flex-col h-screen overflow-hidden" style={{ background: 'radial-gradient(ellipse at center, #1a4a2e 0%, #0d2818 100%)' }}>
      {/* 戻るボタン */}
      {onBack && (
        <button
          onClick={onBack}
          className="absolute top-3 right-3 z-30 w-8 h-8 flex items-center justify-center bg-green-800/60 hover:bg-green-700/80 rounded text-green-300 text-lg transition"
        >
          ✕
        </button>
      )}

      {/* 局情報 */}
      <div className="flex-none p-2">
        <GameInfo state={state} />
        {message && (
          <div className="text-center py-1 text-green-200 text-xs">{message}</div>
        )}
      </div>

      {/* 卓面 */}
      <div className="flex-1 relative">
        {/* 対面 */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 flex flex-col items-center gap-1 z-10">
          <PlayerHand player={state.players[topSeat]} isCurrentTurn={state.current_turn === topSeat} isHuman={false} compact />
          <Kawa tiles={state.players[topSeat].kawa} compact />
        </div>

        {/* 左 */}
        <div className="absolute left-2 top-1/2 -translate-y-1/2 flex flex-col items-center gap-1 z-10">
          <PlayerHand player={state.players[leftSeat]} isCurrentTurn={state.current_turn === leftSeat} isHuman={false} compact />
          <Kawa tiles={state.players[leftSeat].kawa} compact />
        </div>

        {/* 右 */}
        <div className="absolute right-2 top-1/2 -translate-y-1/2 flex flex-col items-center gap-1 z-10">
          <PlayerHand player={state.players[rightSeat]} isCurrentTurn={state.current_turn === rightSeat} isHuman={false} compact />
          <Kawa tiles={state.players[rightSeat].kawa} compact />
        </div>

        {/* 中央 */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-24 h-24 rounded border border-green-600/30 flex items-center justify-center">
          <div className="text-green-400/40 text-2xl font-bold">
            {kazeToJa(state.bakaze)}{state.kyoku}
          </div>
        </div>
      </div>

      {/* 自分 */}
      <div className="flex-none p-3 bg-green-950/40">
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

        {tenpaiTiles.length > 0 && (
          <div className="mt-2 flex items-center justify-center gap-2">
            <span className="text-xs text-green-300">待ち:</span>
            {tenpaiTiles.map((t, i) => (
              <TileView key={i} tile={t} small />
            ))}
          </div>
        )}

        {canTsumo && (
          <div className="flex justify-center mt-2">
            <button
              onClick={handleTsumo}
              className="px-6 py-2 bg-red-600 hover:bg-red-500 text-white font-bold rounded-lg transition shadow-lg"
            >
              ツモ
            </button>
          </div>
        )}
      </div>

      {agariResult && (
        <AgariDialog result={agariResult} winnerName={agariWinner} onClose={handleAgariClose} />
      )}
    </div>
  );
}
