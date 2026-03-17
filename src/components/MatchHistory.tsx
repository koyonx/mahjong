import { useState } from 'react';
import { getHistory, clearHistory, getStats, type MatchResult } from '../hooks/useMatchHistory';
import { kazeToJa } from '../mahjong-bridge';

interface MatchHistoryProps {
  onBack: () => void;
}

export function MatchHistory({ onBack }: MatchHistoryProps) {
  const [tab, setTab] = useState<'history' | 'stats'>('history');
  const [history, setHistory] = useState<MatchResult[]>(getHistory());
  const stats = getStats();

  const handleClear = () => {
    if (confirm('対局履歴を全て削除しますか？')) {
      clearHistory();
      setHistory([]);
    }
  };

  return (
    <div style={{ minHeight: '100vh', background: '#0d1a0f', color: '#ddd', padding: 20 }}>
      <div style={{ maxWidth: 600, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
          <h1 style={{ fontSize: 24, fontWeight: 700, color: '#e8c44a' }}>対局履歴</h1>
          <button onClick={onBack} style={{ padding: '6px 16px', background: '#333', border: 'none', borderRadius: 6, color: '#aaa', cursor: 'pointer' }}>戻る</button>
        </div>

        <div style={{ display: 'flex', gap: 4, marginBottom: 16 }}>
          {(['history', 'stats'] as const).map(t => (
            <button key={t} onClick={() => setTab(t)} style={{
              padding: '6px 14px', borderRadius: 6, border: 'none', cursor: 'pointer',
              fontSize: 13, fontWeight: 600,
              background: tab === t ? '#e8c44a' : '#2a3a2a', color: tab === t ? '#1a1a0a' : '#8a8',
            }}>{t === 'history' ? '履歴' : '統計'}</button>
          ))}
        </div>

        {tab === 'stats' && (
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            {[
              { label: '総対局数', value: stats.totalGames.toString() },
              { label: '勝利数', value: stats.wins.toString() },
              { label: '勝率', value: `${stats.winRate}%` },
              { label: '平均スコア', value: stats.avgScore.toLocaleString() },
              { label: '最高スコア', value: stats.bestScore.toLocaleString() },
            ].map((s, i) => (
              <div key={i} style={{ background: '#1a2a1a', borderRadius: 8, padding: '12px 16px' }}>
                <div style={{ fontSize: 11, color: '#888' }}>{s.label}</div>
                <div style={{ fontSize: 22, fontWeight: 700, color: '#e8c44a' }}>{s.value}</div>
              </div>
            ))}
          </div>
        )}

        {tab === 'history' && (
          <>
            {history.length === 0 ? (
              <p style={{ color: '#666', textAlign: 'center', marginTop: 40 }}>まだ対局履歴がありません</p>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {history.map((m, i) => (
                  <div key={i} style={{
                    background: '#1a2a1a', borderRadius: 8, padding: '10px 14px',
                    border: '1px solid #2a3a2a',
                  }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
                      <span style={{ fontSize: 11, color: '#888' }}>{m.date}</span>
                      <span style={{ fontSize: 11, color: '#888' }}>
                        {m.mode === 'single' ? `CPU戦 ${m.difficulty ?? ''}` : 'オンライン'}
                      </span>
                    </div>
                    <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
                      {m.players.sort((a, b) => b.score - a.score).map((p, j) => (
                        <div key={j} style={{
                          fontSize: 12,
                          color: p.name === m.winner ? '#e8c44a' : '#aaa',
                          fontWeight: p.name === m.winner ? 700 : 400,
                        }}>
                          {kazeToJa(p.jikaze)} {p.score.toLocaleString()}
                          {p.name === m.winner && ' 👑'}
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}
            {history.length > 0 && (
              <button onClick={handleClear} style={{
                marginTop: 16, padding: '8px 16px', background: '#5a2a2a', border: 'none',
                borderRadius: 6, color: '#f87171', cursor: 'pointer', fontSize: 12,
              }}>履歴を全て削除</button>
            )}
          </>
        )}
      </div>
    </div>
  );
}
