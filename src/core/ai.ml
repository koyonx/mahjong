(** CPU思考ロジック — レベル1〜10 *)

(** レベル: 1（最弱）〜 10（最強） *)
type difficulty = Easy | Normal | Hard  (* 互換性のため残す *)

let level_of_difficulty = function
  | Easy -> 2 | Normal -> 5 | Hard -> 8

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

(** === 受入枚数計算 === *)

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

let is_safe_tile tile (other_kawas : Tile.tile list list) =
  List.exists (fun kawa ->
    List.exists (fun t -> Tile.compare t tile = 0) kawa
  ) other_kawas

(** スジ安全判定: 4-1, 5-2, 6-3 等のスジ牌は比較的安全 *)
let is_suji_safe tile (other_kawas : Tile.tile list list) =
  match tile with
  | Tile.Suhai (suit, n) ->
    let check_in_kawa num =
      List.exists (fun kawa ->
        List.exists (fun t -> Tile.compare t (Tile.Suhai (suit, num)) = 0) kawa
      ) other_kawas
    in
    (* スジ: 1-4, 2-5, 3-6, 4-7, 5-8, 6-9 *)
    (n >= 4 && check_in_kawa (n - 3)) ||
    (n <= 6 && check_in_kawa (n + 3))
  | _ -> false

(** 壁判定: 場に3枚見えている牌の外側は安全 *)
let is_kabe_safe tile (visible_tiles : Tile.tile list) =
  match tile with
  | Tile.Suhai (suit, n) ->
    let count_visible num =
      List.length (List.filter (fun t ->
        Tile.compare t (Tile.Suhai (suit, num)) = 0
      ) visible_tiles)
    in
    (* 隣の牌が3-4枚見えていれば壁 *)
    (n > 1 && count_visible (n - 1) >= 3) ||
    (n < 9 && count_visible (n + 1) >= 3)
  | _ -> false

(** === 正確な向聴数計算 === *)

(* 牌をカウント配列(34要素)に変換: 0-8=萬, 9-17=筒, 18-26=索, 27-33=字 *)
let tile_to_index = function
  | Tile.Suhai (Tile.Manzu, n) -> n - 1
  | Tile.Suhai (Tile.Pinzu, n) -> n + 8
  | Tile.Suhai (Tile.Souzu, n) -> n + 17
  | Tile.Jihai Tile.Ton -> 27 | Tile.Jihai Tile.Nan -> 28
  | Tile.Jihai Tile.Sha -> 29 | Tile.Jihai Tile.Pei -> 30
  | Tile.Jihai Tile.Haku -> 31 | Tile.Jihai Tile.Hatsu -> 32
  | Tile.Jihai Tile.Chun -> 33

let counts_of_tiles tiles =
  let c = Array.make 34 0 in
  List.iter (fun t -> let i = tile_to_index t in c.(i) <- c.(i) + 1) tiles;
  c

