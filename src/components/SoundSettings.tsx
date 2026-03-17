import { useState, useRef } from 'react';
import {
  isSoundEnabled, setSoundEnabled,
  getCustomSound, uploadCustomSound, resetCustomSound,
} from '../hooks/useSound';

interface SoundSettingsProps {
  onClose: () => void;
}

export function SoundSettings({ onClose }: SoundSettingsProps) {
  const [enabled, setEnabled] = useState(isSoundEnabled());
  const [hasTsumo, setHasTsumo] = useState(!!getCustomSound('tsumo'));
  const [hasRon, setHasRon] = useState(!!getCustomSound('ron'));
  const tsumoRef = useRef<HTMLInputElement>(null);
  const ronRef = useRef<HTMLInputElement>(null);

  const handleToggle = () => {
    const next = !enabled;
    setEnabled(next);
    setSoundEnabled(next);
  };

  const handleUpload = async (type: 'tsumo' | 'ron', file: File | undefined) => {
    if (!file) return;
    await uploadCustomSound(type, file);
    if (type === 'tsumo') setHasTsumo(true);
    else setHasRon(true);
  };

  const handleReset = (type: 'tsumo' | 'ron') => {
    resetCustomSound(type);
    if (type === 'tsumo') setHasTsumo(false);
    else setHasRon(false);
  };

  const btn = (label: string, onClick: () => void, bg = '#333') => (
    <button onClick={onClick} style={{
      padding: '4px 10px', background: bg, border: 'none', borderRadius: 4,
      color: '#ccc', fontSize: 11, cursor: 'pointer',
    }}>{label}</button>
  );

  return (
    <div style={{
      position: 'absolute', top: 44, left: 8, zIndex: 30,
      background: '#1a1a28', border: '1px solid #444', borderRadius: 8,
      padding: '12px 16px', minWidth: 220,
      boxShadow: '0 4px 16px rgba(0,0,0,0.5)',
    }}>
      <div style={{ fontSize: 13, fontWeight: 700, color: '#e8c44a', marginBottom: 8 }}>サウンド設定</div>

      <label style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10, cursor: 'pointer', fontSize: 12, color: '#ccc' }}>
        <input type="checkbox" checked={enabled} onChange={handleToggle} style={{ accentColor: '#e8c44a' }} />
        サウンド ON
      </label>

      {/* ツモ音 */}
      <div style={{ marginBottom: 8 }}>
        <div style={{ fontSize: 11, color: '#888', marginBottom: 4 }}>ツモ和了音 {hasTsumo ? '(カスタム)' : '(デフォルト)'}</div>
        <div style={{ display: 'flex', gap: 4 }}>
          {btn('アップロード', () => tsumoRef.current?.click(), '#2a5a8a')}
          {hasTsumo && btn('リセット', () => handleReset('tsumo'))}
          <input ref={tsumoRef} type="file" accept="audio/*" hidden
            onChange={e => handleUpload('tsumo', e.target.files?.[0])} />
        </div>
      </div>

      {/* ロン音 */}
      <div style={{ marginBottom: 8 }}>
        <div style={{ fontSize: 11, color: '#888', marginBottom: 4 }}>ロン和了音 {hasRon ? '(カスタム)' : '(デフォルト)'}</div>
        <div style={{ display: 'flex', gap: 4 }}>
          {btn('アップロード', () => ronRef.current?.click(), '#2a5a8a')}
          {hasRon && btn('リセット', () => handleReset('ron'))}
          <input ref={ronRef} type="file" accept="audio/*" hidden
            onChange={e => handleUpload('ron', e.target.files?.[0])} />
        </div>
      </div>

      {btn('閉じる', onClose)}
    </div>
  );
}
