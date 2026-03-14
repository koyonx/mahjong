import type { Tile } from '../mahjong-bridge';
import { tileToDisplay } from '../mahjong-bridge';

interface TileViewProps {
  tile: Tile;
  onClick?: () => void;
  selected?: boolean;
  small?: boolean;
  faceDown?: boolean;
  rotated?: boolean;
}

const suitColors: Record<string, string> = {
  manzu: '#c41e3a',
  pinzu: '#1a6fb5',
  souzu: '#2d8a4e',
  kaze: '#1a1a2e',
  sangen: '#1a1a2e',
};

const sangenColors: Record<number, string> = {
  5: '#b8b8b8',   // 白
  6: '#1a8a3e',   // 發
  7: '#c41e3a',   // 中
};

export function TileView({ tile, onClick, selected, small, faceDown, rotated }: TileViewProps) {
  const w = small ? 28 : 42;
  const h = small ? 38 : 56;

  const wrapperStyle: React.CSSProperties = {
    width: rotated ? h : w,
    height: rotated ? w : h,
    transform: `${selected ? 'translateY(-8px)' : ''} ${rotated ? 'rotate(90deg)' : ''}`.trim() || undefined,
    transition: 'transform 0.15s, box-shadow 0.15s',
    cursor: onClick ? 'pointer' : undefined,
    flexShrink: 0,
  };

  if (faceDown) {
    return (
      <div style={wrapperStyle}>
        <div style={{
          width: w, height: h,
          borderRadius: 4,
          background: 'linear-gradient(145deg, #1e3a5f, #152d4a)',
          border: '1px solid #2a5080',
          boxShadow: '1px 2px 4px rgba(0,0,0,0.4), inset 0 1px 0 rgba(100,160,220,0.15)',
        }} />
      </div>
    );
  }

  const display = tileToDisplay(tile);
  let color = suitColors[tile.suit] ?? '#1a1a2e';
  if (tile.kind === 'jihai' && tile.suit === 'sangen') {
    color = sangenColors[tile.number] ?? color;
  }

  return (
    <div
      onClick={onClick}
      style={wrapperStyle}
      onMouseEnter={onClick ? (e) => {
        if (!selected) (e.currentTarget as HTMLElement).style.transform = 'translateY(-4px)';
      } : undefined}
      onMouseLeave={onClick ? (e) => {
        if (!selected) (e.currentTarget as HTMLElement).style.transform = '';
      } : undefined}
    >
      <div style={{
        width: w, height: h,
        borderRadius: 4,
        background: 'linear-gradient(170deg, #f8f4ec 0%, #e8e0d0 100%)',
        border: selected ? '2px solid #eab308' : '1px solid #c8c0b0',
        boxShadow: selected
          ? '0 4px 12px rgba(234,179,8,0.4), inset 0 1px 0 rgba(255,255,255,0.8)'
          : '1px 2px 3px rgba(0,0,0,0.3), inset 0 1px 0 rgba(255,255,255,0.8), inset 0 -1px 0 rgba(0,0,0,0.05)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        userSelect: 'none',
        overflow: 'hidden',
      }}>
        {/* 牌の上面ハイライト */}
        <div style={{
          position: 'absolute',
          top: 0, left: 0, right: 0,
          height: small ? 3 : 4,
          background: 'linear-gradient(180deg, rgba(255,255,255,0.6), transparent)',
          borderRadius: '4px 4px 0 0',
        }} />
        {/* 牌の底面シャドウ */}
        <div style={{
          position: 'absolute',
          bottom: 0, left: 0, right: 0,
          height: small ? 4 : 6,
          background: 'linear-gradient(0deg, rgba(180,170,150,0.4), transparent)',
          borderRadius: '0 0 4px 4px',
        }} />
        {/* 文字 */}
        <span style={{
          color,
          fontSize: small ? 16 : 24,
          fontWeight: 800,
          textShadow: '0 1px 0 rgba(255,255,255,0.3)',
          lineHeight: 1,
          position: 'relative',
          zIndex: 1,
        }}>
          {display}
        </span>
      </div>
    </div>
  );
}
