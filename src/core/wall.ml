(** 山（牌山）の管理 *)

type t = {
  tiles : Tile.tile array;   (** 牌山 *)
  red : bool array;          (** 赤ドラフラグ（136要素） *)
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

(** 初回のみ乱数を初期化 *)
let _init = Random.self_init ()

(** 山を作成（シャッフル済み、赤ドラ付き） *)
let create () : t =
  let tiles = Array.of_list Tile.all_tiles in
  let red = Array.make 136 false in
  shuffle tiles;
  (* 各スート（萬筒索）の最初の5をひとつずつ赤ドラにする *)
  let marked = Array.make 3 false in  (* manzu=0, pinzu=1, souzu=2 *)
  Array.iteri (fun i tile ->
    match tile with
    | Tile.Suhai (Tile.Manzu, 5) when not marked.(0) -> red.(i) <- true; marked.(0) <- true
    | Tile.Suhai (Tile.Pinzu, 5) when not marked.(1) -> red.(i) <- true; marked.(1) <- true
    | Tile.Suhai (Tile.Souzu, 5) when not marked.(2) -> red.(i) <- true; marked.(2) <- true
    | _ -> ()
  ) tiles;
  { tiles; red; position = 0; dead_wall = 136 - 14 }

(** シード指定で山を作成（テスト用） *)
let create_with_seed (seed : int) : t =
  Random.init seed;
  create ()

(** 指定位置が赤ドラかチェック *)
let is_red_at (wall : t) (pos : int) : bool =
  pos >= 0 && pos < 136 && wall.red.(pos)

(** 牌をツモる（牌, 赤ドラか, 新しい山） *)
let draw (wall : t) : (Tile.tile * bool * t) option =
  if wall.position >= wall.dead_wall then None
  else
    let tile = wall.tiles.(wall.position) in
    let is_red = wall.red.(wall.position) in
    Some (tile, is_red, { wall with position = wall.position + 1 })

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

(** 裏ドラ表示牌を取得（ドラ表示牌の隣） *)
let uradora_indicators (wall : t) (kan_count : int) : Tile.tile list =
  let base = 136 - 6 in  (* ドラ表示牌の1つ下 *)
  List.init (1 + kan_count) (fun i ->
    wall.tiles.(base - i * 2)
  )

(** 表ドラ枚数をカウント *)
let count_dora (wall : t) (kan_count : int) (tiles : Tile.tile list) : int =
  let indicators = dora_indicators wall kan_count in
  let doras = List.map dora_of_indicator indicators in
  List.fold_left (fun acc tile ->
    acc + List.length (List.filter (fun d -> Tile.compare d tile = 0) doras)
  ) 0 tiles

(** 裏ドラ枚数をカウント *)
let count_uradora (wall : t) (kan_count : int) (tiles : Tile.tile list) : int =
  let indicators = uradora_indicators wall kan_count in
  let doras = List.map dora_of_indicator indicators in
  List.fold_left (fun acc tile ->
    acc + List.length (List.filter (fun d -> Tile.compare d tile = 0) doras)
  ) 0 tiles
