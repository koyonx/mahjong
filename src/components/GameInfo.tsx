import type { GameState } from '../mahjong-bridge';
import { kazeToJa } from '../mahjong-bridge';

interface GameInfoProps {
  state: GameState;
}

export function GameInfo({ state }: GameInfoProps) {
  return (
    <div className="flex items-center justify-center gap-6 py-2 px-4 bg-green-950/50 rounded-lg">
      <div className="text-center">
        <div className="text-xs text-green-300">場風</div>
        <div className="text-xl font-bold">{kazeToJa(state.bakaze)}</div>
      </div>
      <div className="text-center">
        <div className="text-xs text-green-300">局</div>
        <div className="text-xl font-bold">
          {kazeToJa(state.bakaze)}{state.kyoku}局
        </div>
      </div>
      <div className="text-center">
        <div className="text-xs text-green-300">本場</div>
        <div className="text-xl font-bold">{state.honba}</div>
      </div>
      <div className="text-center">
        <div className="text-xs text-green-300">残り</div>
        <div className="text-xl font-bold">{state.remaining_tiles}枚</div>
      </div>
    </div>
  );
}
