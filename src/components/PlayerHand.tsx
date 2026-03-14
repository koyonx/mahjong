import type { Tile, Player } from '../mahjong-bridge';
import { TileView } from './TileView';
import { kazeToJa } from '../mahjong-bridge';

interface PlayerHandProps {
  player: Player;
  isCurrentTurn: boolean;
  isHuman: boolean;
  onDiscard?: (tile: Tile) => void;
  selectedTile?: number | null;
  onSelectTile?: (index: number) => void;
}

export function PlayerHand({
  player,
  isCurrentTurn,
  isHuman,
  onDiscard,
  selectedTile,
  onSelectTile,
}: PlayerHandProps) {
  return (
    <div className={`
      p-3 rounded-lg
      ${isCurrentTurn ? 'bg-green-800/50 ring-2 ring-yellow-400' : 'bg-green-800/30'}
    `}>
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <span className="text-lg font-bold">{kazeToJa(player.jikaze)}</span>
          {player.is_riichi && (
            <span className="px-2 py-0.5 bg-red-600 text-white text-xs rounded font-bold">
              リーチ
            </span>
          )}
          {isHuman && (
            <span className="px-2 py-0.5 bg-blue-600 text-white text-xs rounded">
              あなた
            </span>
          )}
        </div>
        <span className="text-amber-300 font-mono font-bold">
          {player.score.toLocaleString()}点
        </span>
      </div>

      <div className="flex gap-1 flex-wrap justify-center">
        {player.hand ? (
          player.hand.map((tile, i) => (
            <TileView
              key={i}
              tile={tile}
              faceDown={!isHuman}
              selected={isHuman && selectedTile === i}
              onClick={isHuman && isCurrentTurn && onSelectTile
                ? () => {
                    if (selectedTile === i && onDiscard) {
                      onDiscard(tile);
                    } else {
                      onSelectTile(i);
                    }
                  }
                : undefined
              }
            />
          ))
        ) : (
          Array.from({ length: player.hand_count ?? 13 }, (_, i) => (
            <TileView key={i} tile={{ kind: 'jihai', suit: 'kaze', number: 1, label: '' }} faceDown />
          ))
        )}
      </div>
    </div>
  );
}
