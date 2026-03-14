import type { Tile } from '../mahjong-bridge';

interface TileViewProps {
  tile: Tile;
  onClick?: () => void;
  selected?: boolean;
  small?: boolean;
  faceDown?: boolean;
  rotated?: boolean;
}

/** 漢数字 */
const kanjiNumbers = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

/** 筒子の丸を描画するための配置（1-9） */
const pinPositions: Record<number, [number, number][]> = {
  1: [[50, 50]],
  2: [[50, 28], [50, 72]],
  3: [[50, 22], [50, 50], [50, 78]],
  4: [[30, 30], [70, 30], [30, 70], [70, 70]],
  5: [[30, 25], [70, 25], [50, 50], [30, 75], [70, 75]],
  6: [[30, 22], [70, 22], [30, 50], [70, 50], [30, 78], [70, 78]],
  7: [[30, 18], [70, 18], [30, 42], [70, 42], [50, 60], [30, 78], [70, 78]],
  8: [[30, 18], [70, 18], [30, 38], [70, 38], [30, 58], [70, 58], [30, 78], [70, 78]],
  9: [[25, 18], [50, 18], [75, 18], [25, 50], [50, 50], [75, 50], [25, 82], [50, 82], [75, 82]],
};

/** 索子の竹を描画 */
function renderSouzu(n: number, size: number) {
  if (n === 1) {
    // 一索は鳥（簡略化して緑の大きな竹1本）
    return (
      <svg viewBox="0 0 100 100" width={size} height={size}>
        <circle cx="50" cy="35" r="18" fill="#2d8a4e" />
        <rect x="44" y="35" width="12" height="45" rx="3" fill="#2d8a4e" />
        <rect x="38" y="50" width="24" height="4" rx="2" fill="#1a6030" />
        <rect x="38" y="62" width="24" height="4" rx="2" fill="#1a6030" />
      </svg>
    );
  }
  const cols = n <= 3 ? 1 : n <= 6 ? 2 : 3;
  const rows = Math.ceil(n / cols);
  const sticks: [number, number][] = [];
  for (let i = 0; i < n; i++) {
    const col = i % cols;
    const row = Math.floor(i / cols);
    const x = cols === 1 ? 50 : cols === 2 ? 30 + col * 40 : 20 + col * 30;
    const y = 15 + row * (70 / rows);
    sticks.push([x, y]);
  }
  return (
    <svg viewBox="0 0 100 100" width={size} height={size}>
      {sticks.map(([x, y], i) => (
        <g key={i}>
          <rect x={x - 5} y={y} width="10" height={60 / rows} rx="2" fill="#2d8a4e" />
          <rect x={x - 6} y={y + 60 / rows * 0.3} width="12" height="2.5" rx="1" fill="#1a6030" />
          <rect x={x - 6} y={y + 60 / rows * 0.6} width="12" height="2.5" rx="1" fill="#1a6030" />
        </g>
      ))}
    </svg>
  );
}

/** 筒子の丸を描画 */
function renderPinzu(n: number, size: number) {
  const positions = pinPositions[n] ?? [];
  const r = n <= 2 ? 14 : n <= 4 ? 12 : n <= 6 ? 10 : 8;
  return (
    <svg viewBox="0 0 100 100" width={size} height={size}>
      {positions.map(([cx, cy], i) => (
        <g key={i}>
          <circle cx={cx} cy={cy} r={r} fill="#1a6fb5" />
          <circle cx={cx} cy={cy} r={r * 0.55} fill="#f8f4ec" />
          <circle cx={cx} cy={cy} r={r * 0.25} fill="#c41e3a" />
        </g>
      ))}
    </svg>
  );
}

/** 萬子を描画（漢数字 + 萬） */
function renderManzu(n: number, size: number) {
  const numSize = size < 40 ? 14 : 22;
  const manSize = size < 40 ? 12 : 18;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0, lineHeight: 1 }}>
      <span style={{ fontSize: numSize, fontWeight: 900, color: '#1a1a2e' }}>{kanjiNumbers[n]}</span>
      <span style={{ fontSize: manSize, fontWeight: 900, color: '#c41e3a' }}>萬</span>
    </div>
  );
}

