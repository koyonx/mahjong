import type { Tile } from '../mahjong-bridge';
import { TileView } from './TileView';

interface KawaProps {
  tiles: Tile[];
  compact?: boolean;
}

export function Kawa({ tiles, compact }: KawaProps) {
  if (tiles.length === 0) return null;

  return (
    <div className={`flex gap-0.5 flex-wrap ${compact ? 'max-w-[180px]' : 'max-w-[280px]'}`}>
      {tiles.map((tile, i) => (
        <TileView key={i} tile={tile} small />
      ))}
    </div>
  );
}
