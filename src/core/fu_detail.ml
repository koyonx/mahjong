(* 符の詳細計算 — 待ち型判定含む *)

(* 待ちの種類 *)
type wait_type =
  | Ryanmen    (** 両面待ち: 例 3-4 で 2 or 5 待ち *)
  | Shanpon    (** シャンポン待ち: 2つの対子 *)
  | Kanchan    (** 嵌張待ち: 例 3-5 で 4 待ち *)
  | Penchan    (** 辺張待ち: 例 1-2 で 3 待ち, 8-9 で 7 待ち *)
  | Tanki      (** 単騎待ち: 雀頭1枚待ち *)

(* 面子の開閉 *)
type mentsu_state =
  | Open       (** 副露（明刻/明順/明槓） *)
  | Closed     (** 門前（暗刻/暗順/暗槓） *)

(* 面子の符 *)
type mentsu_fu_detail = {
  mentsu_type : string;     (** "shuntsu" / "ankou" / "minkou" / "ankan" / "minkan" *)
  tile_label : string;      (** 代表牌のラベル *)
  fu : int;                 (** この面子の符 *)
}

(* 符の内訳 *)
type fu_breakdown = {
  base_fu : int;            (** 副底 20 or 30 *)
  mentsu_fu_list : mentsu_fu_detail list;  (** 面子ごとの符 *)
  jantai_fu : int;          (** 雀頭の符 *)
  wait_type : wait_type;    (** 待ちの種類 *)
  wait_fu : int;            (** 待ちの符 *)
  tsumo_fu : int;           (** ツモ符 *)
  total_fu : int;           (** 合計（切り上げ前） *)
  rounded_fu : int;         (** 合計（10符切り上げ後） *)
}

(* 么九牌判定 *)
let is_yaochu_tile = function
  | Tile.Suhai (_, n) -> n = 1 || n = 9
  | Tile.Jihai _ -> true

(* 面子の符を計算 *)
let calc_mentsu_fu (m : Mentsu.mentsu) (is_furo : bool) : mentsu_fu_detail =
  match m with
  | Mentsu.Shuntsu (t, _, _) ->
    { mentsu_type = "shuntsu"; tile_label = Tile.to_string t; fu = 0 }
  | Mentsu.Koutsu t ->
    let base = if is_yaochu_tile t then 8 else 4 in
    let fu = if is_furo then base / 2 else base in  (* 明刻は半分 *)
    { mentsu_type = (if is_furo then "minkou" else "ankou");
      tile_label = Tile.to_string t; fu }
  | Mentsu.Kantsu t ->
    let base = if is_yaochu_tile t then 32 else 16 in
    let fu = if is_furo then base / 2 else base in
    { mentsu_type = (if is_furo then "minkan" else "ankan");
      tile_label = Tile.to_string t; fu }

(* 雀頭の符 *)
let calc_jantai_fu (jantai : Tile.tile) (bakaze : Tile.jihai) (jikaze : Tile.jihai) : int =
  match jantai with
  | Tile.Jihai j ->
    let fu = ref 0 in
    if j = Tile.Haku || j = Tile.Hatsu || j = Tile.Chun then fu := 2;
    if j = bakaze then fu := !fu + 2;
    if j = jikaze then fu := !fu + 2;
    !fu
  | _ -> 0

(* 待ち型の判定 *)
(* agari_tile: 和了牌, pattern: 和了パターン *)
let detect_wait_type (agari_tile : Tile.tile) (pattern : Mentsu.agari_pattern) : wait_type =
  (* 雀頭待ち（単騎）チェック *)
  if Tile.compare agari_tile pattern.jantai = 0 then Tanki
  else
    (* 和了牌がどの面子に含まれるか探す *)
    let in_mentsu = List.filter (fun m ->
      match m with
      | Mentsu.Shuntsu (t1, t2, t3) ->
        Tile.compare agari_tile t1 = 0 ||
        Tile.compare agari_tile t2 = 0 ||
        Tile.compare agari_tile t3 = 0
      | Mentsu.Koutsu t | Mentsu.Kantsu t ->
        Tile.compare agari_tile t = 0
    ) pattern.mentsu_list in
    match in_mentsu with
    | [] -> Tanki  (* フォールバック *)
    | m :: _ ->
      match m with
      | Mentsu.Koutsu _ | Mentsu.Kantsu _ -> Shanpon
      | Mentsu.Shuntsu (t1, _, t3) ->
        let n1 = match t1 with Tile.Suhai (_, n) -> n | _ -> 0 in
        let n3 = match t3 with Tile.Suhai (_, n) -> n | _ -> 0 in
        let na = match agari_tile with Tile.Suhai (_, n) -> n | _ -> 0 in
        if na = n1 + 1 then Kanchan        (* 嵌張: 真ん中 *)
        else if na = n1 && n1 = 1 then Penchan   (* 辺張: 12で3待ち *)
        else if na = n3 && n3 = 9 then Penchan   (* 辺張: 89で7待ち *)
        else Ryanmen                         (* 両面 *)

