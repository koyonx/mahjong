import { useState } from 'react';

export interface AssistConfig {
  showWaitCounts: boolean;
  showShanten: boolean;
  showDangerTiles: boolean;
}

const DEFAULT_CONFIG: AssistConfig = {
  showWaitCounts: true,
  showShanten: false,
  showDangerTiles: false,
};

const STORAGE_KEY = 'mahjong_assist_config';

export function loadAssistConfig(): AssistConfig {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) return { ...DEFAULT_CONFIG, ...JSON.parse(saved) };
  } catch {}
  return DEFAULT_CONFIG;
}

export function saveAssistConfig(config: AssistConfig): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
}

interface AssistSettingsProps {
  config: AssistConfig;
  onChange: (config: AssistConfig) => void;
  onClose: () => void;
}

export function AssistSettings({ config, onChange, onClose }: AssistSettingsProps) {
  const toggle = (key: keyof AssistConfig) => {
    const next = { ...config, [key]: !config[key] };
    onChange(next);
    saveAssistConfig(next);
  };

  return (
    <div style={{
      position: 'absolute', top: 44, left: 8, zIndex: 30,
      background: '#1a1a28', border: '1px solid #444', borderRadius: 8,
      padding: '12px 16px', minWidth: 200,
      boxShadow: '0 4px 16px rgba(0,0,0,0.5)',
    }}>
      <div style={{ fontSize: 13, fontWeight: 700, color: '#e8c44a', marginBottom: 8 }}>補助表示</div>
      {([
        { key: 'showWaitCounts' as const, label: '待ち牌の残り枚数' },
        { key: 'showShanten' as const, label: '向聴数' },
        { key: 'showDangerTiles' as const, label: '危険牌警告' },
      ]).map(item => (
        <label key={item.key} style={{
          display: 'flex', alignItems: 'center', gap: 8, padding: '4px 0',
          cursor: 'pointer', fontSize: 12, color: '#ccc',
        }}>
          <input
            type="checkbox"
            checked={config[item.key]}
            onChange={() => toggle(item.key)}
            style={{ accentColor: '#e8c44a' }}
          />
          {item.label}
        </label>
      ))}
      <button onClick={onClose} style={{
        marginTop: 8, padding: '4px 12px', background: '#333', border: 'none',
        borderRadius: 4, color: '#aaa', fontSize: 11, cursor: 'pointer',
      }}>閉じる</button>
    </div>
  );
}
