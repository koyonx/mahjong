import type { Tile } from '../mahjong-bridge';
import { TileView } from './TileView';

interface KawaProps {
  tiles: Tile[];
}

export function Kawa({ tiles }: KawaProps) {
  if (tiles.length === 0) return null;

  return (
    <div className="flex gap-0.5 flex-wrap max-w-[260px]">
      {tiles.map((tile, i) => (
        <TileView key={i} tile={tile} small />
      ))}
    </div>
  );
}
