(** 面子の種類 *)
type mentsu =
  | Shuntsu of Tile.tile * Tile.tile * Tile.tile  (** 順子: 連続する3枚の数牌 *)
  | Koutsu of Tile.tile                           (** 刻子: 同じ牌3枚 *)
  | Kantsu of Tile.tile                           (** 槓子: 同じ牌4枚 *)

(** 雀頭 *)
type jantai = Tile.tile

(** 和了形: 4面子1雀頭 *)
type agari_pattern = {
  mentsu_list : mentsu list;
  jantai : jantai;
}

(** 数牌の次の牌を返す *)
let next_suhai suit n =
  if n < 9 then Some (Tile.Suhai (suit, n + 1)) else None

(** 順子になりうるか判定 *)
let is_shuntsu t1 t2 t3 =
  match (t1, t2, t3) with
  | Tile.Suhai (s1, n1), Tile.Suhai (s2, n2), Tile.Suhai (s3, n3) ->
    s1 = s2 && s2 = s3 && n2 = n1 + 1 && n3 = n1 + 2
  | _ -> false

(** 刻子になりうるか判定 *)
let is_koutsu t1 t2 t3 =
  Tile.compare t1 t2 = 0 && Tile.compare t2 t3 = 0

(** リストから指定の牌を1枚取り除く *)
let remove_one tile tiles =
  let rec aux acc = function
    | [] -> None
    | x :: rest ->
      if Tile.compare x tile = 0 then Some (List.rev acc @ rest)
      else aux (x :: acc) rest
  in
  aux [] tiles

(** ソート済みの牌リストから全ての和了パターンを探索する *)
let find_agari_patterns (tiles : Tile.tile list) : agari_pattern list =
  let sorted = List.sort Tile.compare tiles in

  (* 面子を再帰的に抽出する *)
  let rec extract_mentsu (remaining : Tile.tile list) (acc_mentsu : mentsu list) : (mentsu list * Tile.tile list) list =
    match remaining with
    | [] -> [(List.rev acc_mentsu, [])]
    | t1 :: rest ->
      let results = ref [] in

      (* 刻子を試す *)
      (match rest with
       | t2 :: t3 :: rest2 when is_koutsu t1 t2 t3 ->
         let sub = extract_mentsu rest2 (Koutsu t1 :: acc_mentsu) in
         results := sub @ !results
       | _ -> ());

      (* 順子を試す *)
      (match t1 with
       | Tile.Suhai (suit, n) ->
         let t2 = Tile.Suhai (suit, n + 1) in
         let t3 = Tile.Suhai (suit, n + 2) in
         (match remove_one t2 rest with
          | Some rest_after_t2 ->
            (match remove_one t3 rest_after_t2 with
             | Some rest_after_t3 ->
               let sub = extract_mentsu rest_after_t3 (Shuntsu (t1, t2, t3) :: acc_mentsu) in
               results := sub @ !results
             | None -> ())
          | None -> ())
       | _ -> ());

      !results
  in

  (* 雀頭候補を列挙して、残りから4面子を探す *)
  let rec try_jantai (tiles : Tile.tile list) : agari_pattern list =
    match tiles with
    | [] -> []
    | t1 :: rest ->
      let patterns =
        match remove_one t1 rest with
        | Some rest_without_pair ->
          let mentsu_results = extract_mentsu (List.sort Tile.compare rest_without_pair) [] in
          List.filter_map (fun (ms, leftover) ->
            if leftover = [] && List.length ms = 4 then
              Some { mentsu_list = ms; jantai = t1 }
            else
              None
          ) mentsu_results
        | None -> []
      in
      (* 同じ牌の雀頭は一度だけ試す *)
      let skip_same = List.filter (fun t -> Tile.compare t t1 <> 0) rest in
      patterns @ try_jantai skip_same
  in

  try_jantai sorted

(** 和了判定: 14枚の手牌が4面子1雀頭に分解できるか *)
let is_agari (tiles : Tile.tile list) : bool =
  List.length tiles = 14 && find_agari_patterns tiles <> []
