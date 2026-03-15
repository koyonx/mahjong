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

  (* 一意な雀頭候補を列挙 *)
  let unique_jantai_candidates =
    let rec aux seen = function
      | [] -> []
      | t :: rest ->
        if List.exists (fun s -> Tile.compare s t = 0) seen then
          aux seen rest
        else
          (* ペアが存在するか確認 *)
          let count = List.length (List.filter (fun x -> Tile.compare x t = 0) sorted) in
          if count >= 2 then t :: aux (t :: seen) rest
          else aux (t :: seen) rest
    in
    aux [] sorted
  in

  (* 各雀頭候補について、残りから4面子を探す *)
  List.concat_map (fun jantai ->
    match remove_one jantai sorted with
    | Some rest1 ->
      (match remove_one jantai rest1 with
       | Some rest_without_pair ->
         let mentsu_results = extract_mentsu (List.sort Tile.compare rest_without_pair) [] in
         List.filter_map (fun (ms, leftover) ->
           if leftover = [] && List.length ms = 4 then
             Some { mentsu_list = ms; jantai }
           else
             None
         ) mentsu_results
       | None -> [])
    | None -> []
  ) unique_jantai_candidates

(** 副露を考慮した和了パターン探索 *)
let find_agari_patterns_furo (tiles : Tile.tile list) (furo_count : int) : agari_pattern list =
  let needed = 4 - furo_count in
  let sorted = List.sort Tile.compare tiles in

  let rec extract_mentsu (remaining : Tile.tile list) (acc_mentsu : mentsu list) : (mentsu list * Tile.tile list) list =
    match remaining with
    | [] -> [(List.rev acc_mentsu, [])]
    | t1 :: rest ->
      let results = ref [] in
      (match rest with
       | t2 :: t3 :: rest2 when is_koutsu t1 t2 t3 ->
         let sub = extract_mentsu rest2 (Koutsu t1 :: acc_mentsu) in
         results := sub @ !results
       | _ -> ());
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

  let unique_jantai_candidates =
    let rec aux seen = function
      | [] -> []
      | t :: rest ->
        if List.exists (fun s -> Tile.compare s t = 0) seen then aux seen rest
        else
          let count = List.length (List.filter (fun x -> Tile.compare x t = 0) sorted) in
          if count >= 2 then t :: aux (t :: seen) rest
          else aux (t :: seen) rest
    in
    aux [] sorted
  in

  List.concat_map (fun jantai ->
    match remove_one jantai sorted with
    | Some rest1 ->
      (match remove_one jantai rest1 with
       | Some rest_without_pair ->
         let mentsu_results = extract_mentsu (List.sort Tile.compare rest_without_pair) [] in
         List.filter_map (fun (ms, leftover) ->
           if leftover = [] && List.length ms = needed then
             Some { mentsu_list = ms; jantai }
           else
             None
         ) mentsu_results
       | None -> [])
    | None -> []
  ) unique_jantai_candidates

(** 和了判定: 14枚の手牌が4面子1雀頭に分解できるか *)
let is_agari (tiles : Tile.tile list) : bool =
  List.length tiles = 14 && find_agari_patterns tiles <> []
