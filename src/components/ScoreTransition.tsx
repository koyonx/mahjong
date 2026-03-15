import type { Player } from '../mahjong-bridge';
import { kazeToJa } from '../mahjong-bridge';

interface ScoreTransitionProps {
  beforeScores: { jikaze: string; score: number }[];
  afterScores: { jikaze: string; score: number }[];
  reason: string; // '流局' or '和了'
}

export function ScoreTransition({ beforeScores, afterScores, reason }: ScoreTransitionProps) {
  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
      <div style={{
        background: '#1a2a1a',
        border: '2px solid #444',
        borderRadius: 12,
        padding: '24px 32px',
        minWidth: 300,
        boxShadow: '0 8px 32px rgba(0,0,0,0.5)',
      }}>
        <h3 style={{ textAlign: 'center', color: '#e8c44a', fontSize: 18, fontWeight: 700, marginBottom: 16 }}>
          {reason} — 点数移動
        </h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {afterScores.map((after, i) => {
            const before = beforeScores[i];
            const diff = after.score - before.score;
            return (
              <div key={i} style={{
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                padding: '6px 12px', background: 'rgba(255,255,255,0.05)', borderRadius: 6,
              }}>
                <span style={{ fontWeight: 700, color: '#ccc', minWidth: 30 }}>
                  {kazeToJa(after.jikaze)}
                </span>
                <span style={{ color: '#999', fontFamily: 'monospace', fontSize: 13 }}>
                  {before.score.toLocaleString()}
                </span>
                <span style={{ margin: '0 8px', color: '#888' }}>→</span>
                <span style={{ fontWeight: 700, fontFamily: 'monospace', fontSize: 14, color: '#eee', minWidth: 60, textAlign: 'right' }}>
                  {after.score.toLocaleString()}
                </span>
                <span style={{
                  fontWeight: 700, fontFamily: 'monospace', fontSize: 13, minWidth: 70, textAlign: 'right',
                  color: diff > 0 ? '#4ade80' : diff < 0 ? '#f87171' : '#888',
                }}>
                  {diff > 0 ? `+${diff.toLocaleString()}` : diff < 0 ? diff.toLocaleString() : '±0'}
                </span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