/** 字牌の文字と色 */
const jihaiInfo: Record<number, { char: string; color: string }> = {
  1: { char: '東', color: '#1a1a2e' },
  2: { char: '南', color: '#1a1a2e' },
  3: { char: '西', color: '#1a1a2e' },
  4: { char: '北', color: '#1a1a2e' },
  5: { char: '', color: '#888' },       // 白（枠だけ）
  6: { char: '發', color: '#1a8a3e' },
  7: { char: '中', color: '#c41e3a' },
};

function renderTileFace(tile: Tile, size: number) {
  const artSize = Math.floor(size * 0.7);

  if (tile.kind === 'suhai') {
    switch (tile.suit) {
      case 'manzu':
        return renderManzu(tile.number, artSize);
      case 'pinzu':
        return renderPinzu(tile.number, artSize);
      case 'souzu':
        return renderSouzu(tile.number, artSize);
    }
  }

  // 字牌
  const info = jihaiInfo[tile.number];
  if (!info) return null;

  if (tile.number === 5) {
    // 白: 空の枠
    return (
      <div style={{
        width: artSize * 0.7, height: artSize * 0.7,
        border: `2px solid #999`,
        borderRadius: 2,
      }} />
    );
  }

  const fontSize = size < 40 ? 20 : 32;
  return (
    <span style={{
      fontSize,
      fontWeight: 900,
      color: info.color,
      lineHeight: 1,
    }}>
      {info.char}
    </span>
  );
}

export function TileView({ tile, onClick, selected, small, faceDown, rotated }: TileViewProps) {
  const w = small ? 30 : 48;
  const h = small ? 42 : 66;
  const depth = small ? 3 : 5;

  const outerW = rotated ? h : w;
  const outerH = rotated ? w : h;

  if (faceDown) {
    return (
      <div style={{
        width: outerW, height: outerH, flexShrink: 0,
        transform: rotated ? `rotate(90deg)` : undefined,
      }}>
        <div style={{
          width: w, height: h, borderRadius: 3,
          background: 'linear-gradient(160deg, #d4933a 0%, #b87a2a 50%, #a06820 100%)',
          border: '1px solid #8a5a1a',
          boxShadow: `0 ${depth}px 0 #6a4a15, 0 ${depth + 2}px 4px rgba(0,0,0,0.3)`,
          position: 'relative',
          overflow: 'hidden',
        }}>
          {/* 裏面の模様 */}
          <div style={{
            position: 'absolute', inset: 3,
            border: '1px solid rgba(255,220,150,0.3)',
            borderRadius: 2,
          }} />
        </div>
      </div>
    );
  }

  return (
    <div
      onClick={onClick}
      style={{
        width: outerW, height: outerH, flexShrink: 0,
        transform: [
          selected ? 'translateY(-10px)' : '',
          rotated ? 'rotate(90deg)' : '',
        ].filter(Boolean).join(' ') || undefined,
        transition: 'transform 0.15s',
        cursor: onClick ? 'pointer' : undefined,
      }}
      onMouseEnter={onClick ? (e) => {
        if (!selected) {
          (e.currentTarget as HTMLElement).style.transform =
            `translateY(-5px)${rotated ? ' rotate(90deg)' : ''}`;
        }
      } : undefined}
      onMouseLeave={onClick ? (e) => {
        if (!selected) {
          (e.currentTarget as HTMLElement).style.transform =
            rotated ? 'rotate(90deg)' : '';
        }
      } : undefined}
    >
      {/* 牌本体 */}
      <div style={{
        width: w, height: h, borderRadius: 3,
        background: 'linear-gradient(175deg, #fefcf7 0%, #f0ead8 60%, #e0d8c4 100%)',
        border: selected ? '2px solid #eab308' : '1px solid #b8b0a0',
        boxShadow: selected
          ? `0 ${depth}px 0 #c8a040, 0 ${depth + 4}px 12px rgba(234,179,8,0.3)`
          : `0 ${depth}px 0 #a09880, 0 ${depth + 2}px 4px rgba(0,0,0,0.25)`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        position: 'relative',
        userSelect: 'none',
      }}>
        {/* 上面のハイライト */}
        <div style={{
          position: 'absolute', top: 0, left: 0, right: 0, height: 2,
          background: 'rgba(255,255,255,0.6)',
          borderRadius: '3px 3px 0 0',
        }} />
        {renderTileFace(tile, small ? 36 : 56)}
      </div>
    </div>
  );
}
