.PHONY: setup build test dev clean ocaml-build ocaml-test ocaml-watch melange-copy docker-build server-dev server-install stop stop-docker stop-server stop-dev

# === セットアップ ===

setup: docker-build npm-install server-install melange-copy ## 初回セットアップ（Docker + npm + Melange出力コピー）

docker-build: ## Dockerイメージをビルド
	docker compose build

npm-install: ## npm依存関係をインストール
	npm install

server-install: ## サーバー依存関係をインストール
	cd server && npm install

# === OCaml (Docker) ===

ocaml-build: ## OCamlソースをビルド
	docker compose run --rm ocaml dune build

ocaml-test: ## OCamlテストを実行
	docker compose run --rm ocaml dune test

ocaml-watch: ## OCamlソースをウォッチビルド
	docker compose up

ocaml-shell: ## OCamlコンテナにシェルで入る
	docker compose run --rm ocaml bash

# === Melange ===

melange-copy: ## MelangeのJS出力をsrc/generatedにコピー
	bash scripts/copy-melange-output.sh

# === サーバー ===

server-dev: ## WebSocketサーバーを起動（開発モード）
	node --experimental-strip-types --experimental-detect-module server/src/index.ts

# === フロントエンド ===

dev: ## 開発サーバーを起動（フロント + サーバー両方必要）
	npm run dev

dev-all: ## フロント + サーバーを同時起動
	@echo "ターミナル1: make server-dev"
	@echo "ターミナル2: make dev"
	@echo "（別々のターミナルで実行してください）"

build: ocaml-build melange-copy ## プロダクションビルド（OCaml + フロント）
	npm run build

# === テスト ===

test: ocaml-test ## 全テストを実行

# === 停止 ===

stop: stop-docker stop-server stop-dev ## 全サービスを停止

stop-docker: ## Dockerコンテナを停止
	docker compose down

stop-server: ## WebSocketサーバーを停止
	@-lsof -ti :8080 | xargs kill 2>/dev/null; echo "WebSocketサーバーを停止しました"

stop-dev: ## フロントエンド開発サーバーを停止
	@-lsof -ti :5173 | xargs kill 2>/dev/null; echo "開発サーバーを停止しました"

# === クリーンアップ ===

clean: stop ## ビルド成果物を削除 + 全サービス停止
	rm -rf dist _build src/generated node_modules/.vite

# === ヘルプ ===

help: ## コマンド一覧を表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
