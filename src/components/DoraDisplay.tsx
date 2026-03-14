import type { Tile } from '../mahjong-bridge';
import { TileView } from './TileView';

interface DoraDisplayProps {
  indicators: Tile[];
}

export function DoraDisplay({ indicators }: DoraDisplayProps) {
  if (!indicators || indicators.length === 0) return null;

  return (
    <div style={{
      position: 'absolute', top: 8, left: 8, zIndex: 20,
      background: 'rgba(0,0,0,0.6)',
      border: '1px solid #444',
      borderRadius: 6,
      padding: '6px 10px',
    }}>
      <div style={{ fontSize: 10, color: '#aaa', marginBottom: 4 }}>ドラ表示牌</div>
      <div style={{ display: 'flex', gap: 3 }}>
        {indicators.map((t, i) => (
          <TileView key={i} tile={t} small />
        ))}
      </div>
    </div>
  );
}
