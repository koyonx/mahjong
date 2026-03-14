(** CPU思考ロジック *)

(** 牌の有効度（向聴数を下げる可能性）を評価する *)

(** 孤立牌かどうか判定（周囲に関連する牌がない） *)
let is_isolated tile hand_tiles =
  let related = match tile with
    | Tile.Suhai (suit, n) ->
      let check_exists s num =
        num >= 1 && num <= 9 &&
        List.exists (fun t -> Tile.compare t (Tile.Suhai (s, num)) = 0) hand_tiles
      in
      check_exists suit (n - 2) || check_exists suit (n - 1) ||
      check_exists suit (n + 1) || check_exists suit (n + 2)
    | Tile.Jihai _ ->
      List.exists (fun t -> Tile.compare t tile = 0 && t != tile) hand_tiles
  in
  not related

(** 牌の枚数をカウント *)
let count_tile tile tiles =
  List.length (List.filter (fun t -> Tile.compare t tile = 0) tiles)

(** 数牌の端度（1,9に近いほど高い） *)
let edge_penalty = function
  | Tile.Suhai (_, n) ->
    if n = 1 || n = 9 then 3
    else if n = 2 || n = 8 then 1
    else 0
  | Tile.Jihai _ -> 2

(** 牌の価値を評価（低いほど捨てやすい） *)
let evaluate_tile tile hand_tiles =
  let count = count_tile tile hand_tiles in
  let isolated = is_isolated tile hand_tiles in
  let edge = edge_penalty tile in

  (* 基本スコア: 対子・刻子は価値が高い *)
  let pair_bonus = match count with
    | 1 -> 0
    | 2 -> 30   (* 対子 *)
    | 3 -> 50   (* 刻子 *)
    | _ -> 60   (* 槓子候補 *)
  in

  (* 連続性: 順子に使える数牌は価値が高い *)
  let sequence_bonus = match tile with
    | Tile.Suhai (suit, n) ->
      let has num =
        num >= 1 && num <= 9 &&
        List.exists (fun t -> Tile.compare t (Tile.Suhai (suit, num)) = 0) hand_tiles
      in
      let bonus = ref 0 in
      (* 両面搭子 *)
      if has (n - 1) && has (n + 1) then bonus := !bonus + 40;
      (* 連続搭子 *)
      if has (n - 1) then bonus := !bonus + 15;
      if has (n + 1) then bonus := !bonus + 15;
      (* 嵌張搭子 *)
      if has (n - 2) then bonus := !bonus + 8;
      if has (n + 2) then bonus := !bonus + 8;
      (* 3連続 *)
      if has (n - 1) && has (n - 2) then bonus := !bonus + 20;
      if has (n + 1) && has (n + 2) then bonus := !bonus + 20;
      !bonus
    | Tile.Jihai _ -> 0
  in

  (* 孤立牌ペナルティ *)
  let isolation_penalty = if isolated then -20 else 0 in

  pair_bonus + sequence_bonus + isolation_penalty - edge

(** 捨て牌を選択する（最も価値の低い牌を捨てる） *)
let choose_discard (hand_tiles : Tile.tile list) : Tile.tile =
  (* 各牌のユニークリスト *)
  let unique_tiles =
    let rec aux seen = function
      | [] -> List.rev seen
      | t :: rest ->
        if List.exists (fun s -> Tile.compare s t = 0) seen then aux seen rest
        else aux (t :: seen) rest
    in
    aux [] hand_tiles
  in

  match unique_tiles with
  | [] -> List.hd hand_tiles  (* あり得ないが安全のため *)
  | _ ->
    let scored = List.map (fun t -> (t, evaluate_tile t hand_tiles)) unique_tiles in
    let sorted = List.sort (fun (_, s1) (_, s2) -> compare s1 s2) scored in
    fst (List.hd sorted)

(** リーチ判定: テンパイ + 門前 + 持ち点1000以上 *)
let should_riichi (player : Player.t) : bool =
  if player.is_riichi then false
  else if not (Player.is_menzen player) then false
  else if player.score < 1000 then false
  else
    (* 13枚でテンパイしているか確認 *)
    let hand_13 = match player.hand.tsumo with
      | Some tsumo_tile ->
        (match Mentsu.remove_one tsumo_tile player.hand.tiles with
         | Some rest -> rest
         | None -> player.hand.tiles)
      | None -> player.hand.tiles
    in
    if List.length hand_13 = 13 then
      Hand.tenpai_tiles (Hand.make hand_13) <> []
    else
      false

(** CPUの行動を決定 *)
type action =
  | Discard of Tile.tile
  | DeclareRiichi of Tile.tile  (** リーチ宣言 + 捨て牌 *)
  | TsumoAgari                  (** ツモ和了 *)

let decide (player : Player.t) (bakaze : Tile.jihai) : action =
  (* ツモ和了チェック *)
  let ctx = {
    Yaku.is_tsumo = true;
    is_riichi = player.is_riichi;
    is_ippatsu = player.is_ippatsu;
    is_tenhou = false;
    is_chiihou = false;
    bakaze;
    jikaze = player.jikaze;
  } in
  let is_oya = player.jikaze = Tile.Ton in
  match Scoring.score_hand player.hand.tiles ctx is_oya with
  | Some _ -> TsumoAgari
  | None ->
    let tile = choose_discard player.hand.tiles in
    (* リーチ判定 *)
    if should_riichi player then
      DeclareRiichi tile
    else
      Discard tile
