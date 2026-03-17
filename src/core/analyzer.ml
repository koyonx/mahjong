(* 手牌アナライザー — 最適打牌の提案と分析 *)

(* 打牌候補の分析結果 *)
type discard_analysis = {
  tile : Tile.tile;              (** 捨て牌 *)
  shanten_after : int;           (** 捨てた後の向聴数 *)
  acceptance : int;              (** 受入枚数 *)
  wait_tiles : Tile.tile list;   (** 改善する牌のリスト *)
  estimated_han : int;           (** 推定翻数 *)
  reason : string;               (** 推薦理由（英語ID） *)
}

(* 手牌分析の全体結果 *)
type hand_analysis = {
  current_shanten : int;            (** 現在の向聴数 *)
  is_tenpai : bool;                 (** テンパイか *)
  best_discards : discard_analysis list;  (** 推薦打牌（スコア順） *)
  hand_direction : string;          (** 手の方向性 *)
  recommended_action : string;      (** 推奨アクション *)
}

(* index→牌変換 *)
let tile_of_index = function
  | n when n < 9 -> Tile.Suhai (Tile.Manzu, n + 1)
  | n when n < 18 -> Tile.Suhai (Tile.Pinzu, n - 8)
  | n when n < 27 -> Tile.Suhai (Tile.Souzu, n - 17)
  | 27 -> Tile.Jihai Tile.Ton | 28 -> Tile.Jihai Tile.Nan
  | 29 -> Tile.Jihai Tile.Sha | 30 -> Tile.Jihai Tile.Pei
  | 31 -> Tile.Jihai Tile.Haku | 32 -> Tile.Jihai Tile.Hatsu
  | _ -> Tile.Jihai Tile.Chun

(* 各捨て牌候補を分析 *)
let analyze_discard (tile : Tile.tile) (hand_tiles : Tile.tile list)
    (furo_count : int) (visible : Tile.tile list)
    (bakaze : Tile.jihai) (jikaze : Tile.jihai) (dora_tiles : Tile.tile list)
  : discard_analysis option =
  match Mentsu.remove_one tile hand_tiles with
  | None -> None
  | Some rest ->
    let sh = Ai.estimate_shanten rest furo_count in

    (* 受入牌を特定 *)
    let visible_c = Ai.counts_of_tiles visible in
    let wait_tiles = ref [] in
    let acceptance = ref 0 in
    for idx = 0 to 33 do
      let unseen = max 0 (4 - visible_c.(idx)) in
      if unseen > 0 then begin
        let t = tile_of_index idx in
        let test = t :: rest in
        let new_sh = Ai.estimate_shanten test furo_count in
        if new_sh < sh then begin
          wait_tiles := t :: !wait_tiles;
          acceptance := !acceptance + unseen
        end
      end
    done;

    (* 推定翻数 *)
    let path = Ai.analyze_yaku_path rest bakaze jikaze dora_tiles in
    let han = Ai.estimate_hand_han path (furo_count = 0) in

    (* 推薦理由 *)
    let reason =
      if Ai.is_isolated tile hand_tiles then "isolated"
      else if Ai.count_tile tile hand_tiles = 1 && sh > 0 then "low_value"
      else if List.exists (fun d -> Tile.compare d tile = 0) dora_tiles then "dora_cut"
      else "efficiency"
    in

    Some {
      tile;
      shanten_after = sh;
      acceptance = !acceptance;
      wait_tiles = List.rev !wait_tiles;
      estimated_han = han;
      reason;
    }

(* 手の方向性を判定 *)
let detect_direction (tiles : Tile.tile list) (bakaze : Tile.jihai) (jikaze : Tile.jihai) (dora_tiles : Tile.tile list) : string =
  let path = Ai.analyze_yaku_path tiles bakaze jikaze dora_tiles in
  if path.chinitsu_score > 0 then "chinitsu"
  else if path.honitsu_score > 0 then "honitsu"
  else if path.tanyao_score > 0 then "tanyao"
  else if path.toitoi_score > 0 then "toitoi"
  else if path.yakuhai_count > 0 then "yakuhai"
  else if Ai.calc_shanten_chiitoitsu tiles <= 2 then "chiitoitsu"
  else "general"

(* 推奨アクションを決定 *)
let recommend_action (shanten : int) (is_menzen : bool) (has_riichi_opponent : bool) : string =
  if shanten = 0 then
    if is_menzen then "riichi_or_damaten"
    else "wait_for_agari"
  else if shanten = 1 then
    if has_riichi_opponent then "balanced_offense_defense"
    else "push_for_tenpai"
  else if shanten = 2 then
    if has_riichi_opponent then "consider_defense"
    else "build_hand"
  else
    if has_riichi_opponent then "full_defense"
    else "early_game_build"

(* 手牌の完全分析 *)
let analyze_hand (hand_tiles : Tile.tile list) (furo_count : int)
    (visible : Tile.tile list) (bakaze : Tile.jihai) (jikaze : Tile.jihai)
    (dora_tiles : Tile.tile list) (has_riichi_opponent : bool)
  : hand_analysis =
  let current_shanten = Ai.estimate_shanten hand_tiles furo_count in
  let is_tenpai = current_shanten = 0 in

  (* 全捨て牌候補を分析 *)
  let unique = Ai.unique_tiles hand_tiles in
  let analyses = List.filter_map (fun t ->
    analyze_discard t hand_tiles furo_count visible bakaze jikaze dora_tiles
  ) unique in

  (* 最良向聴数の候補だけフィルタ *)
  let min_sh = List.fold_left (fun acc a -> min acc a.shanten_after) 100 analyses in
  let best_sh = List.filter (fun a -> a.shanten_after = min_sh) analyses in

  (* 受入枚数でソート *)
  let sorted = List.sort (fun a b ->
    let cmp = compare b.acceptance a.acceptance in
    if cmp <> 0 then cmp
    else compare b.estimated_han a.estimated_han
  ) best_sh in

  let direction = detect_direction hand_tiles bakaze jikaze dora_tiles in
  let is_menzen = furo_count = 0 in
  let action = recommend_action current_shanten is_menzen has_riichi_opponent in

  {
    current_shanten;
    is_tenpai;
    best_discards = sorted;
    hand_direction = direction;
    recommended_action = action;
  }
