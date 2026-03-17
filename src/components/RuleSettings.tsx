import { useState } from 'react';
import { loadGameRules, saveGameRules, type GameRules } from '../hooks/useGameRules';

interface RuleSettingsProps {
  onBack: () => void;
}

export function RuleSettings({ onBack }: RuleSettingsProps) {
  const [rules, setRules] = useState<GameRules>(loadGameRules());

  const update = (patch: Partial<GameRules>) => {
    const next = { ...rules, ...patch };
    setRules(next);
    saveGameRules(next);
  };

  const Toggle = ({ label, desc, value, onChange }: { label: string; desc: string; value: boolean; onChange: (v: boolean) => void }) => (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '12px 16px', background: '#1a2a1a', borderRadius: 8, marginBottom: 8,
    }}>
      <div>
        <div style={{ fontSize: 14, fontWeight: 600, color: '#eee' }}>{label}</div>
        <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>{desc}</div>
      </div>
      <button onClick={() => onChange(!value)} style={{
        padding: '4px 16px', borderRadius: 6, border: 'none', cursor: 'pointer',
        fontWeight: 700, fontSize: 13,
        background: value ? '#4ade80' : '#555',
        color: value ? '#0a1a0a' : '#aaa',
      }}>{value ? 'ON' : 'OFF'}</button>
    </div>
  );

  return (
    <div style={{ minHeight: '100vh', background: '#0d1a0f', color: '#ddd', padding: 20 }}>
      <div style={{ maxWidth: 500, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
          <h1 style={{ fontSize: 24, fontWeight: 700, color: '#e8c44a' }}>ルール設定</h1>
          <button onClick={onBack} style={{ padding: '6px 16px', background: '#333', border: 'none', borderRadius: 6, color: '#aaa', cursor: 'pointer' }}>戻る</button>
        </div>

        <Toggle label="赤ドラ" desc="5萬・5筒・5索の各1枚が赤ドラ（+1翻）" value={rules.redDora} onChange={v => update({ redDora: v })} />
        <Toggle label="食いタン" desc="鳴いても断么九が成立する" value={rules.openTanyao} onChange={v => update({ openTanyao: v })} />

        <div style={{ padding: '12px 16px', background: '#1a2a1a', borderRadius: 8, marginBottom: 8 }}>
          <div style={{ fontSize: 14, fontWeight: 600, color: '#eee', marginBottom: 8 }}>初期持ち点</div>
          <div style={{ display: 'flex', gap: 8 }}>
            {[25000, 30000].map(s => (
              <button key={s} onClick={() => update({ startScore: s })} style={{
                flex: 1, padding: '8px', borderRadius: 6, border: 'none', cursor: 'pointer',
                fontWeight: 700, fontSize: 14,
                background: rules.startScore === s ? '#e8c44a' : '#333',
                color: rules.startScore === s ? '#0a1a0a' : '#aaa',
              }}>{s.toLocaleString()}</button>
            ))}
          </div>
        </div>

        <div style={{ padding: '12px 16px', background: '#1a2a1a', borderRadius: 8, marginBottom: 8 }}>
          <div style={{ fontSize: 14, fontWeight: 600, color: '#eee', marginBottom: 8 }}>対局形式</div>
          <div style={{ display: 'flex', gap: 8 }}>
            {([['hanchan', '半荘戦'], ['tonpuu', '東風戦']] as const).map(([key, label]) => (
              <button key={key} onClick={() => update({ gameMode: key })} style={{
                flex: 1, padding: '8px', borderRadius: 6, border: 'none', cursor: 'pointer',
                fontWeight: 700, fontSize: 14,
                background: rules.gameMode === key ? '#e8c44a' : '#333',
                color: rules.gameMode === key ? '#0a1a0a' : '#aaa',
              }}>{label}</button>
            ))}
          </div>
        </div>

        <p style={{ marginTop: 16, fontSize: 11, color: '#666' }}>
          ※ 一部のルールはゲームロジックへの反映が今後のアップデートで追加されます
        </p>
      </div>
    </div>
  );
}