(* スート内の面子/搭子分解（再帰探索） *)
let scan_suit (c : int array) (offset : int) : int * int =
  let best_mentsu = ref 0 in
  let best_block = ref 0 in
  let rec scan pos mentsu block =
    if pos > offset + 8 then begin
      if mentsu > !best_mentsu || (mentsu = !best_mentsu && block > !best_block) then begin
        best_mentsu := mentsu;
        best_block := block
      end
    end else begin
      let cnt = c.(pos) in
      if cnt = 0 then scan (pos + 1) mentsu block
      else begin
        (* 刻子を抽出 *)
        if cnt >= 3 then begin
          c.(pos) <- c.(pos) - 3;
          scan pos (mentsu + 1) block;
          c.(pos) <- c.(pos) + 3
        end;
        (* 順子を抽出 *)
        if pos <= offset + 6 && c.(pos) >= 1 && c.(pos+1) >= 1 && c.(pos+2) >= 1 then begin
          c.(pos) <- c.(pos) - 1; c.(pos+1) <- c.(pos+1) - 1; c.(pos+2) <- c.(pos+2) - 1;
          scan pos (mentsu + 1) block;
          c.(pos) <- c.(pos) + 1; c.(pos+1) <- c.(pos+1) + 1; c.(pos+2) <- c.(pos+2) + 1
        end;
        (* 搭子（対子） *)
        if cnt >= 2 then begin
          c.(pos) <- c.(pos) - 2;
          scan (pos + 1) mentsu (block + 1);
          c.(pos) <- c.(pos) + 2
        end;
        (* 搭子（両面/嵌張） *)
        if pos <= offset + 7 && c.(pos) >= 1 && c.(pos+1) >= 1 then begin
          c.(pos) <- c.(pos) - 1; c.(pos+1) <- c.(pos+1) - 1;
          scan (pos + 1) mentsu (block + 1);
          c.(pos) <- c.(pos) + 1; c.(pos+1) <- c.(pos+1) + 1
        end;
        if pos <= offset + 6 && c.(pos) >= 1 && c.(pos+2) >= 1 then begin
          c.(pos) <- c.(pos) - 1; c.(pos+2) <- c.(pos+2) - 1;
          scan (pos + 1) mentsu (block + 1);
          c.(pos) <- c.(pos) + 1; c.(pos+2) <- c.(pos+2) + 1
        end;
        (* 何も取らずにスキップ *)
        scan (pos + 1) mentsu block
      end
    end
  in
  scan offset 0 0;
  (!best_mentsu, !best_block)

(* 通常形の向聴数 *)
let calc_shanten_regular (tiles : Tile.tile list) (furo_count : int) : int =
  let c = counts_of_tiles tiles in
  let needed = 4 - furo_count in
  let best = ref 100 in
  (* 雀頭候補を列挙 *)
  for jantai = 0 to 33 do
    let has_jantai = c.(jantai) >= 2 in
    if has_jantai then c.(jantai) <- c.(jantai) - 2;
    (* 各スートの面子/搭子を数える *)
    let total_mentsu = ref 0 in
    let total_block = ref 0 in
    (* 萬子 *)
    let (m, b) = scan_suit c 0 in total_mentsu := !total_mentsu + m; total_block := !total_block + b;
    (* 筒子 *)
    let (m, b) = scan_suit c 9 in total_mentsu := !total_mentsu + m; total_block := !total_block + b;
    (* 索子 *)
    let (m, b) = scan_suit c 18 in total_mentsu := !total_mentsu + m; total_block := !total_block + b;
    (* 字牌 *)
    for i = 27 to 33 do
      if c.(i) >= 3 then (incr total_mentsu; c.(i) <- c.(i) - 3);
      if c.(i) >= 2 then (incr total_block; c.(i) <- c.(i) - 2)
    done;
    (* 字牌を元に戻す *)
    let c2 = counts_of_tiles tiles in
    if has_jantai then c2.(jantai) <- c2.(jantai) - 2;
    for i = 27 to 33 do c.(i) <- c2.(i) done;
    (* 面子+搭子がneededを超えないようにクランプ *)
    let mentsu = min !total_mentsu needed in
    let block = min !total_block (needed - mentsu) in
    let jantai_bonus = if has_jantai then 1 else 0 in
    let sh = (needed - mentsu) * 2 - block - jantai_bonus in
    if sh < !best then best := sh;
    if has_jantai then c.(jantai) <- c.(jantai) + 2
  done;
  (* 雀頭なし *)
  let total_mentsu = ref 0 in
  let total_block = ref 0 in
  let (m, b) = scan_suit c 0 in total_mentsu := m; total_block := b;
  let (m, b) = scan_suit c 9 in total_mentsu := !total_mentsu + m; total_block := !total_block + b;
  let (m, b) = scan_suit c 18 in total_mentsu := !total_mentsu + m; total_block := !total_block + b;
  for i = 27 to 33 do
    if c.(i) >= 3 then incr total_mentsu
    else if c.(i) >= 2 then incr total_block
  done;
  let mentsu = min !total_mentsu needed in
  let block = min !total_block (needed - mentsu) in
  let sh = (needed - mentsu) * 2 - block in
  if sh < !best then best := sh;
  !best

