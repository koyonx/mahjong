(** CPU思考ロジック — 難易度別 *)

type difficulty = Easy | Normal | Hard

(** === 共通ユーティリティ === *)

let count_tile tile tiles =
  List.length (List.filter (fun t -> Tile.compare t tile = 0) tiles)

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

let edge_penalty = function
  | Tile.Suhai (_, n) ->
    if n = 1 || n = 9 then 3
    else if n = 2 || n = 8 then 1
    else 0
  | Tile.Jihai _ -> 2

let unique_tiles tiles =
  let rec aux seen = function
    | [] -> List.rev seen
    | t :: rest ->
      if List.exists (fun s -> Tile.compare s t = 0) seen then aux seen rest
      else aux (t :: seen) rest
  in
  aux [] tiles

(** === Easy AI: ほぼランダム、基本的な牌だけ保持 === *)

let choose_discard_easy (hand_tiles : Tile.tile list) : Tile.tile =
  let candidates = unique_tiles hand_tiles in
  (* 対子・刻子はなるべく残す、それ以外はランダム *)
  let singles = List.filter (fun t -> count_tile t hand_tiles = 1) candidates in
  let pool = if singles = [] then candidates else singles in
  let idx = Random.int (List.length pool) in
  List.nth pool idx

(** === Normal AI: 牌効率ベース（現行ロジック） === *)

let evaluate_tile_normal tile hand_tiles =
  let count = count_tile tile hand_tiles in
  let isolated = is_isolated tile hand_tiles in
  let edge = edge_penalty tile in
  let pair_bonus = match count with
    | 1 -> 0 | 2 -> 30 | 3 -> 50 | _ -> 60
  in
  let sequence_bonus = match tile with
    | Tile.Suhai (suit, n) ->
      let has num =
        num >= 1 && num <= 9 &&
        List.exists (fun t -> Tile.compare t (Tile.Suhai (suit, num)) = 0) hand_tiles
      in
      let bonus = ref 0 in
      if has (n - 1) && has (n + 1) then bonus := !bonus + 40;
      if has (n - 1) then bonus := !bonus + 15;
      if has (n + 1) then bonus := !bonus + 15;
      if has (n - 2) then bonus := !bonus + 8;
      if has (n + 2) then bonus := !bonus + 8;
      if has (n - 1) && has (n - 2) then bonus := !bonus + 20;
      if has (n + 1) && has (n + 2) then bonus := !bonus + 20;
      !bonus
    | Tile.Jihai _ -> 0
  in
  let isolation_penalty = if isolated then -20 else 0 in
  pair_bonus + sequence_bonus + isolation_penalty - edge

let choose_discard_normal (hand_tiles : Tile.tile list) : Tile.tile =
  let candidates = unique_tiles hand_tiles in
  match candidates with
  | [] -> List.hd hand_tiles
  | _ ->
    let scored = List.map (fun t -> (t, evaluate_tile_normal t hand_tiles)) candidates in
    let sorted = List.sort (fun (_, s1) (_, s2) -> compare s1 s2) scored in
    fst (List.hd sorted)

(** === Hard AI: 向聴数意識 + 防御 + テンパイ維持 === *)

(** 1枚捨てた後のテンパイ受入数を計算 *)
let count_acceptance (remaining : Tile.tile list) : int =
  let suits = [Tile.Manzu; Tile.Pinzu; Tile.Souzu] in
  let numbers = [1; 2; 3; 4; 5; 6; 7; 8; 9] in
  let jihais = [Tile.Ton; Tile.Nan; Tile.Sha; Tile.Pei; Tile.Haku; Tile.Hatsu; Tile.Chun] in
  let candidates =
    List.concat_map (fun s -> List.map (fun n -> Tile.Suhai (s, n)) numbers) suits @
    List.map (fun j -> Tile.Jihai j) jihais
  in
  List.length (List.filter (fun t ->
    let test_hand = List.sort Tile.compare (t :: remaining) in
    Mentsu.is_agari test_hand
  ) candidates)

(** 安全牌判定: 他家の河に出ている牌は安全 *)
let is_safe_tile tile (other_kawas : Tile.tile list list) =
  List.exists (fun kawa ->
    List.exists (fun t -> Tile.compare t tile = 0) kawa
  ) other_kawas

