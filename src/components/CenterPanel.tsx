import type { GameState } from '../mahjong-bridge';
import { kazeToJa } from '../mahjong-bridge';

interface CenterPanelProps {
  state: GameState;
  mySeat?: number;
}

const windPositions = [
  { label: '東', top: '100%', left: '50%', transform: 'translate(-50%, -120%)' },   // 下
  { label: '南', top: '50%', left: '100%', transform: 'translate(-120%, -50%)' },   // 右
  { label: '西', top: '0%', left: '50%', transform: 'translate(-50%, 20%)' },       // 上
  { label: '北', top: '50%', left: '0%', transform: 'translate(20%, -50%)' },       // 左
];

export function CenterPanel({ state, mySeat = 0 }: CenterPanelProps) {
  const relativeSeat = (offset: number) => (mySeat + offset) % 4;

  // 各方向のプレイヤー: 下=自分, 右, 上, 左
  const positions = [
    { seat: mySeat, pos: 'bottom' },
    { seat: relativeSeat(1), pos: 'right' },
    { seat: relativeSeat(2), pos: 'top' },
    { seat: relativeSeat(3), pos: 'left' },
  ];

  return (
    <div style={{
      width: 160, height: 160,
      background: 'linear-gradient(145deg, #2a2a3a, #1a1a28)',
      border: '2px solid #444',
      borderRadius: 8,
      position: 'relative',
      boxShadow: '0 4px 20px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.05)',
    }}>
      {/* 中央の局情報 */}
      <div style={{
        position: 'absolute', top: '50%', left: '50%',
        transform: 'translate(-50%, -50%)',
        textAlign: 'center',
      }}>
        <div style={{ fontSize: 16, fontWeight: 700, color: '#e8c44a' }}>
          {kazeToJa(state.bakaze)}{state.kyoku}局
        </div>
        <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>
          残{state.remaining_tiles}枚
        </div>
        {state.honba > 0 && (
          <div style={{ fontSize: 10, color: '#888' }}>
            {state.honba}本場
          </div>
        )}
      </div>

      {/* 各プレイヤーのスコア */}
      {positions.map(({ seat, pos }) => {
        const player = state.players[seat];
        const isCurrent = state.current_turn === seat;
        const wind = kazeToJa(player.jikaze);

        const style: React.CSSProperties = {
          position: 'absolute',
          display: 'flex',
          alignItems: 'center',
          gap: 4,
          fontSize: 11,
          whiteSpace: 'nowrap',
        };

        switch (pos) {
          case 'bottom':
            Object.assign(style, { bottom: 8, left: '50%', transform: 'translateX(-50%)' });
            break;
          case 'top':
            Object.assign(style, { top: 8, left: '50%', transform: 'translateX(-50%)' });
            break;
          case 'left':
            Object.assign(style, { left: 8, top: '50%', transform: 'translateY(-50%)', flexDirection: 'column' });
            break;
          case 'right':
            Object.assign(style, { right: 8, top: '50%', transform: 'translateY(-50%)', flexDirection: 'column' });
            break;
        }

        return (
          <div key={seat} style={style}>
            <span style={{
              color: isCurrent ? '#e8c44a' : '#888',
              fontWeight: 700,
              fontSize: 13,
            }}>
              {wind}
            </span>
            <span style={{
              color: seat === mySeat ? '#f0d060' : '#aaa',
              fontFamily: 'monospace',
              fontWeight: 600,
            }}>
              {player.score.toLocaleString()}
            </span>
          </div>
        );
      })}
    </div>
  );
}