(* 七対子の向聴数 *)
let calc_shanten_chiitoitsu (tiles : Tile.tile list) : int =
  let c = counts_of_tiles tiles in
  let pairs = Array.fold_left (fun acc cnt -> if cnt >= 2 then acc + 1 else acc) 0 c in
  6 - pairs

(* 国士無双の向聴数 *)
let calc_shanten_kokushi (tiles : Tile.tile list) : int =
  let c = counts_of_tiles tiles in
  let yaochu = [0;8;9;17;18;26;27;28;29;30;31;32;33] in
  let types = List.length (List.filter (fun i -> c.(i) >= 1) yaochu) in
  let has_pair = List.exists (fun i -> c.(i) >= 2) yaochu in
  13 - types - (if has_pair then 1 else 0)

(* 統合向聴数（3形式の最小値） *)
let estimate_shanten (tiles : Tile.tile list) (furo_count : int) : int =
  let regular = calc_shanten_regular tiles furo_count in
  if furo_count > 0 then regular
  else
    let chiitoi = calc_shanten_chiitoitsu tiles in
    let kokushi = calc_shanten_kokushi tiles in
    min regular (min chiitoi kokushi)

(** === Lv9-10: 受入枚数ベース打牌 === *)

(* 見えていない牌の枚数 *)
let unseen_count (tile_idx : int) (visible : Tile.tile list) =
  let visible_c = counts_of_tiles visible in
  max 0 (4 - visible_c.(tile_idx))

(* 受入枚数を正確に計算: 各捨て牌候補に対して *)
let calc_acceptance (hand_13 : Tile.tile list) (furo_count : int) (visible : Tile.tile list) : int =
  let current_sh = estimate_shanten hand_13 furo_count in
  if current_sh < 0 then 0  (* 既に和了 *)
  else
    let total = ref 0 in
    for idx = 0 to 33 do
      let unseen = unseen_count idx visible in
      if unseen > 0 then begin
        (* この牌を加えて向聴数が下がるか *)
        let test_tile = match idx with
          | n when n < 9 -> Tile.Suhai (Tile.Manzu, n + 1)
          | n when n < 18 -> Tile.Suhai (Tile.Pinzu, n - 8)
          | n when n < 27 -> Tile.Suhai (Tile.Souzu, n - 17)
          | 27 -> Tile.Jihai Tile.Ton | 28 -> Tile.Jihai Tile.Nan
          | 29 -> Tile.Jihai Tile.Sha | 30 -> Tile.Jihai Tile.Pei
          | 31 -> Tile.Jihai Tile.Haku | 32 -> Tile.Jihai Tile.Hatsu
          | _ -> Tile.Jihai Tile.Chun
        in
        let new_hand = test_tile :: hand_13 in
        let new_sh = estimate_shanten new_hand furo_count in
        if new_sh < current_sh then
          total := !total + unseen
      end
    done;
    !total

(** 完全ベタオリ: 安全度でランキング *)
let betaori_score (tile : Tile.tile) (other_kawas : Tile.tile list list) (visible : Tile.tile list) (riichi_kawas : Tile.tile list list) : int =
  (* 低いほど安全 *)
  if is_safe_tile tile other_kawas then 0  (* 現物: 完全安全 *)
  else if is_safe_tile tile riichi_kawas then 5  (* リーチ者の現物 *)
  else if is_suji_safe tile riichi_kawas then 15  (* スジ *)
  else if is_kabe_safe tile visible then 20  (* 壁 *)
  else match tile with
  | Tile.Jihai _ -> 25  (* 字牌は比較的安全 *)
  | Tile.Suhai (_, n) when n = 1 || n = 9 -> 35  (* 端牌 *)
  | Tile.Suhai (_, n) when n = 2 || n = 8 -> 50  (* 準端牌 *)
  | _ -> 70  (* 中張牌: 最も危険 *)

