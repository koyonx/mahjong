import type { WaitCount, DangerTile } from '../mahjong-bridge';
import { TileView } from './TileView';
import type { AssistConfig } from './AssistSettings';

interface AssistDisplayProps {
  config: AssistConfig;
  shanten: number;
  waitCounts: WaitCount[];
  dangerTiles: DangerTile[];
}

const dangerColors = {
  high: '#f87171',
  medium: '#fbbf24',
  low: '#4ade80',
};

export function AssistDisplay({ config, shanten, waitCounts, dangerTiles }: AssistDisplayProps) {
  const hasContent = (config.showShanten && shanten >= 0) ||
    (config.showWaitCounts && waitCounts.length > 0) ||
    (config.showDangerTiles && dangerTiles.length > 0);

  if (!hasContent) return null;

  return (
    <div style={{
      display: 'flex', flexWrap: 'wrap', gap: 8, justifyContent: 'center',
      marginTop: 4, padding: '4px 8px',
      background: 'rgba(0,0,0,0.3)', borderRadius: 6,
      fontSize: 11,
    }}>
      {/* 向聴数 */}
      {config.showShanten && shanten >= 0 && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, color: '#aaa' }}>
          <span style={{ color: '#e8c44a', fontWeight: 700 }}>
            {shanten === 0 ? 'テンパイ' : `${shanten}向聴`}
          </span>
        </div>
      )}

      {/* 待ち牌残り枚数 */}
      {config.showWaitCounts && waitCounts.length > 0 && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
          <span style={{ color: '#888' }}>待ち:</span>
          {waitCounts.map((w, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <TileView tile={w.tile} small />
              <span style={{
                color: w.remaining === 0 ? '#f87171' : '#4ade80',
                fontWeight: 700, fontSize: 10,
              }}>
                ×{w.remaining}
              </span>
            </div>
          ))}
        </div>
      )}

      {/* 危険牌 */}
      {config.showDangerTiles && dangerTiles.length > 0 && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
          <span style={{ color: '#f87171' }}>危険:</span>
          {dangerTiles.slice(0, 5).map((d, i) => (
            <div key={i} style={{
              position: 'relative',
              border: `1px solid ${dangerColors[d.level]}`,
              borderRadius: 3,
            }}>
              <TileView tile={d.tile} small />
              <div style={{
                position: 'absolute', top: -6, right: -4,
                width: 8, height: 8, borderRadius: '50%',
                background: dangerColors[d.level],
              }} />
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
