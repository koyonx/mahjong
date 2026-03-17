import type { WaitCount, DangerTile, HandAnalysis, WinProbability } from '../mahjong-bridge';
import { directionName, actionName } from '../mahjong-bridge';
import { TileView } from './TileView';
import type { AssistConfig } from './AssistSettings';

interface AssistDisplayProps {
  config: AssistConfig;
  shanten: number;
  waitCounts: WaitCount[];
  dangerTiles: DangerTile[];
  handAnalysis?: HandAnalysis | null;
  winProb?: WinProbability | null;
}

const dangerColors = {
  high: '#f87171',
  medium: '#fbbf24',
  low: '#4ade80',
};

export function AssistDisplay({ config, shanten, waitCounts, dangerTiles, handAnalysis, winProb }: AssistDisplayProps) {
  const hasContent = (config.showShanten && shanten >= 0) ||
    (config.showWaitCounts && waitCounts.length > 0) ||
    (config.showDangerTiles && dangerTiles.length > 0) ||
    (config.showAnalysis && handAnalysis) ||
    (config.showWinRate && winProb);

  if (!hasContent) return null;

  return (
    <div style={{
      display: 'flex', flexDirection: 'column', gap: 4,
      marginTop: 4, padding: '4px 8px',
      background: 'rgba(0,0,0,0.3)', borderRadius: 6,
      fontSize: 11,
    }}>
      {/* 上段: 向聴数 + 待ち + 危険牌 */}
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, justifyContent: 'center' }}>
        {config.showShanten && shanten >= 0 && (
          <span style={{ color: '#e8c44a', fontWeight: 700 }}>
            {shanten === 0 ? 'テンパイ' : `${shanten}向聴`}
          </span>
        )}

        {config.showWaitCounts && waitCounts.length > 0 && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <span style={{ color: '#888' }}>待ち:</span>
            {waitCounts.map((w, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                <TileView tile={w.tile} small />
                <span style={{
                  color: w.remaining === 0 ? '#f87171' : '#4ade80',
                  fontWeight: 700, fontSize: 10,
                }}>×{w.remaining}</span>
              </div>
            ))}
          </div>
        )}

        {config.showDangerTiles && dangerTiles.length > 0 && (
          <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <span style={{ color: '#f87171' }}>危険:</span>
            {dangerTiles.slice(0, 5).map((d, i) => (
              <div key={i} style={{
                position: 'relative',
                border: `1px solid ${dangerColors[d.level]}`, borderRadius: 3,
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

      {/* 手牌分析 */}
      {config.showAnalysis && handAnalysis && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, justifyContent: 'center', color: '#aaa' }}>
          <span>方向: <span style={{ color: '#e8c44a' }}>{directionName(handAnalysis.direction)}</span></span>
          <span>推奨: <span style={{ color: '#4ade80' }}>{actionName(handAnalysis.action)}</span></span>
          {handAnalysis.discards.length > 0 && (
            <span>最適打: <span style={{ color: '#fff' }}>
              {handAnalysis.discards.slice(0, 2).map(d =>
                `${d.tile.label}(${d.acceptance}枚)`
              ).join(' / ')}
            </span></span>
          )}
        </div>
      )}

      {/* 勝率 */}
      {config.showWinRate && winProb && (
        <div style={{ display: 'flex', gap: 8, justifyContent: 'center', color: '#aaa' }}>
          <span>勝率: <span style={{ color: '#e8c44a', fontWeight: 700 }}>{winProb.win_rate}%</span></span>
          <span>聴牌率: <span style={{ color: '#4ade80' }}>{winProb.tenpai_rate}%</span></span>
          <span>平均点: <span style={{ color: '#fff' }}>{winProb.avg_score}</span></span>
        </div>
      )}
    </div>
  );
}