(** === レベル別打牌評価 === *)

(** レベル対応の牌評価 *)
let evaluate_tile_leveled ~(level:int) tile hand_tiles
    (other_kawas : Tile.tile list list) (riichi_players : bool list)
    (visible_tiles : Tile.tile list) =

  (* 基本: 対子/刻子ボーナス *)
  let count = count_tile tile hand_tiles in
  let pair_bonus = match count with
    | 1 -> 0 | 2 -> 30 | 3 -> 50 | _ -> 60
  in

  (* 連続性ボーナス（Lv3+） *)
  let sequence_bonus =
    if level < 3 then 0
    else match tile with
    | Tile.Suhai (suit, n) ->
      let has num =
        num >= 1 && num <= 9 &&
        List.exists (fun t -> Tile.compare t (Tile.Suhai (suit, num)) = 0) hand_tiles
      in
      let b = ref 0 in
      if has (n - 1) && has (n + 1) then b := !b + 40;
      if has (n - 1) then b := !b + 15;
      if has (n + 1) then b := !b + 15;
      if has (n - 2) then b := !b + 8;
      if has (n + 2) then b := !b + 8;
      if has (n - 1) && has (n - 2) then b := !b + 20;
      if has (n + 1) && has (n + 2) then b := !b + 20;
      !b
    | Tile.Jihai _ -> 0
  in

  (* 孤立牌ペナルティ（Lv2+） *)
  let isolation = if level >= 2 && is_isolated tile hand_tiles then -20 else 0 in

  (* 端牌ペナルティ（Lv3+） *)
  let edge = if level >= 3 then edge_penalty tile else 0 in

  (* 受入枚数ボーナス（Lv5+） *)
  let acceptance =
    if level < 5 then 0
    else match Mentsu.remove_one tile hand_tiles with
    | Some rest ->
      if level >= 9 then
        (* Lv9+: 正確な受入枚数計算 *)
        let acc = calc_acceptance rest 0 visible_tiles in
        acc * 25
      else
        let acc = count_acceptance rest in
        acc * (5 + level * 2)
    | None -> 0
  in

  (* 防御（Lv5+） *)
  let defense =
    if level < 5 then 0
    else if not (List.exists (fun r -> r) riichi_players) then 0
    else
      let safe_bonus =
        if is_safe_tile tile other_kawas then -(10 + level * 3)
        else if level >= 8 && is_suji_safe tile other_kawas then -(5 + level)
        else if level >= 9 && is_kabe_safe tile visible_tiles then -(3 + level)
        else 0
      in
      let danger =
        if is_safe_tile tile other_kawas then 0
        else match tile with
        | Tile.Suhai (_, n) when n >= 3 && n <= 7 -> 10 + level * 2
        | Tile.Suhai (_, n) when n = 2 || n = 8 -> 5 + level
        | _ -> 0
      in
      safe_bonus + danger
  in

  pair_bonus + sequence_bonus + isolation - edge + acceptance + defense

(** 攻防モード判定（Lv7+） *)
type strategy = Attack | Balanced | Defense | Full_betaori

let choose_strategy ~(level:int) (hand_tiles : Tile.tile list) (furo_count : int)
    (riichi_players : bool list) (remaining : int) : strategy =
  if level < 7 then Attack
  else
    let sh = estimate_shanten hand_tiles furo_count in
    let riichi_count = List.length (List.filter (fun r -> r) riichi_players) in
    if riichi_count = 0 then Attack
    else if sh = 0 then Balanced  (* テンパイ vs リーチ: 押し *)
    else if sh = 1 && level >= 8 then Balanced  (* 1向聴: バランス *)
    else if sh >= 3 then Full_betaori  (* 3向聴以上: 完全ベタオリ *)
    else if sh = 2 && riichi_count >= 2 then Full_betaori  (* 複数リーチ *)
    else if sh = 2 && remaining < 20 then Full_betaori  (* 終盤 *)
    else Defense  (* 2向聴: 慎重 *)