(** Hard AI の牌評価 *)
let evaluate_tile_hard tile hand_tiles (other_kawas : Tile.tile list list) (riichi_players : bool list) =
  let base = evaluate_tile_normal tile hand_tiles in

  (* テンパイに近い牌を高く評価: 捨てた後の受入数 *)
  let acceptance_bonus = match Mentsu.remove_one tile hand_tiles with
    | Some rest ->
      let acc = count_acceptance rest in
      acc * 15  (* 受入1枚 = 15点のボーナス *)
    | None -> 0
  in

  (* 防御: リーチ者がいる時は安全牌を優先 *)
  let defense_bonus =
    if List.exists (fun r -> r) riichi_players then
      if is_safe_tile tile other_kawas then -30  (* 安全牌は捨てやすい（スコアを下げる） *)
      else
        (* 危険牌: 中張牌は危険、端牌/字牌は比較的安全 *)
        match tile with
        | Tile.Suhai (_, n) when n >= 3 && n <= 7 -> 25  (* 中張牌は保持 *)
        | Tile.Jihai _ -> -10  (* 字牌は比較的安全 *)
        | _ -> 0
    else 0
  in

  base + acceptance_bonus + defense_bonus

let choose_discard_hard (hand_tiles : Tile.tile list) (other_kawas : Tile.tile list list) (riichi_players : bool list) : Tile.tile =
  let candidates = unique_tiles hand_tiles in
  match candidates with
  | [] -> List.hd hand_tiles
  | _ ->
    let scored = List.map (fun t ->
      (t, evaluate_tile_hard t hand_tiles other_kawas riichi_players)
    ) candidates in
    let sorted = List.sort (fun (_, s1) (_, s2) -> compare s1 s2) scored in
    fst (List.hd sorted)

(** === 難易度に応じた捨て牌選択 === *)

let choose_discard ?(difficulty=Normal) ?(other_kawas=[]) ?(riichi_players=[]) (hand_tiles : Tile.tile list) : Tile.tile =
  match difficulty with
  | Easy -> choose_discard_easy hand_tiles
  | Normal -> choose_discard_normal hand_tiles
  | Hard -> choose_discard_hard hand_tiles other_kawas riichi_players

(** リーチ判定 *)
let should_riichi ?(difficulty=Normal) (player : Player.t) : bool =
  if player.is_riichi then false
  else if not (Player.is_menzen player) then false
  else if player.score < 1000 then false
  else
    let hand_13 = match player.hand.tsumo with
      | Some tsumo_tile ->
        (match Mentsu.remove_one tsumo_tile player.hand.tiles with
         | Some rest -> rest
         | None -> player.hand.tiles)
      | None -> player.hand.tiles
    in
    if List.length hand_13 <> 13 then false
    else
      let tenpai = Hand.tenpai_tiles (Hand.make hand_13) <> [] in
      match difficulty with
      | Easy -> tenpai && Random.int 3 = 0  (* 1/3の確率でリーチ *)
      | Normal -> tenpai
      | Hard -> tenpai  (* Hardも常にリーチ（将来的にダマテン戦略追加可能） *)

(** CPUの行動を決定 *)
type action =
  | Discard of Tile.tile
  | DeclareRiichi of Tile.tile
  | TsumoAgari

let decide ?(difficulty=Normal) ?(other_kawas=[]) ?(riichi_players=[]) (player : Player.t) (bakaze : Tile.jihai) : action =
  let ctx = {
    Yaku.is_tsumo = true;
    is_riichi = player.is_riichi;
    is_double_riichi = player.is_double_riichi;
    is_ippatsu = player.is_ippatsu;
    is_tenhou = false;
    is_chiihou = false;
    is_menzen = Player.is_menzen player;
    is_haitei = false;
    is_houtei = false;
    dora_count = 0;
    agari_tile = None;
    bakaze;
    jikaze = player.jikaze;
  } in
  let is_oya = player.jikaze = Tile.Ton in
  let furo_count = List.length player.furo_list in
  let furo_mentsu = player.furo_list in
  match Scoring.score_hand ~furo_count ~furo_mentsu player.hand.tiles ctx is_oya with
  | Some _ -> TsumoAgari
  | None ->
    let tile = choose_discard ~difficulty ~other_kawas ~riichi_players player.hand.tiles in
    if should_riichi ~difficulty player then
      DeclareRiichi tile
    else
      Discard tile
