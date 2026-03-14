(** 山（牌山）の管理 *)

type t = {
  tiles : Tile.tile array;   (** 牌山 *)
  position : int;            (** 現在のツモ位置 *)
  dead_wall : int;           (** 王牌の開始位置（残り14枚） *)
}

(** Fisher-Yatesシャッフル *)
let shuffle arr =
  let n = Array.length arr in
  for i = n - 1 downto 1 do
    let j = Random.int (i + 1) in
    let tmp = arr.(i) in
    arr.(i) <- arr.(j);
    arr.(j) <- tmp
  done

(** 山を作成（シャッフル済み） *)
let create () : t =
  let tiles = Array.of_list Tile.all_tiles in
  shuffle tiles;
  { tiles; position = 0; dead_wall = 136 - 14 }

(** シード指定で山を作成（テスト用） *)
let create_with_seed (seed : int) : t =
  Random.init seed;
  create ()

(** 牌をツモる *)
let draw (wall : t) : (Tile.tile * t) option =
  if wall.position >= wall.dead_wall then None
  else
    let tile = wall.tiles.(wall.position) in
    Some (tile, { wall with position = wall.position + 1 })

(** 残りツモ枚数 *)
let remaining (wall : t) : int =
  wall.dead_wall - wall.position

(** ドラ表示牌を取得 *)
let dora_indicators (wall : t) (kan_count : int) : Tile.tile list =
  let base = 136 - 5 in  (* 王牌の上から5枚目がドラ表示牌 *)
  List.init (1 + kan_count) (fun i ->
    wall.tiles.(base - i * 2)
  )

(** ドラ表示牌から実際のドラを取得 *)
let dora_of_indicator (indicator : Tile.tile) : Tile.tile =
  match indicator with
  | Tile.Suhai (suit, 9) -> Tile.Suhai (suit, 1)
  | Tile.Suhai (suit, n) -> Tile.Suhai (suit, n + 1)
  | Tile.Jihai Tile.Pei -> Tile.Jihai Tile.Ton
  | Tile.Jihai Tile.Ton -> Tile.Jihai Tile.Nan
  | Tile.Jihai Tile.Nan -> Tile.Jihai Tile.Sha
  | Tile.Jihai Tile.Sha -> Tile.Jihai Tile.Pei
  | Tile.Jihai Tile.Chun -> Tile.Jihai Tile.Haku
  | Tile.Jihai Tile.Haku -> Tile.Jihai Tile.Hatsu
  | Tile.Jihai Tile.Hatsu -> Tile.Jihai Tile.Chun

(** 手牌中のドラ枚数をカウント *)
let count_dora (wall : t) (kan_count : int) (tiles : Tile.tile list) : int =
  let indicators = dora_indicators wall kan_count in
  let doras = List.map dora_of_indicator indicators in
  List.fold_left (fun acc tile ->
    acc + List.length (List.filter (fun d -> Tile.compare d tile = 0) doras)
  ) 0 tiles
