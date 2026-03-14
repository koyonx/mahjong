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
  onLeaveRoom: () => void;
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
  onLeaveRoom,
}: MultiplayerGameBoardProps) {
  const [selectedTile, setSelectedTile] = useState<number | null>(null);
  const [showMenu, setShowMenu] = useState(false);

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
        <button
          onClick={onLeaveRoom}
          className="px-6 py-3 bg-green-700 hover:bg-green-600 text-white font-bold rounded-lg transition"
        >
          ロビーに戻る
        </button>
      </div>
    );
  }

  const isMyTurn = state.current_turn === seat && state.phase === 'waiting_discard';

  const relativeSeat = (offset: number) => (seat + offset) % 4;
  const topSeat = relativeSeat(2);
  const rightSeat = relativeSeat(1);
  const leftSeat = relativeSeat(3);

  const lastMessage = messages[messages.length - 1] ?? '';

  return (
    <div className="relative flex flex-col h-screen overflow-hidden" style={{ background: 'radial-gradient(ellipse at center, #1a4a2e 0%, #0d2818 100%)' }}>
      {/* メニューボタン */}
      <button
        onClick={() => setShowMenu(!showMenu)}
        className="absolute top-3 right-3 z-30 w-8 h-8 flex items-center justify-center bg-green-800/60 hover:bg-green-700/80 rounded text-green-300 text-lg transition"
      >
        ☰
      </button>

      {/* メニューパネル */}
      {showMenu && (
        <div className="absolute top-12 right-3 z-30 bg-green-950/95 border border-green-700 rounded-lg p-3 shadow-xl">
          <button
            onClick={() => { onLeaveRoom(); setShowMenu(false); }}
            className="block w-full text-left px-4 py-2 text-red-400 hover:bg-green-800/50 rounded transition text-sm"
          >
            ルームを退出
          </button>
        </div>
      )}

      {/* 局情報バー */}
      <div className="flex-none p-2">
        <GameInfo state={state} />
        {lastMessage && (
          <div className="text-center py-1 text-green-200 text-xs">{lastMessage}</div>
        )}
      </div>

      {/* 卓面 */}
      <div className="flex-1 relative">
        {/* 対面（上） */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 flex flex-col items-center gap-1 z-10">
          <PlayerHand
            player={state.players[topSeat]}
            isCurrentTurn={state.current_turn === topSeat}
            isHuman={false}
            compact
          />
          <Kawa tiles={state.players[topSeat].kawa} compact />
        </div>

        {/* 左（左側） */}
        <div className="absolute left-2 top-1/2 -translate-y-1/2 flex flex-col items-center gap-1 z-10">
          <PlayerHand
            player={state.players[leftSeat]}
            isCurrentTurn={state.current_turn === leftSeat}
            isHuman={false}
            compact
          />
          <Kawa tiles={state.players[leftSeat].kawa} compact />
        </div>

        {/* 右（右側） */}
        <div className="absolute right-2 top-1/2 -translate-y-1/2 flex flex-col items-center gap-1 z-10">
          <PlayerHand
            player={state.players[rightSeat]}
            isCurrentTurn={state.current_turn === rightSeat}
            isHuman={false}
            compact
          />
          <Kawa tiles={state.players[rightSeat].kawa} compact />
        </div>

        {/* 中央の卓デコレーション */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-24 h-24 rounded border border-green-600/30 flex items-center justify-center">
          <div className="text-green-400/40 text-2xl font-bold">
            {kazeToJa(state.bakaze)}{state.kyoku}
          </div>
        </div>
      </div>

      {/* 自分（下） */}
      <div className="flex-none p-3 bg-green-950/40">
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
            <span className="text-xs text-green-300">待ち:</span>
            {turnInfo.tenpaiTiles.map((t, i) => (
              <TileView key={i} tile={t} small />
            ))}
          </div>
        )}

        {/* アクションボタン */}
        {isMyTurn && turnInfo?.canTsumo && (
          <div className="flex justify-center mt-2">
            <button
              onClick={onTsumo}
              className="px-6 py-2 bg-red-600 hover:bg-red-500 text-white font-bold rounded-lg transition shadow-lg"
            >
              ツモ
            </button>
          </div>
        )}
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
