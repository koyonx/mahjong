(** 符計算の基礎 *)

(** 和了者の情報 *)
type agari_info = {
  han : int;          (** 翻数 *)
  fu : int;           (** 符 *)
  is_oya : bool;      (** 親か *)
  is_tsumo : bool;    (** ツモか *)
}

(** 符の切り上げ（10符単位） *)
let round_up_fu fu =
  let r = fu mod 10 in
  if r = 0 then fu else fu + (10 - r)

(** 面子の符を計算 *)
let fu_of_mentsu = function
  | Mentsu.Shuntsu _ -> 0
  | Mentsu.Koutsu t ->
    let base = if Yaku.is_yaochu t then 8 else 4 in
    base
  | Mentsu.Kantsu t ->
    let base = if Yaku.is_yaochu t then 32 else 16 in
    base

(** 雀頭の符を計算 *)
let fu_of_jantai (jantai : Tile.tile) (ctx : Yaku.agari_context) : int =
  match jantai with
  | Tile.Jihai j ->
    let fu = ref 0 in
    if j = Tile.Haku || j = Tile.Hatsu || j = Tile.Chun then fu := 2;
    if j = ctx.bakaze then fu := !fu + 2;
    if j = ctx.jikaze then fu := !fu + 2;
    !fu
  | _ -> 0

(** 和了形から符を計算 *)
let calculate_fu (pattern : Mentsu.agari_pattern) (ctx : Yaku.agari_context) : int =
  let base_fu = 30 in  (* 副底 *)
  let mentsu_fu = List.fold_left (fun acc m -> acc + fu_of_mentsu m) 0 pattern.mentsu_list in
  let jantai_fu = fu_of_jantai pattern.jantai ctx in
  let tsumo_fu = if ctx.is_tsumo then 2 else 0 in
  let total = base_fu + mentsu_fu + jantai_fu + tsumo_fu in
  round_up_fu total

(** 基本点の計算 *)
let base_points (han : int) (fu : int) : int =
  if han >= 13 then 8000          (* 役満 *)
  else if han >= 11 then 6000     (* 三倍満 *)
  else if han >= 8 then 4000      (* 倍満 *)
  else if han >= 6 then 3000      (* 跳満 *)
  else if han = 5 then 2000       (* 満貫 *)
  else
    let bp = fu * (1 lsl (han + 2)) in
    if bp >= 2000 then 2000       (* 満貫切り上げ *)
    else bp

(** 100点単位切り上げ *)
let round_up_100 n =
  let r = n mod 100 in
  if r = 0 then n else n + (100 - r)

(** 点数結果 *)
type score_result = {
  total : int;               (** 合計点 *)
  payments : payment;        (** 支払い *)
  han_detail : int;          (** 翻数 *)
  fu_detail : int;           (** 符数 *)
  yakus : Yaku.yaku list;    (** 成立した役 *)
}

and payment =
  | Ron of int                     (** ロン: 放銃者が支払う点数 *)
  | Tsumo_oya of int               (** ツモ(親): 子が各自支払う点数 *)
  | Tsumo_ko of int * int          (** ツモ(子): 親の支払い * 子の支払い *)

(** 最終的な点数を計算 *)
let calculate (info : agari_info) : payment =
  let bp = base_points info.han info.fu in
  if info.is_tsumo then begin
    if info.is_oya then
      (* 親ツモ: 子が各自 基本点×2 *)
      Tsumo_oya (round_up_100 (bp * 2))
    else
      (* 子ツモ: 親 基本点×2, 子 基本点×1 *)
      Tsumo_ko (round_up_100 (bp * 2), round_up_100 bp)
  end else begin
    if info.is_oya then
      (* 親ロン: 基本点×6 *)
      Ron (round_up_100 (bp * 6))
    else
      (* 子ロン: 基本点×4 *)
      Ron (round_up_100 (bp * 4))
  end

(** 全体の点数計算（役判定→符計算→点数計算） *)
let score_hand ?(furo_count=0) ?(furo_mentsu=[]) (tiles : Tile.tile list) (ctx : Yaku.agari_context) (is_oya : bool) : score_result option =
  match Yaku.judge ~furo_count ~furo_mentsu tiles ctx with
  | None -> None
  | Some (yakus, han) ->
    let patterns = Mentsu.find_agari_patterns_furo tiles furo_count in
    let fu =
      if List.exists (fun y -> y = Yaku.Chiitoitsu) yakus then 25
      else
        match patterns with
        | [] -> 30
        | _ ->
          let fus = List.map (fun p -> calculate_fu p ctx) patterns in
          List.fold_left max 0 fus
    in
    let info = { han; fu; is_oya; is_tsumo = ctx.is_tsumo } in
    let payment = calculate info in
    let total = match payment with
      | Ron n -> n
      | Tsumo_oya n -> n * 3
      | Tsumo_ko (oya_pay, ko_pay) -> oya_pay + ko_pay * 2
    in
    Some { total; payments = payment; han_detail = han; fu_detail = fu; yakus }
