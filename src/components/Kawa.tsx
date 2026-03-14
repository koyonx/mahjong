import type { Tile } from '../mahjong-bridge';
import { TileView } from './TileView';

interface KawaProps {
  tiles: Tile[];
}

/** 捨て牌を6列のグリッドで表示（実際の麻雀卓と同じ） */
export function Kawa({ tiles }: KawaProps) {
  if (tiles.length === 0) return null;

  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(6, auto)',
      gap: 2,
      justifyContent: 'center',
    }}>
      {tiles.map((tile, i) => (
        <TileView key={i} tile={tile} small />
      ))}
    </div>
  );
}
