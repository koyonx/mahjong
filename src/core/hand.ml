(** 手牌 *)
type t = {
  tiles : Tile.tile list;      (** 手牌（ツモ牌含む、最大14枚） *)
  tsumo : Tile.tile option;    (** 最後にツモった牌 *)
}

(** 空の手牌 *)
let empty = { tiles = []; tsumo = None }

(** 手牌を作成 *)
let make tiles = {
  tiles = List.sort Tile.compare tiles;
  tsumo = None;
}

(** 手牌の枚数 *)
let count hand = List.length hand.tiles

(** 牌を追加（ツモ） *)
let tsumo tile hand =
  if count hand >= 14 then
    Error "手牌が14枚を超えます"
  else
    Ok { tiles = List.sort Tile.compare (tile :: hand.tiles); tsumo = Some tile }

(** 牌を捨てる *)
let discard tile hand =
  match Mentsu.remove_one tile hand.tiles with
  | Some remaining -> Ok { tiles = remaining; tsumo = None }
  | None -> Error "指定された牌が手牌にありません"

(** 手牌をソート *)
let sort hand =
  { hand with tiles = List.sort Tile.compare hand.tiles }

(** 手牌を文字列に変換 *)
let to_string hand =
  hand.tiles
  |> List.map Tile.to_string
  |> String.concat " "

(** 和了判定 *)
let is_agari hand =
  Mentsu.is_agari hand.tiles

(** 和了パターンを取得 *)
let agari_patterns hand =
  Mentsu.find_agari_patterns hand.tiles

(** テンパイ判定: 何か1枚加えれば和了になるか（13枚の手牌用） *)
let tenpai_tiles hand =
  if count hand <> 13 then []
  else
    let candidates =
      let suits = [Tile.Manzu; Tile.Pinzu; Tile.Souzu] in
      let numbers = [1; 2; 3; 4; 5; 6; 7; 8; 9] in
      let jihais = [Tile.Ton; Tile.Nan; Tile.Sha; Tile.Pei; Tile.Haku; Tile.Hatsu; Tile.Chun] in
      let suhai = List.concat_map (fun s -> List.map (fun n -> Tile.Suhai (s, n)) numbers) suits in
      let jihai = List.map (fun j -> Tile.Jihai j) jihais in
      suhai @ jihai
    in
    List.filter (fun t ->
      Mentsu.is_agari (List.sort Tile.compare (t :: hand.tiles))
    ) candidates
