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
  compact?: boolean;
}

export function PlayerHand({
  player,
  isCurrentTurn,
  isHuman,
  onDiscard,
  selectedTile,
  onSelectTile,
  compact,
}: PlayerHandProps) {
  return (
    <div>
      <div className={`flex items-center gap-2 mb-1 ${compact ? 'text-xs' : 'text-sm'}`}>
        <span className={`font-bold ${isCurrentTurn ? 'text-yellow-400' : 'text-green-300'}`}>
          {kazeToJa(player.jikaze)}
        </span>
        {player.is_riichi && (
          <span className="px-1.5 py-0.5 bg-red-600 text-white text-[10px] rounded font-bold">
            立直
          </span>
        )}
        <span className="text-amber-300 font-mono font-bold ml-auto">
          {player.score.toLocaleString()}
        </span>
      </div>

      <div className="flex gap-0.5 flex-wrap justify-center">
        {player.hand ? (
          player.hand.map((tile, i) => (
            <TileView
              key={i}
              tile={tile}
              faceDown={!isHuman}
              small={compact}
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
            <TileView key={i} tile={{ kind: 'jihai', suit: 'kaze', number: 1, label: '' }} faceDown small={compact} />
          ))
        )}
      </div>
    </div>
  );
}
