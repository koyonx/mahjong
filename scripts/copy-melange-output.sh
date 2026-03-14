#!/bin/bash
# MelangeのJS出力をフロントエンドから参照できる位置にコピーする
set -e

CONTAINER_OUTPUT="/home/opam/app/_build/default/src/bindings/output"
LOCAL_OUTPUT="./src/generated"

mkdir -p "$LOCAL_OUTPUT"

docker compose run --rm ocaml bash -c "
  dune build && \
  tar cf - -C $CONTAINER_OUTPUT .
" | tar xf - -C "$LOCAL_OUTPUT"

# Vite/Rolldownとの互換性のため、Melange出力の変数名衝突を修正
# string.js 内で Rolldown が const min → min$1 にリネームし、
# 元の min$1 と衝突する問題を回避する
if [ -f "$LOCAL_OUTPUT/node_modules/melange/string.js" ]; then
  # forループ内の min → edit_min, min$1 → edit_min2 にリネーム
  sed -i.bak \
    -e 's/const min = Stdlib__Int\.min(Caml_array/const edit_min = Stdlib__Int.min(Caml_array/g' \
    -e 's/const min\$1 = i > 1/const edit_min2 = i > 1/g' \
    -e 's/Stdlib__Int\.min(min, Caml_array\.get(row_minus2/Stdlib__Int.min(edit_min, Caml_array.get(row_minus2/g' \
    -e 's/cost | 0) : min;/cost | 0) : edit_min;/g' \
    -e 's/Caml_array\.set(row, j, min\$1)/Caml_array.set(row, j, edit_min2)/g' \
    -e 's/row_min = Stdlib__Int\.min(row_min, min\$1)/row_min = Stdlib__Int.min(row_min, edit_min2)/g' \
    -e 's/const min = {/const min_ref = {/g' \
    -e 's/min\.contents/min_ref.contents/g' \
    "$LOCAL_OUTPUT/node_modules/melange/string.js"
  rm -f "$LOCAL_OUTPUT/node_modules/melange/string.js.bak"
fi

# サーバーからMelange stdlibを解決できるようシンボリックリンクを作成
if [ -d "$LOCAL_OUTPUT/node_modules/melange" ]; then
  MELANGE_MODULES="$LOCAL_OUTPUT/node_modules"

  # ルートのnode_modulesにもリンク
  for dir in "$MELANGE_MODULES"/melange*; do
    name=$(basename "$dir")
    target=$(cd "$dir" && pwd)
    rm -rf "node_modules/$name"
    ln -sf "$target" "node_modules/$name"
  done

  # serverのnode_modulesにもリンク
  if [ -d "server/node_modules" ]; then
    for dir in "$MELANGE_MODULES"/melange*; do
      name=$(basename "$dir")
      target=$(cd "$dir" && pwd)
      rm -rf "server/node_modules/$name"
      ln -sf "$target" "server/node_modules/$name"
    done
  fi
fi

echo "Melange output copied to $LOCAL_OUTPUT"
