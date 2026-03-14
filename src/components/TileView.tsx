import type { Tile } from '../mahjong-bridge';

interface TileViewProps {
  tile: Tile;
  onClick?: () => void;
  selected?: boolean;
  small?: boolean;
  faceDown?: boolean;
}

const SERIF_FONT = '"Yu Mincho", "Hiragino Mincho ProN", "Noto Serif JP", serif';

const kanjiNumbers = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

const pinPositions: Record<number, [number, number][]> = {
  1: [[50, 50]],
  2: [[50, 30], [50, 70]],
  3: [[50, 22], [50, 50], [50, 78]],
  4: [[30, 30], [70, 30], [30, 70], [70, 70]],
  5: [[30, 25], [70, 25], [50, 50], [30, 75], [70, 75]],
  6: [[30, 22], [70, 22], [30, 50], [70, 50], [30, 78], [70, 78]],
  7: [[30, 18], [70, 18], [30, 42], [70, 42], [50, 60], [30, 78], [70, 78]],
  8: [[30, 18], [70, 18], [30, 38], [70, 38], [30, 58], [70, 58], [30, 78], [70, 78]],
  9: [[25, 18], [50, 18], [75, 18], [25, 50], [50, 50], [75, 50], [25, 82], [50, 82], [75, 82]],
};

function renderSouzu(n: number, size: number) {
  if (n === 1) {
    return (
      <svg viewBox="0 0 100 100" width={size} height={size}>
        <circle cx="50" cy="30" r="16" fill="#2d8a4e" />
        <rect x="44" y="30" width="12" height="50" rx="3" fill="#2d8a4e" />
        <rect x="38" y="48" width="24" height="3" rx="1.5" fill="#1a6030" />
        <rect x="38" y="62" width="24" height="3" rx="1.5" fill="#1a6030" />
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
    const y = 12 + row * (75 / rows);
    sticks.push([x, y]);
  }
  const stickH = Math.min(60 / rows, 30);
  return (
    <svg viewBox="0 0 100 100" width={size} height={size}>
      {sticks.map(([x, y], i) => (
        <g key={i}>
          <rect x={x - 5} y={y} width="10" height={stickH} rx="2" fill="#2d8a4e" />
          <rect x={x - 6} y={y + stickH * 0.35} width="12" height="2" rx="1" fill="#1a6030" />
          <rect x={x - 6} y={y + stickH * 0.65} width="12" height="2" rx="1" fill="#1a6030" />
        </g>
      ))}
    </svg>
  );
}

function renderPinzu(n: number, size: number) {
  const positions = pinPositions[n] ?? [];
  const r = n <= 2 ? 14 : n <= 4 ? 11 : n <= 6 ? 9 : 7;
  return (
    <svg viewBox="0 0 100 100" width={size} height={size}>
      {positions.map(([cx, cy], i) => (
        <g key={i}>
          <circle cx={cx} cy={cy} r={r} fill="#1a6fb5" />
          <circle cx={cx} cy={cy} r={r * 0.55} fill="#f8f4ec" />
          <circle cx={cx} cy={cy} r={r * 0.22} fill="#c41e3a" />
        </g>
      ))}
    </svg>
  );
}

function renderManzu(n: number, big: boolean) {
  const numSize = big ? 26 : 16;
  const manSize = big ? 20 : 13;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', lineHeight: 1, gap: 1 }}>
      <span style={{ fontSize: numSize, fontWeight: 700, color: '#1a1a2e', fontFamily: SERIF_FONT }}>{kanjiNumbers[n]}</span>
      <span style={{ fontSize: manSize, fontWeight: 700, color: '#c41e3a', fontFamily: SERIF_FONT }}>萬</span>
    </div>
  );
}

const jihaiInfo: Record<number, { char: string; color: string }> = {
  1: { char: '東', color: '#1a1a2e' },
  2: { char: '南', color: '#1a1a2e' },
  3: { char: '西', color: '#1a1a2e' },
  4: { char: '北', color: '#1a1a2e' },
  5: { char: '', color: '#888' },
  6: { char: '發', color: '#1a8a3e' },
  7: { char: '中', color: '#c41e3a' },
};

function renderTileFace(tile: Tile, big: boolean) {
  const artSize = big ? 42 : 28;

  if (tile.kind === 'suhai') {
    switch (tile.suit) {
      case 'manzu': return renderManzu(tile.number, big);
      case 'pinzu': return renderPinzu(tile.number, artSize);
      case 'souzu': return renderSouzu(tile.number, artSize);
    }
  }

  const info = jihaiInfo[tile.number];
  if (!info) return null;

  if (tile.number === 5) {
    const s = big ? 28 : 18;
    return <div style={{ width: s, height: s, border: '2px solid #999', borderRadius: 2 }} />;
  }

  return (
    <span style={{
      fontSize: big ? 32 : 20,
      fontWeight: 700,
      color: info.color,
      lineHeight: 1,
      fontFamily: SERIF_FONT,
    }}>
      {info.char}
    </span>
  );
}

export function TileView({ tile, onClick, selected, small, faceDown }: TileViewProps) {
  const w = small ? 28 : 44;
  const h = small ? 38 : 60;
  const depth = small ? 3 : 5;

  if (faceDown) {
    return (
      <div style={{ width: w, height: h, flexShrink: 0 }}>
        <div style={{
          width: w, height: h, borderRadius: 3,
          background: 'linear-gradient(160deg, #d4933a 0%, #b87a2a 50%, #a06820 100%)',
          border: '1px solid #8a5a1a',
          boxShadow: `0 ${depth}px 0 #6a4a15, 0 ${depth + 2}px 4px rgba(0,0,0,0.3)`,
          position: 'relative',
        }}>
          <div style={{ position: 'absolute', inset: 3, border: '1px solid rgba(255,220,150,0.3)', borderRadius: 2 }} />
        </div>
      </div>
    );
  }

  return (
    <div
      onClick={onClick}
      style={{
        width: w, height: h, flexShrink: 0,
        transform: selected ? 'translateY(-10px)' : undefined,
        transition: 'transform 0.12s',
        cursor: onClick ? 'pointer' : undefined,
      }}
      onMouseEnter={onClick ? (e) => { if (!selected) (e.currentTarget as HTMLElement).style.transform = 'translateY(-4px)'; } : undefined}
      onMouseLeave={onClick ? (e) => { if (!selected) (e.currentTarget as HTMLElement).style.transform = ''; } : undefined}
    >
      <div style={{
        width: w, height: h, borderRadius: 3,
        background: 'linear-gradient(175deg, #fefcf7 0%, #f0ead8 60%, #e4dcc8 100%)',
        border: selected ? '2px solid #eab308' : '1px solid #c0b8a8',
        boxShadow: selected
          ? `0 ${depth}px 0 #c8a040, 0 ${depth + 4}px 12px rgba(234,179,8,0.3)`
          : `0 ${depth}px 0 #a09880, 0 ${depth + 2}px 4px rgba(0,0,0,0.2)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative', userSelect: 'none',
      }}>
        <div style={{
          position: 'absolute', top: 0, left: 0, right: 0, height: 2,
          background: 'rgba(255,255,255,0.5)', borderRadius: '3px 3px 0 0',
        }} />
        {renderTileFace(tile, !small)}
      </div>
    </div>
  );
}
