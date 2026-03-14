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
      <div style={{
        display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4,
        fontSize: compact ? 11 : 13,
      }}>
        <span style={{
          fontWeight: 700,
          color: isCurrentTurn ? '#e8c44a' : '#6a8a6a',
        }}>
          {kazeToJa(player.jikaze)}
        </span>
        {player.is_riichi && (
          <span style={{
            padding: '1px 5px', background: '#c41e3a', color: '#fff',
            fontSize: 10, borderRadius: 3, fontWeight: 700,
          }}>立直</span>
        )}
        {isHuman && (
          <span style={{
            padding: '1px 5px', background: '#2a5a8a', color: '#fff',
            fontSize: 10, borderRadius: 3,
          }}>YOU</span>
        )}
      </div>

      <div style={{ display: 'flex', gap: 2, flexWrap: 'wrap', justifyContent: 'center' }}>
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
