import type { Tile } from '../mahjong-bridge';
import { TileView } from './TileView';

interface KawaProps {
  tiles: Tile[];
  /** 'horizontal' = 6列横並び（自分・対面）, 'vertical' = 3列縦並び（左右） */
  direction?: 'horizontal' | 'vertical';
}

export function Kawa({ tiles, direction = 'horizontal' }: KawaProps) {
  if (tiles.length === 0) return null;

  if (direction === 'vertical') {
    return (
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(2, auto)',
        gridTemplateRows: 'repeat(6, auto)',
        gridAutoFlow: 'column',
        gap: 2,
        justifyContent: 'center',
      }}>
        {tiles.map((tile, i) => (
          <TileView key={i} tile={tile} small />
        ))}
      </div>
    );
  }

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