(* 待ち型の符 *)
let fu_of_wait_type = function
  | Ryanmen -> 0
  | Shanpon -> 0
  | Kanchan -> 2
  | Penchan -> 2
  | Tanki -> 2

(* 待ち型の日本語名 *)
let wait_type_to_string = function
  | Ryanmen -> "ryanmen"
  | Shanpon -> "shanpon"
  | Kanchan -> "kanchan"
  | Penchan -> "penchan"
  | Tanki -> "tanki"

let wait_type_to_ja = function
  | Ryanmen -> "両面"
  | Shanpon -> "シャンポン"
  | Kanchan -> "嵌張"
  | Penchan -> "辺張"
  | Tanki -> "単騎"

(* 符の詳細計算 *)
let calculate_fu_detail
    (pattern : Mentsu.agari_pattern)
    (agari_tile : Tile.tile option)
    (is_tsumo : bool)
    (is_menzen : bool)
    (furo_count : int)
    (bakaze : Tile.jihai)
    (jikaze : Tile.jihai)
  : fu_breakdown =

  (* 副底 *)
  let base_fu = if is_menzen && not is_tsumo then 30 else 20 in

  (* 面子の符（手牌面子 + 副露面子） *)
  let total_mentsu = List.length pattern.mentsu_list in
  let hand_count = total_mentsu - furo_count in
  let mentsu_fu_list = List.mapi (fun i m ->
    let is_furo = i >= hand_count in
    calc_mentsu_fu m is_furo
  ) pattern.mentsu_list in

  (* 雀頭の符 *)
  let jantai_fu = calc_jantai_fu pattern.jantai bakaze jikaze in

  (* 待ち型 *)
  let wait_type = match agari_tile with
    | Some t -> detect_wait_type t pattern
    | None -> Ryanmen  (* 不明な場合は両面扱い *)
  in
  let wait_fu = fu_of_wait_type wait_type in

  (* ツモ符 *)
  let tsumo_fu = if is_tsumo && is_menzen then 2 else 0 in

  (* 合計 *)
  let mentsu_total = List.fold_left (fun acc d -> acc + d.fu) 0 mentsu_fu_list in
  let total = base_fu + mentsu_total + jantai_fu + wait_fu + tsumo_fu in

  (* 切り上げ *)
  let rounded = let r = total mod 10 in
    if r = 0 then total else total + (10 - r)
  in

  { base_fu; mentsu_fu_list; jantai_fu; wait_type; wait_fu;
    tsumo_fu; total_fu = total; rounded_fu = rounded }

(* 和了パターンの中で最も符が高いものを計算 *)
let best_fu_breakdown
    (patterns : Mentsu.agari_pattern list)
    (agari_tile : Tile.tile option)
    (is_tsumo : bool)
    (is_menzen : bool)
    (furo_count : int)
    (bakaze : Tile.jihai)
    (jikaze : Tile.jihai)
  : fu_breakdown option =
  let breakdowns = List.map (fun p ->
    calculate_fu_detail p agari_tile is_tsumo is_menzen furo_count bakaze jikaze
  ) patterns in
  match breakdowns with
  | [] -> None
  | _ -> Some (List.fold_left (fun best b ->
      if b.rounded_fu > best.rounded_fu then b else best
    ) (List.hd breakdowns) breakdowns)
