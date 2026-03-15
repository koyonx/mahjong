# CLAUDE.md - 麻雀プロジェクト

## プロジェクト概要
日本式麻雀（リーチ麻雀）のWebアプリケーション。一人プレイ（CPU対戦）とオンライン対戦に対応。

## 技術スタック
- **麻雀ロジック**: OCaml（Melange経由でJSにコンパイル）
- **フロントエンド**: React + TypeScript
- **サーバー**: Node.js + WebSocket (ws)
- **スタイリング**: Tailwind CSS + インラインスタイル
- **ビルドツール**: Dune (OCaml) + Vite (フロント)
- **テスト**: OUnit2 (OCamlロジック)
- **パッケージ管理**: opam (OCaml) + npm (JS)
- **OCaml環境**: Docker（開発環境をコンテナで管理）

## ブランチ戦略
- **機能単位で細かくブランチを切り分け、PRを作成する**
- 新しいブランチは常に現在の作業ブランチから切る（mainからではない）
  - 例: `feature/tile-types` → `feature/hand-evaluation` → `feature/scoring`
- ブランチ名は `feature/<機能名>` の形式にする
- PRのマージ先は直前の親ブランチとする
- 各PRは小さく、レビューしやすい単位に保つ
- **1つの機能追加やバグ修正に対して1つのPRを立てる**

## コーディング規約
- 麻雀のコアロジック（牌の定義、手牌補完、役判定、点数計算）はすべてOCamlで実装する
- OCaml側では代数的データ型とパターンマッチを活用し、牌・面子・役を型安全に表現する
- UIはReact + TypeScriptで実装し、Melange経由でOCamlロジックを呼び出す
- 麻雀用語は英語表記を使用する（例: `hai`, `mentsu`, `agari`, `tsumo`）
- OCamlの日本語文字列はMelangeで文字化けするため、日本語表示はTypeScript側で定義する

## ディレクトリ構成
```
src/
  core/              # OCaml - 麻雀ロジック（UI非依存）
    tile.ml           # 牌の型定義
    hand.ml           # 手牌管理・テンパイ判定
    mentsu.ml         # 面子判定・和了パターン探索
    yaku.ml           # 役判定
    scoring.ml        # 符計算・点数計算
    wall.ml           # 牌山・ドラ・赤ドラ
    player.ml         # プレイヤー状態・副露（ポン・チー・カン）
    game.ml           # ゲーム進行管理・流局精算
    ai.ml             # CPU思考ロジック
  bindings/          # Melange - OCaml→JSバインディング
    mahjong_js.ml     # クライアント用API
    mahjong_server_js.ml  # サーバー用API（マルチルーム対応）
  components/        # React - UIコンポーネント
    TileView.tsx      # 牌の表示（SVG描画・赤ドラ対応）
    PlayerHand.tsx    # 手牌（ツモ牌分離・副露表示）
    Kawa.tsx          # 河（捨て牌・6列グリッド）
    CenterPanel.tsx   # 中央スコアパネル
    DoraDisplay.tsx   # ドラ表示牌
    GameBoard.tsx     # シングルプレイ用ゲームボード
    MultiplayerGameBoard.tsx  # マルチプレイ用ゲームボード
    Lobby.tsx         # ルーム作成/参加UI
    AgariDialog.tsx   # 和了結果表示（手牌・ドラ・裏ドラ）
    ScoreTransition.tsx  # 点数移動表示
  hooks/
    useMultiplayer.ts # WebSocket通信フック
  protocol.ts        # WebSocketメッセージ型定義
  mahjong-bridge.ts  # TypeScript型定義・APIラッパー・役名マッピング
server/
  src/
    index.ts          # WebSocketサーバーエントリポイント
    room-manager.ts   # ルーム管理（座席シャッフル・ゲームモード）
    game-controller.ts # ゲーム進行管理
test/
  test_mahjong.ml    # OUnit2テスト
scripts/
  copy-melange-output.sh  # Melange出力コピー＋パッチ
```

## Docker環境
- OCamlのビルド・テストはDocker内で実行する
- `docker compose` でOCaml環境を管理

## コマンド（Makefile）
```bash
make help              # コマンド一覧を表示
make setup             # 初回セットアップ（Docker + npm + サーバー + Melange）
make dev               # フロントエンド開発サーバー起動
make server-dev        # WebSocketサーバー起動（開発モード）
make build             # プロダクションビルド（OCaml + フロント）
make test              # OCamlテスト実行
make ocaml-build       # OCamlビルド
make ocaml-test        # OCamlテスト
make melange-copy      # Melange JS出力をコピー
make stop              # 全サービス停止
make stop-server       # WebSocketサーバー停止
make stop-dev          # フロント開発サーバー停止
make clean             # ビルド成果物削除 + 全停止
```

## 注意事項
- Melange出力の`string.js`はVite/Rolldownとの互換性問題があるため、`copy-melange-output.sh`でパッチを適用している
- サーバーは`node --experimental-strip-types`で実行する（tsxはMelange ESMと互換性がない）
- OCaml変更後は必ず`make melange-copy`を実行してJS出力を更新する