(** レベル別打牌選択 *)
let choose_discard_leveled ~(level:int) (hand_tiles : Tile.tile list)
    (other_kawas : Tile.tile list list) (riichi_players : bool list)
    (visible_tiles : Tile.tile list) : Tile.tile =
  let candidates = unique_tiles hand_tiles in
  match candidates with
  | [] -> List.hd hand_tiles
  | _ ->
    (* Lv1-2: 一定確率でランダム打牌（ミス） *)
    let mistake_rate = max 0 (30 - level * 3) in
    if mistake_rate > 0 && Random.int 100 < mistake_rate then begin
      let singles = List.filter (fun t -> count_tile t hand_tiles = 1) candidates in
      let pool = if singles = [] then candidates else singles in
      List.nth pool (Random.int (List.length pool))
    end else if level >= 9 then begin
      (* Lv9-10: 攻防モードに基づく打牌 *)
      let furo_count = 0 in  (* TODO: 副露数を外から渡す *)
      let remaining = 70 in  (* TODO *)
      let riichi_kawas = List.filter_map (fun (r, k) -> if r then Some k else None)
        (List.combine riichi_players other_kawas) in
      let strategy = choose_strategy ~level hand_tiles furo_count riichi_players remaining in
      match strategy with
      | Full_betaori ->
        (* 完全ベタオリ: 安全度のみで選択 *)
        let scored = List.map (fun t ->
          (t, betaori_score t other_kawas visible_tiles riichi_kawas)
        ) candidates in
        let sorted = List.sort (fun (_, s1) (_, s2) -> compare s1 s2) sorted in
        fst (List.hd sorted)
      | _ ->
        (* 攻撃/バランス: 受入枚数 + 防御バランス *)
        let scored = List.map (fun t ->
          let base = evaluate_tile_leveled ~level t hand_tiles other_kawas riichi_players visible_tiles in
          let danger = match strategy with
            | Defense -> betaori_score t other_kawas visible_tiles riichi_kawas * 2
            | Balanced -> betaori_score t other_kawas visible_tiles riichi_kawas
            | _ -> 0
          in
          (t, base - danger)
        ) candidates in
        let sorted = List.sort (fun (_, s1) (_, s2) -> compare s1 s2) sorted in
        fst (List.hd sorted)
    end else begin
      let scored = List.map (fun t ->
        (t, evaluate_tile_leveled ~level t hand_tiles other_kawas riichi_players visible_tiles)
      ) candidates in
      let sorted = List.sort (fun (_, s1) (_, s2) -> compare s1 s2) sorted in
      fst (List.hd sorted)
    end

(** 互換性のためのラッパー *)
let choose_discard ?(difficulty=Normal) ?(other_kawas=[]) ?(riichi_players=[]) (hand_tiles : Tile.tile list) : Tile.tile =
  let level = level_of_difficulty difficulty in
  choose_discard_leveled ~level hand_tiles other_kawas riichi_players []

(** === 鳴き判断 === *)

let should_pon_leveled ~(level:int) (player : Player.t) (tile : Tile.tile) (bakaze : Tile.jihai) : bool =
  if level < 6 then false  (* Lv5以下は鳴かない *)
  else
    let count = count_tile tile player.hand.tiles in
    if count < 2 then false
    else
      let furo_count = List.length player.furo_list in
      let current_shanten = estimate_shanten player.hand.tiles furo_count in
      match Mentsu.remove_one tile player.hand.tiles with
      | None -> false
      | Some rest1 ->
        match Mentsu.remove_one tile rest1 with
        | None -> false
        | Some rest2 ->
          let new_shanten = estimate_shanten rest2 (furo_count + 1) in
          if new_shanten < current_shanten then true
          else if new_shanten = current_shanten && level >= 6 then
            match tile with
            | Tile.Jihai j ->
              j = Tile.Haku || j = Tile.Hatsu || j = Tile.Chun ||
              j = bakaze || j = player.jikaze
            | _ -> false
          else false

