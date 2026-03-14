import type { AgariResult } from '../mahjong-bridge';

interface AgariDialogProps {
  result: AgariResult;
  winnerName: string;
  onClose: () => void;
}

export function AgariDialog({ result, winnerName, onClose }: AgariDialogProps) {
  const paymentText = () => {
    const p = result.payment;
    switch (p.kind) {
      case 'ron':
        return `ロン ${p.ron?.toLocaleString()}点`;
      case 'tsumo_oya':
        return `ツモ ${p.ko_pay?.toLocaleString()}点オール`;
      case 'tsumo_ko':
        return `ツモ ${p.oya_pay?.toLocaleString()}/${p.ko_pay?.toLocaleString()}点`;
    }
  };

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
      <div className="bg-green-950 border-2 border-yellow-400 rounded-xl p-8 max-w-md w-full mx-4 shadow-2xl">
        <h2 className="text-3xl font-bold text-yellow-400 text-center mb-4">
          和了
        </h2>
        <p className="text-center text-lg mb-4">{winnerName}</p>

        <div className="space-y-2 mb-6">
          {result.yakus.map((yaku, i) => (
            <div key={i} className="flex justify-between px-4 py-1 bg-green-900/50 rounded">
              <span>{yaku.name}</span>
              <span className="text-amber-300">{yaku.han}翻</span>
            </div>
          ))}
        </div>

        <div className="text-center space-y-1 mb-6">
          <div className="text-sm text-green-300">
            {result.han}翻 {result.fu}符
          </div>
          <div className="text-2xl font-bold text-yellow-400">
            {result.total.toLocaleString()}点
          </div>
          <div className="text-sm text-green-300">
            {paymentText()}
          </div>
        </div>

        <button
          onClick={onClose}
          className="w-full py-3 bg-yellow-500 hover:bg-yellow-400 text-green-950 font-bold rounded-lg transition"
        >
          次の局へ
        </button>
      </div>
    </div>
  );
}
