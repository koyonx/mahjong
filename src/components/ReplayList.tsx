import { useState } from 'react';
import { listReplays, deleteReplay } from '../hooks/useReplay';

interface ReplayListProps {
  onSelect: (id: string) => void;
  onBack: () => void;
}

export function ReplayList({ onSelect, onBack }: ReplayListProps) {
  const [replays, setReplays] = useState(listReplays());

  const handleDelete = (id: string) => {
    deleteReplay(id);
    setReplays(listReplays());
  };

  return (
    <div style={{ minHeight: '100vh', background: '#0d1a0f', color: '#ddd', padding: 20 }}>
      <div style={{ maxWidth: 500, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
          <h1 style={{ fontSize: 24, fontWeight: 700, color: '#e8c44a' }}>リプレイ一覧</h1>
          <button onClick={onBack} style={{ padding: '6px 16px', background: '#333', border: 'none', borderRadius: 6, color: '#aaa', cursor: 'pointer' }}>戻る</button>
        </div>

        {replays.length === 0 ? (
          <p style={{ color: '#666', textAlign: 'center', marginTop: 40 }}>リプレイデータがありません</p>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {replays.map(r => (
              <div key={r.id} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: '10px 14px', background: '#1a2a1a', borderRadius: 8, border: '1px solid #2a3a2a',
              }}>
                <span style={{ fontSize: 13, color: '#ccc' }}>{r.date}</span>
                <div style={{ display: 'flex', gap: 6 }}>
                  <button onClick={() => onSelect(r.id)} style={{
                    padding: '4px 12px', background: '#2a5a8a', border: 'none', borderRadius: 4,
                    color: '#fff', fontSize: 12, cursor: 'pointer',
                  }}>再生</button>
                  <button onClick={() => handleDelete(r.id)} style={{
                    padding: '4px 12px', background: '#5a2a2a', border: 'none', borderRadius: 4,
                    color: '#f87171', fontSize: 12, cursor: 'pointer',
                  }}>削除</button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