let should_chi_leveled ~(level:int) (player : Player.t) (t1 : Tile.tile) (t2 : Tile.tile) : bool =
  if level < 7 then false  (* Lv6以下はチーしない *)
  else
    let furo_count = List.length player.furo_list in
    let current_shanten = estimate_shanten player.hand.tiles furo_count in
    match Mentsu.remove_one t1 player.hand.tiles with
    | None -> false
    | Some rest1 ->
      match Mentsu.remove_one t2 rest1 with
      | None -> false
      | Some rest2 ->
        let new_shanten = estimate_shanten rest2 (furo_count + 1) in
        let threshold = if level >= 9 then 3 else 2 in
        new_shanten < current_shanten && current_shanten <= threshold

(* 互換性 *)
let should_pon (player : Player.t) (tile : Tile.tile) (bakaze : Tile.jihai) : bool =
  should_pon_leveled ~level:8 player tile bakaze

let should_chi (player : Player.t) (t1 : Tile.tile) (t2 : Tile.tile) : bool =
  should_chi_leveled ~level:8 player t1 t2

(** === リーチ戦略 === *)

let should_riichi_leveled ~(level:int) (player : Player.t) (bakaze : Tile.jihai) (remaining_tiles : int) : bool =
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
      let waits = Hand.tenpai_tiles (Hand.make hand_13) in
      if waits = [] then false
      else
        (* Lv1-2: リーチしない/稀 *)
        if level <= 2 then Random.int 4 = 0
        (* Lv3-6: 常にリーチ *)
        else if level <= 6 then true
        (* Lv7+: 戦略的リーチ/ダマテン *)
        else
          let wait_count = List.length waits in
          let ctx = {
            Yaku.is_tsumo = true; is_riichi = false; is_double_riichi = false;
            is_ippatsu = false; is_tenhou = false; is_chiihou = false;
            is_menzen = true; is_haitei = false; is_houtei = false;
            dora_count = 0; agari_tile = None; bakaze; jikaze = player.jikaze;
          } in
          let is_oya = player.jikaze = Tile.Ton in
          let has_high_yaku = List.exists (fun w ->
            let test = List.sort Tile.compare (w :: hand_13) in
            match Scoring.score_hand test ctx is_oya with
            | Some result -> result.han_detail >= (if level >= 9 then 2 else 3)
            | None -> false
          ) waits in
          if has_high_yaku && wait_count >= 2 then
            (* ダマテン条件: Lv7+で高い手+広い待ち *)
            if level >= 9 && remaining_tiles > 30 then false  (* Lv9+: 序盤のダマテン *)
            else if level >= 8 then false
            else true
          else if remaining_tiles < (if level >= 9 then 25 else 20) then
            true  (* 終盤: リーチ *)
          else true

(* 互換性 *)
let should_riichi ?(difficulty=Normal) ?(bakaze=Tile.Ton) ?(remaining_tiles=70) (player : Player.t) : bool =
  should_riichi_leveled ~level:(level_of_difficulty difficulty) player bakaze remaining_tiles

(** === メイン判定 === *)

type action =
  | Discard of Tile.tile
  | DeclareRiichi of Tile.tile
  | TsumoAgari

let decide_leveled ~(level:int) ?(other_kawas=[]) ?(riichi_players=[]) ?(remaining_tiles=70) ?(visible_tiles=[]) (player : Player.t) (bakaze : Tile.jihai) : action =
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
    let tile = choose_discard_leveled ~level player.hand.tiles other_kawas riichi_players visible_tiles in
    if should_riichi_leveled ~level player bakaze remaining_tiles then
      DeclareRiichi tile
    else
      Discard tile

(* 互換性 *)
let decide ?(difficulty=Normal) ?(other_kawas=[]) ?(riichi_players=[]) ?(remaining_tiles=70) (player : Player.t) (bakaze : Tile.jihai) : action =
  decide_leveled ~level:(level_of_difficulty difficulty) ~other_kawas ~riichi_players ~remaining_tiles player bakaze
