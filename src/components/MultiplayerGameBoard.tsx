import { useState } from 'react';
import type { Tile, GameState, AgariResult } from '../mahjong-bridge';
import { kazeToJa } from '../mahjong-bridge';
import { TileView } from './TileView';
import { PlayerHand } from './PlayerHand';
import { Kawa } from './Kawa';
import { GameInfo } from './GameInfo';
import { AgariDialog } from './AgariDialog';

interface MultiplayerGameBoardProps {
  state: GameState;
  seat: number;
  turnInfo: { canTsumo: boolean; canRiichi: boolean; tenpaiTiles: Tile[] } | null;
  agariResult: { result: AgariResult; winnerSeat: number; winnerName: string } | null;
  messages: string[];
  gameEnd: { name: string; score: number }[] | null;
  onDiscard: (tile: Tile) => void;
  onTsumo: () => void;
  onRiichi: (tile: Tile) => void;
  onAgariClose: () => void;
}

export function MultiplayerGameBoard({
  state,
  seat,
  turnInfo,
  agariResult,
  messages,
  gameEnd,
  onDiscard,
  onTsumo,
  onAgariClose,
}: MultiplayerGameBoardProps) {
  const [selectedTile, setSelectedTile] = useState<number | null>(null);

  if (gameEnd) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen gap-6">
        <h1 className="text-4xl font-bold text-amber-300">ゲーム終了</h1>
        <div className="bg-green-800/50 rounded-xl p-6 w-full max-w-md">
          {gameEnd.map((p, i) => (
            <div key={i} className="flex justify-between px-4 py-3 border-b border-green-700 last:border-0">
              <span className="font-bold">
                {i === 0 ? '🏆 ' : ''}{p.name}
              </span>
              <span className="text-amber-300 font-mono">{p.score.toLocaleString()}点</span>
            </div>
          ))}
        </div>
      </div>
    );
  }

  const isMyTurn = state.current_turn === seat && state.phase === 'waiting_discard';

  // 自分を基準に相対的な座席配置
  // 自分(下) → 右(右) → 対面(上) → 左(左)
  const relativeSeat = (offset: number) => (seat + offset) % 4;
  const topSeat = relativeSeat(2);   // 対面
  const rightSeat = relativeSeat(1); // 右
  const leftSeat = relativeSeat(3);  // 左

  const lastMessage = messages[messages.length - 1] ?? '';

  return (
    <div className="flex flex-col min-h-screen p-4 gap-4">
      <GameInfo state={state} />

      {lastMessage && (
        <div className="text-center py-2 text-green-200 text-sm">{lastMessage}</div>
      )}

      {/* 対面 */}
      <div className="flex flex-col items-center gap-2">
        <PlayerHand
          player={state.players[topSeat]}
          isCurrentTurn={state.current_turn === topSeat}
          isHuman={false}
        />
        <Kawa tiles={state.players[topSeat].kawa} />
      </div>

      {/* 左右 */}
      <div className="flex justify-between items-start">
        <div className="flex flex-col items-center gap-2">
          <PlayerHand
            player={state.players[leftSeat]}
            isCurrentTurn={state.current_turn === leftSeat}
            isHuman={false}
          />
          <Kawa tiles={state.players[leftSeat].kawa} />
        </div>
        <div className="flex flex-col items-center gap-2">
          <PlayerHand
            player={state.players[rightSeat]}
            isCurrentTurn={state.current_turn === rightSeat}
            isHuman={false}
          />
          <Kawa tiles={state.players[rightSeat].kawa} />
        </div>
      </div>

      {/* 自分 */}
      <div className="mt-auto">
        <Kawa tiles={state.players[seat].kawa} />
        <div className="mt-2">
          <PlayerHand
            player={state.players[seat]}
            isCurrentTurn={isMyTurn}
            isHuman={true}
            onDiscard={(tile) => {
              onDiscard(tile);
              setSelectedTile(null);
            }}
            selectedTile={selectedTile}
            onSelectTile={setSelectedTile}
          />
        </div>

        {/* テンパイ表示 */}
        {turnInfo && turnInfo.tenpaiTiles.length > 0 && (
          <div className="mt-2 flex items-center justify-center gap-2">
            <span className="text-sm text-green-300">待ち:</span>
            {turnInfo.tenpaiTiles.map((t, i) => (
              <TileView key={i} tile={t} small />
            ))}
          </div>
        )}

        {/* アクションボタン */}
        <div className="flex justify-center gap-3 mt-3">
          {isMyTurn && turnInfo?.canTsumo && (
            <button
              onClick={onTsumo}
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
          result={agariResult.result}
          winnerName={agariResult.winnerName}
          onClose={onAgariClose}
        />
      )}
    </div>
  );
}
