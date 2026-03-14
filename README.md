# 麻雀 - 日本式リーチ麻雀

日本式リーチ麻雀のWebアプリケーション。麻雀のコアロジック（牌・面子・役判定・点数計算）をOCamlで実装し、MelangeでJavaScriptにコンパイルしてReactフロントエンドから利用しています。

## 必要な環境

- Docker
- Node.js (v18+)
- npm

## セットアップ

```bash
# 初回セットアップ（Dockerイメージビルド + npm install + サーバー + Melange出力コピー）
make setup
```

## 起動方法

### 一人プレイ（CPU対戦）

```bash
make dev
# http://localhost:5173 を開いて「一人プレイ」を選択
```

### オンライン対戦

2つのターミナルが必要です：

```bash
# ターミナル1: WebSocketサーバー起動
make server-dev

# ターミナル2: フロントエンド起動
make dev
```

http://localhost:5173 を開いて「オンライン対戦」を選択します。

1. 一人が「ルームを作成」→ 6文字のルームIDが表示される
2. 他のプレイヤーが「ルームに参加」→ ルームIDを入力
3. ホストが「ゲーム開始」を押すとゲームスタート
4. 4人未満の場合、空席はCPUが埋めます

同じネットワーク内の他の端末からは `http://<ホストのIP>:5173` でアクセスできます。

OCamlのソースを変更した場合は、Melange出力の再コピーが必要です：

```bash
make melange-copy
```

## コマンド一覧

```bash
make help              # コマンド一覧を表示
make setup             # 初回セットアップ
make dev               # フロントエンド開発サーバー起動
make server-dev        # WebSocketサーバー起動（開発モード）
make build             # プロダクションビルド
make test              # テスト実行
make ocaml-build       # OCamlビルド
make ocaml-test        # OCamlテスト
make ocaml-watch       # OCamlウォッチビルド
make ocaml-shell       # OCamlコンテナにシェルで入る
make melange-copy      # Melange JS出力をコピー
make server-install    # サーバー依存関係インストール
make clean             # ビルド成果物を削除
```

## プロジェクト構成

```
src/
  core/              # OCaml - 麻雀ロジック
    tile.ml           # 牌の型定義
    mentsu.ml         # 面子判定・和了パターン探索
    hand.ml           # 手牌管理・テンパイ判定
    yaku.ml           # 役判定
    scoring.ml        # 符計算・点数計算
    wall.ml           # 牌山・ドラ
    player.ml         # プレイヤー状態・副露
    game.ml           # 局進行管理
    ai.ml             # CPU思考ロジック
  bindings/          # Melange - OCaml→JSバインディング
    mahjong_js.ml     # クライアント用API
    mahjong_server_js.ml  # サーバー用API（マルチルーム対応）
  components/        # React - UIコンポーネント
  hooks/             # React カスタムフック
    useMultiplayer.ts # WebSocket通信フック
  protocol.ts        # WebSocketプロトコル型定義
  mahjong-bridge.ts  # TypeScript型定義・APIラッパー
server/
  src/
    index.ts          # WebSocketサーバーエントリポイント
    room-manager.ts   # ルーム管理
    game-controller.ts # ゲーム進行管理
test/
  test_mahjong.ml    # OUnit2テスト
```

## 技術スタック

| レイヤー | 技術 |
|---------|------|
| 麻雀ロジック | OCaml (Melange) |
| フロントエンド | React + TypeScript |
| サーバー | Node.js + WebSocket (ws) |
| スタイリング | Tailwind CSS |
| ビルド | Dune (OCaml) + Vite (フロント) |
| テスト | OUnit2 |
| OCaml環境 | Docker |
