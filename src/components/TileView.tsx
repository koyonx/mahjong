import type { Tile } from '../mahjong-bridge';
import { tileToDisplay } from '../mahjong-bridge';

interface TileViewProps {
  tile: Tile;
  onClick?: () => void;
  selected?: boolean;
  small?: boolean;
  faceDown?: boolean;
}

const suitColors: Record<string, string> = {
  manzu: 'text-red-600',
  pinzu: 'text-blue-600',
  souzu: 'text-green-600',
  kaze: 'text-gray-800',
  sangen: 'text-gray-800',
};

const sangenColors: Record<number, string> = {
  5: 'text-gray-300',   // 白
  6: 'text-green-600',  // 發
  7: 'text-red-600',    // 中
};

export function TileView({ tile, onClick, selected, small, faceDown }: TileViewProps) {
  if (faceDown) {
    return (
      <div className={`
        inline-flex items-center justify-center
        ${small ? 'w-7 h-10' : 'w-10 h-14'}
        bg-blue-800 rounded border border-blue-600
        shadow-md
      `} />
    );
  }

  const display = tileToDisplay(tile);
  let colorClass = suitColors[tile.suit] ?? 'text-gray-800';
  if (tile.kind === 'jihai' && tile.suit === 'sangen') {
    colorClass = sangenColors[tile.number] ?? colorClass;
  }

  return (
    <div
      onClick={onClick}
      className={`
        inline-flex items-center justify-center
        ${small ? 'w-7 h-10 text-lg' : 'w-10 h-14 text-2xl'}
        bg-amber-50 rounded border
        ${selected ? 'border-yellow-400 -translate-y-2 shadow-lg' : 'border-amber-200 shadow-md'}
        ${onClick ? 'cursor-pointer hover:-translate-y-1 hover:shadow-lg active:translate-y-0' : ''}
        ${colorClass} font-bold
        transition-all duration-150
        select-none
      `}
    >
      {display}
    </div>
  );
}
