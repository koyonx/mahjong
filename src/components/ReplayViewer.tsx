import { useState } from 'react';
import type { ReplayData, ReplayAction } from '../hooks/useReplay';
import { kazeToJa, tileToDisplay } from '../mahjong-bridge';

interface ReplayViewerProps {
  replay: ReplayData;
  onBack: () => void;
}

const kazeNames = ['東', '南', '西', '北'];

function actionToText(action: ReplayAction): string {
  const who = `${kazeNames[action.seat] ?? '?'}家`;
  const tile = action.tile ? tileToDisplay(action.tile as any) : '';
  switch (action.type) {
    case 'draw': return `${who} ツモ`;
    case 'discard': return `${who} ${tile} 打牌`;
    case 'pon': return `${who} ポン ${tile}`;
    case 'chi': return `${who} チー`;
    case 'kan': return `${who} カン ${tile}`;
    case 'riichi': return `${who} リーチ宣言`;
    case 'tsumo_agari': return `${who} ツモ和了！`;
    case 'ron_agari': return `${who} ロン和了！ ${tile}`;
    case 'round_start': return `--- 局開始 ---`;
    case 'ryuukyoku': return `--- 流局 ---`;
    default: return `${who} ${action.type}`;
  }
}

export function ReplayViewer({ replay, onBack }: ReplayViewerProps) {
  const [pos, setPos] = useState(0);
  const [autoPlay, setAutoPlay] = useState(false);

  const actions = replay.actions;
  const current = actions.slice(0, pos + 1);

  const handleAutoPlay = () => {
    if (autoPlay) { setAutoPlay(false); return; }
    setAutoPlay(true);
    let i = pos;
    const interval = setInterval(() => {
      i++;
      if (i >= actions.length) { clearInterval(interval); setAutoPlay(false); return; }
      setPos(i);
    }, 500);
  };

  return (
    <div style={{ minHeight: '100vh', background: '#0d1a0f', color: '#ddd', padding: 20 }}>
      <div style={{ maxWidth: 600, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
          <h1 style={{ fontSize: 24, fontWeight: 700, color: '#e8c44a' }}>リプレイ</h1>
          <div style={{ display: 'flex', gap: 4 }}>
            <span style={{ fontSize: 12, color: '#888' }}>{replay.date}</span>
            <button onClick={onBack} style={{ padding: '4px 12px', background: '#333', border: 'none', borderRadius: 4, color: '#aaa', cursor: 'pointer' }}>戻る</button>
          </div>
        </div>

        {/* コントロール */}
        <div style={{ display: 'flex', gap: 6, justifyContent: 'center', marginBottom: 16 }}>
          {[
            { label: '◀◀', onClick: () => setPos(0) },
            { label: '◀', onClick: () => setPos(Math.max(0, pos - 1)) },
            { label: autoPlay ? '⏸' : '▶', onClick: handleAutoPlay },
            { label: '▶', onClick: () => setPos(Math.min(actions.length - 1, pos + 1)) },
            { label: '▶▶', onClick: () => setPos(actions.length - 1) },
          ].map((btn, i) => (
            <button key={i} onClick={btn.onClick} style={{
              padding: '6px 14px', background: '#2a3a2a', border: '1px solid #444',
              borderRadius: 6, color: '#e8c44a', fontSize: 16, cursor: 'pointer',
              fontWeight: 700,
            }}>{btn.label}</button>
          ))}
        </div>

        <div style={{ fontSize: 12, color: '#888', textAlign: 'center', marginBottom: 12 }}>
          {pos + 1} / {actions.length}
        </div>

        {/* アクションログ */}
        <div style={{
          maxHeight: 400, overflowY: 'auto', background: '#1a2a1a',
          borderRadius: 8, padding: 12,
        }}>
          {current.map((action, i) => (
            <div key={i} style={{
              padding: '4px 8px', fontSize: 12,
              color: i === pos ? '#e8c44a' : '#888',
              fontWeight: i === pos ? 700 : 400,
              background: i === pos ? 'rgba(232,196,74,0.1)' : 'transparent',
              borderRadius: 4,
            }}>
              {actionToText(action)}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
