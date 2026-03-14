.PHONY: setup build test dev clean ocaml-build ocaml-test ocaml-watch melange-copy docker-build

# === セットアップ ===

setup: docker-build npm-install melange-copy ## 初回セットアップ（Docker + npm + Melange出力コピー）

docker-build: ## Dockerイメージをビルド
	docker compose build

npm-install: ## npm依存関係をインストール
	npm install

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

# === フロントエンド ===

dev: ## 開発サーバーを起動
	npm run dev

build: ocaml-build melange-copy ## プロダクションビルド（OCaml + フロント）
	npm run build

# === テスト ===

test: ocaml-test ## 全テストを実行

# === クリーンアップ ===

clean: ## ビルド成果物を削除
	rm -rf dist _build src/generated node_modules/.vite

# === ヘルプ ===

help: ## コマンド一覧を表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
