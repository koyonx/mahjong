import type { Tile, Player, Furo } from '../mahjong-bridge';
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
  vertical?: boolean;
  disabledTiles?: Tile[];  // これらの牌は暗く表示（リーチ時の候補外）
}

function FuroGroup({ furo }: { furo: Furo }) {
  return (
    <div style={{
      display: 'flex', gap: 1,
      padding: '0 4px',
      borderLeft: '2px solid rgba(255,255,255,0.15)',
    }}>
      {furo.tiles.map((tile, i) => (
        <TileView key={i} tile={tile} small />
      ))}
    </div>
  );
}

export function PlayerHand({
  player,
  isCurrentTurn,
  isHuman,
  onDiscard,
  selectedTile,
  onSelectTile,
  compact,
  vertical,
  disabledTiles,
}: PlayerHandProps) {
  const handTiles = player.hand ?? [];
  const tsumoTile = player.tsumo;
  const furoList = player.furo ?? [];

  return (
    <div>
      {/* プレイヤー情報 */}
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

      <div style={{
        display: 'flex',
        flexDirection: vertical ? 'column' : 'row',
        alignItems: vertical ? 'center' : 'flex-end',
        gap: 0,
        justifyContent: 'center',
      }}>
        {/* 副露 */}
        {furoList.length > 0 && (
          <div style={{
            display: 'flex',
            flexDirection: vertical ? 'column' : 'row',
            gap: 4,
            ...(vertical ? { marginBottom: 8 } : { marginRight: 8 }),
          }}>
            {furoList.map((f, i) => <FuroGroup key={i} furo={f} />)}
          </div>
        )}

        {/* メイン手牌（ソート済み） */}
        <div style={{
          display: 'flex',
          flexDirection: vertical ? 'column' : 'row',
          gap: vertical ? 1 : 2,
        }}>
          {isHuman ? (
            handTiles.map((tile, i) => {
              const isDisabled = disabledTiles && !disabledTiles.some(
                c => c.kind === tile.kind && c.suit === tile.suit && c.number === tile.number
              );
              return (
              <div
                key={`${tile.kind}-${tile.suit}-${tile.number}-${i}`}
                style={{
                  transition: 'transform 0.3s ease, opacity 0.3s ease',
                  opacity: isDisabled ? 0.35 : 1,
                  filter: isDisabled ? 'grayscale(0.8)' : undefined,
                }}
              >
                <TileView
                  tile={tile}
                  small={compact}
                  selected={!isDisabled && selectedTile === i}
                  onClick={!isDisabled && isCurrentTurn && onSelectTile
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
              </div>
              );
            })
          ) : (
            // 他プレイヤー: 裏面表示
            Array.from({ length: player.hand_count ?? (handTiles.length + (tsumoTile ? 1 : 0)) }, (_, i) => (
              <TileView key={i} tile={{ kind: 'jihai', suit: 'kaze', number: 1, label: '' }} faceDown small={compact} rotated={vertical} />
            ))
          )}
        </div>

        {/* ツモ牌（右端に分離） */}
        {isHuman && tsumoTile && (() => {
          const tsumoDisabled = disabledTiles && !disabledTiles.some(
            c => c.kind === tsumoTile.kind && c.suit === tsumoTile.suit && c.number === tsumoTile.number
          );
          return (
          <div style={{
            marginLeft: 12, transition: 'transform 0.3s ease',
            opacity: tsumoDisabled ? 0.35 : 1,
            filter: tsumoDisabled ? 'grayscale(0.8)' : undefined,
          }}>
            <TileView
              tile={tsumoTile}
              small={compact}
              selected={!tsumoDisabled && selectedTile === handTiles.length}
              onClick={!tsumoDisabled && isCurrentTurn && onSelectTile
                ? () => {
                    const tsumoIdx = handTiles.length;
                    if (selectedTile === tsumoIdx && onDiscard) {
                      onDiscard(tsumoTile);
                    } else {
                      onSelectTile(tsumoIdx);
                    }
                  }
                : undefined
              }
            />
          </div>
          );
        })()}
      </div>
    </div>
  );
}
