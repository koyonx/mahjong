(** 役の定義 *)
type yaku =
  | Riichi             (** リーチ *)
  | Ippatsu            (** 一発 *)
  | Tsumo              (** 門前清自摸和 *)
  | Tanyao             (** 断么九 *)
  | Pinfu              (** 平和 *)
  | Iipeiko            (** 一盃口 *)
  | Yakuhai of Tile.jihai  (** 役牌 *)
  | Chanta             (** 混全帯么九 *)
  | Ittsu              (** 一気通貫 *)
  | Sanshoku_doujun    (** 三色同順 *)
  | Sanshoku_doukou    (** 三色同刻 *)
  | Toitoi             (** 対々和 *)
  | Sanankou           (** 三暗刻 *)
  | Honroutou          (** 混老頭 *)
  | Shousangen         (** 小三元 *)
  | Chiitoitsu         (** 七対子 *)
  | Honitsu            (** 混一色 *)
  | Junchan            (** 純全帯么九 *)
  | Ryanpeiko          (** 二盃口 *)
  | Chinitsu           (** 清一色 *)
  (* 役満 *)
  | Kokushi            (** 国士無双 *)
  | Suuankou           (** 四暗刻 *)
  | Daisangen          (** 大三元 *)
  | Shousuushii        (** 小四喜 *)
  | Daisuushii         (** 大四喜 *)
  | Tsuuiisou          (** 字一色 *)
  | Ryuuiisou          (** 緑一色 *)
  | Chinroutou         (** 清老頭 *)
  | Chuuren            (** 九蓮宝燈 *)
  | Tenhou             (** 天和 *)
  | Chiihou            (** 地和 *)

(** 役の翻数 *)
let han_of_yaku = function
  | Riichi -> 1
  | Ippatsu -> 1
  | Tsumo -> 1
  | Tanyao -> 1
  | Pinfu -> 1
  | Iipeiko -> 1
  | Yakuhai _ -> 1
  | Chanta -> 2
  | Ittsu -> 2
  | Sanshoku_doujun -> 2
  | Sanshoku_doukou -> 2
  | Toitoi -> 2
  | Sanankou -> 2
  | Honroutou -> 2
  | Shousangen -> 2
  | Chiitoitsu -> 2
  | Honitsu -> 3
  | Junchan -> 3
  | Ryanpeiko -> 3
  | Chinitsu -> 6
  | Kokushi | Suuankou | Daisangen | Shousuushii | Daisuushii
  | Tsuuiisou | Ryuuiisou | Chinroutou | Chuuren
  | Tenhou | Chiihou -> 13

(** 役の名前 *)
let name_of_yaku = function
  | Riichi -> "リーチ"
  | Ippatsu -> "一発"
  | Tsumo -> "門前清自摸和"
  | Tanyao -> "断么九"
  | Pinfu -> "平和"
  | Iipeiko -> "一盃口"
  | Yakuhai j -> (match j with
    | Tile.Haku -> "役牌 白"
    | Tile.Hatsu -> "役牌 發"
    | Tile.Chun -> "役牌 中"
    | Tile.Ton -> "役牌 東"
    | Tile.Nan -> "役牌 南"
    | Tile.Sha -> "役牌 西"
    | Tile.Pei -> "役牌 北")
  | Chanta -> "混全帯么九"
  | Ittsu -> "一気通貫"
  | Sanshoku_doujun -> "三色同順"
  | Sanshoku_doukou -> "三色同刻"
  | Toitoi -> "対々和"
  | Sanankou -> "三暗刻"
  | Honroutou -> "混老頭"
  | Shousangen -> "小三元"
  | Chiitoitsu -> "七対子"
  | Honitsu -> "混一色"
  | Junchan -> "純全帯么九"
  | Ryanpeiko -> "二盃口"
  | Chinitsu -> "清一色"
  | Kokushi -> "国士無双"
  | Suuankou -> "四暗刻"
  | Daisangen -> "大三元"
  | Shousuushii -> "小四喜"
  | Daisuushii -> "大四喜"
  | Tsuuiisou -> "字一色"
  | Ryuuiisou -> "緑一色"
  | Chinroutou -> "清老頭"
  | Chuuren -> "九蓮宝燈"
  | Tenhou -> "天和"
  | Chiihou -> "地和"

(** 么九牌か判定 *)
let is_yaochu = function
  | Tile.Suhai (_, n) -> n = 1 || n = 9
  | Tile.Jihai _ -> true

(** 老頭牌か判定（1,9の数牌のみ） *)
let is_routouhai = function
  | Tile.Suhai (_, n) -> n = 1 || n = 9
  | Tile.Jihai _ -> false

(** 三元牌か *)
let is_sangenpai = function
  | Tile.Jihai (Tile.Haku | Tile.Hatsu | Tile.Chun) -> true
  | _ -> false

(** 風牌か *)
let is_kazehai = function
  | Tile.Jihai (Tile.Ton | Tile.Nan | Tile.Sha | Tile.Pei) -> true
  | _ -> false

(** 面子から全ての牌を取得 *)
let tiles_of_mentsu = function
  | Mentsu.Shuntsu (t1, t2, t3) -> [t1; t2; t3]
  | Mentsu.Koutsu t -> [t; t; t]
  | Mentsu.Kantsu t -> [t; t; t; t]

(** 数牌のsuit取得 *)
let suit_of_tile = function
  | Tile.Suhai (s, _) -> Some s
  | Tile.Jihai _ -> None

(** 和了の場の情報 *)
type agari_context = {
  is_tsumo : bool;        (** ツモ和了か *)
  is_riichi : bool;       (** リーチしているか *)
  is_double_riichi : bool;(** ダブルリーチか *)
  is_ippatsu : bool;      (** 一発か *)
  is_tenhou : bool;       (** 天和か *)
  is_chiihou : bool;      (** 地和か *)
  is_menzen : bool;       (** 門前か *)
  is_haitei : bool;       (** 海底ツモか *)
  is_houtei : bool;       (** 河底ロンか *)
  dora_count : int;       (** ドラ枚数 *)
  bakaze : Tile.jihai;    (** 場風 *)
  jikaze : Tile.jihai;    (** 自風 *)
}

let default_context = {
  is_tsumo = false;
  is_riichi = false;
  is_double_riichi = false;
  is_ippatsu = false;
  is_tenhou = false;
  is_chiihou = false;
  is_menzen = true;
  is_haitei = false;
  is_houtei = false;
  dora_count = 0;
  bakaze = Tile.Ton;
  jikaze = Tile.Ton;
}

(** 七対子判定 *)
let check_chiitoitsu (tiles : Tile.tile list) : bool =
  if List.length tiles <> 14 then false
  else
    let sorted = List.sort Tile.compare tiles in
    let rec check = function
      | [] -> true
      | [_] -> false
      | a :: b :: rest ->
        Tile.compare a b = 0 && check rest
    in
    check sorted

(** 国士無双判定 *)
let check_kokushi (tiles : Tile.tile list) : bool =
  if List.length tiles <> 14 then false
  else
    let yaochu_types = [
      Tile.Suhai (Tile.Manzu, 1); Tile.Suhai (Tile.Manzu, 9);
      Tile.Suhai (Tile.Pinzu, 1); Tile.Suhai (Tile.Pinzu, 9);
      Tile.Suhai (Tile.Souzu, 1); Tile.Suhai (Tile.Souzu, 9);
      Tile.Jihai Tile.Ton; Tile.Jihai Tile.Nan;
      Tile.Jihai Tile.Sha; Tile.Jihai Tile.Pei;
      Tile.Jihai Tile.Haku; Tile.Jihai Tile.Hatsu; Tile.Jihai Tile.Chun;
    ] in
    let has tile = List.exists (fun t -> Tile.compare t tile = 0) tiles in
    let count tile = List.length (List.filter (fun t -> Tile.compare t tile = 0) tiles) in
    List.for_all has yaochu_types &&
    List.exists (fun t -> count t = 2) yaochu_types

(** 断么九判定: 全ての牌が中張牌(2-8) *)
let check_tanyao (pattern : Mentsu.agari_pattern) : bool =
  let all_tiles =
    List.concat_map tiles_of_mentsu pattern.mentsu_list @ [pattern.jantai; pattern.jantai]
  in
  List.for_all (fun t -> not (is_yaochu t)) all_tiles

(** 平和判定: 全て順子 + 雀頭が役牌でない *)
let check_pinfu (pattern : Mentsu.agari_pattern) (ctx : agari_context) : bool =
  let all_shuntsu = List.for_all (fun m ->
    match m with Mentsu.Shuntsu _ -> true | _ -> false
  ) pattern.mentsu_list in
  let jantai_is_yakuhai = match pattern.jantai with
    | Tile.Jihai j ->
      j = Tile.Haku || j = Tile.Hatsu || j = Tile.Chun ||
      j = ctx.bakaze || j = ctx.jikaze
    | _ -> false
  in
  all_shuntsu && not jantai_is_yakuhai

(** 対々和判定: 全て刻子 *)
let check_toitoi (pattern : Mentsu.agari_pattern) : bool =
  List.for_all (fun m ->
    match m with Mentsu.Koutsu _ -> true | _ -> false
  ) pattern.mentsu_list

(** 三暗刻判定: 刻子が3つ以上 *)
let check_sanankou (pattern : Mentsu.agari_pattern) : bool =
  let koutsu_count = List.length (List.filter (fun m ->
    match m with Mentsu.Koutsu _ -> true | _ -> false
  ) pattern.mentsu_list) in
  koutsu_count >= 3

(** 四暗刻判定: 刻子が4つ *)
let check_suuankou (pattern : Mentsu.agari_pattern) : bool =
  List.for_all (fun m ->
    match m with Mentsu.Koutsu _ -> true | _ -> false
  ) pattern.mentsu_list

(** 一盃口判定: 同じ順子が2組 *)
let check_iipeiko (pattern : Mentsu.agari_pattern) : bool =
  let shuntsus = List.filter_map (fun m ->
    match m with Mentsu.Shuntsu (t1, _, _) -> Some t1 | _ -> None
  ) pattern.mentsu_list in
  let sorted = List.sort Tile.compare shuntsus in
  let rec has_pair = function
    | [] | [_] -> false
    | a :: b :: rest ->
      if Tile.compare a b = 0 then true
      else has_pair (b :: rest)
  in
  has_pair sorted

(** 二盃口判定: 同じ順子が2組×2 *)
let check_ryanpeiko (pattern : Mentsu.agari_pattern) : bool =
  let shuntsus = List.filter_map (fun m ->
    match m with Mentsu.Shuntsu (t1, _, _) -> Some t1 | _ -> None
  ) pattern.mentsu_list in
  if List.length shuntsus <> 4 then false
  else
    let sorted = List.sort Tile.compare shuntsus in
    match sorted with
    | [a; b; c; d] ->
      Tile.compare a b = 0 && Tile.compare c d = 0
    | _ -> false

(** 役牌判定 *)
let check_yakuhai (pattern : Mentsu.agari_pattern) (ctx : agari_context) : yaku list =
  let yakus = ref [] in
  List.iter (fun m ->
    match m with
    | Mentsu.Koutsu (Tile.Jihai j) ->
      if j = Tile.Haku || j = Tile.Hatsu || j = Tile.Chun then
        yakus := Yakuhai j :: !yakus;
      if j = ctx.bakaze then
        yakus := Yakuhai j :: !yakus;
      if j = ctx.jikaze && ctx.jikaze <> ctx.bakaze then
        yakus := Yakuhai j :: !yakus;
      (* 連風牌の場合は上でbakazeとして1つ付いているので、jikazeとしてもう1つ付ける *)
      if j = ctx.jikaze && ctx.jikaze = ctx.bakaze then
        yakus := Yakuhai j :: !yakus
    | _ -> ()
  ) pattern.mentsu_list;
  !yakus

(** 混一色判定: 1種の数牌 + 字牌のみ *)
let check_honitsu (pattern : Mentsu.agari_pattern) : bool =
  let all_tiles =
    List.concat_map tiles_of_mentsu pattern.mentsu_list @ [pattern.jantai; pattern.jantai]
  in
  let suits = List.filter_map suit_of_tile all_tiles in
  let has_jihai = List.exists (fun t -> match t with Tile.Jihai _ -> true | _ -> false) all_tiles in
  match suits with
  | [] -> false
  | s :: rest -> has_jihai && List.for_all (fun s2 -> s2 = s) rest

(** 清一色判定: 1種の数牌のみ *)
let check_chinitsu (pattern : Mentsu.agari_pattern) : bool =
  let all_tiles =
    List.concat_map tiles_of_mentsu pattern.mentsu_list @ [pattern.jantai; pattern.jantai]
  in
  let no_jihai = List.for_all (fun t -> match t with Tile.Jihai _ -> false | _ -> true) all_tiles in
  let suits = List.filter_map suit_of_tile all_tiles in
  match suits with
  | [] -> false
  | s :: rest -> no_jihai && List.for_all (fun s2 -> s2 = s) rest

(** 混老頭判定: 全て么九牌 *)
let check_honroutou (pattern : Mentsu.agari_pattern) : bool =
  let all_tiles =
    List.concat_map tiles_of_mentsu pattern.mentsu_list @ [pattern.jantai; pattern.jantai]
  in
  List.for_all is_yaochu all_tiles

(** 清老頭判定: 全て老頭牌(1,9のみ) *)
let check_chinroutou (pattern : Mentsu.agari_pattern) : bool =
  let all_tiles =
    List.concat_map tiles_of_mentsu pattern.mentsu_list @ [pattern.jantai; pattern.jantai]
  in
  List.for_all is_routouhai all_tiles

(** 字一色判定: 全て字牌 *)
let check_tsuuiisou (pattern : Mentsu.agari_pattern) : bool =
  let all_tiles =
    List.concat_map tiles_of_mentsu pattern.mentsu_list @ [pattern.jantai; pattern.jantai]
  in
  List.for_all (fun t -> match t with Tile.Jihai _ -> true | _ -> false) all_tiles

(** 小三元判定: 三元牌の刻子2つ + 三元牌の雀頭 *)
let check_shousangen (pattern : Mentsu.agari_pattern) : bool =
  let sangen_koutsu = List.length (List.filter (fun m ->
    match m with Mentsu.Koutsu t -> is_sangenpai t | _ -> false
  ) pattern.mentsu_list) in
  let jantai_is_sangen = match pattern.jantai with
    | Tile.Jihai (Tile.Haku | Tile.Hatsu | Tile.Chun) -> true
    | _ -> false
  in
  sangen_koutsu = 2 && jantai_is_sangen

(** 大三元判定: 三元牌の刻子3つ *)
let check_daisangen (pattern : Mentsu.agari_pattern) : bool =
  let sangen_koutsu = List.length (List.filter (fun m ->
    match m with Mentsu.Koutsu t -> is_sangenpai t | _ -> false
  ) pattern.mentsu_list) in
  sangen_koutsu = 3

(** 小四喜判定: 風牌の刻子3つ + 風牌の雀頭 *)
let check_shousuushii (pattern : Mentsu.agari_pattern) : bool =
  let kaze_koutsu = List.length (List.filter (fun m ->
    match m with Mentsu.Koutsu t -> is_kazehai t | _ -> false
  ) pattern.mentsu_list) in
  let jantai_is_kaze = is_kazehai pattern.jantai in
  kaze_koutsu = 3 && jantai_is_kaze

(** 大四喜判定: 風牌の刻子4つ *)
let check_daisuushii (pattern : Mentsu.agari_pattern) : bool =
  let kaze_koutsu = List.length (List.filter (fun m ->
    match m with Mentsu.Koutsu t -> is_kazehai t | _ -> false
  ) pattern.mentsu_list) in
  kaze_koutsu = 4

(** 一気通貫判定: 同じ種類で123,456,789の順子 *)
let check_ittsu (pattern : Mentsu.agari_pattern) : bool =
  let shuntsus = List.filter_map (fun m ->
    match m with
    | Mentsu.Shuntsu (Tile.Suhai (s, n), _, _) -> Some (s, n)
    | _ -> None
  ) pattern.mentsu_list in
  let suits = [Tile.Manzu; Tile.Pinzu; Tile.Souzu] in
  List.exists (fun s ->
    List.exists (fun (s2, n) -> s2 = s && n = 1) shuntsus &&
    List.exists (fun (s2, n) -> s2 = s && n = 4) shuntsus &&
    List.exists (fun (s2, n) -> s2 = s && n = 7) shuntsus
  ) suits

(** 三色同順判定: 3種の数牌で同じ数字の順子 *)
let check_sanshoku_doujun (pattern : Mentsu.agari_pattern) : bool =
  let shuntsus = List.filter_map (fun m ->
    match m with
    | Mentsu.Shuntsu (Tile.Suhai (s, n), _, _) -> Some (s, n)
    | _ -> None
  ) pattern.mentsu_list in
  let numbers = [1; 2; 3; 4; 5; 6; 7] in
  List.exists (fun n ->
    List.exists (fun (s, n2) -> s = Tile.Manzu && n2 = n) shuntsus &&
    List.exists (fun (s, n2) -> s = Tile.Pinzu && n2 = n) shuntsus &&
    List.exists (fun (s, n2) -> s = Tile.Souzu && n2 = n) shuntsus
  ) numbers

(** 三色同刻判定: 3種の数牌で同じ数字の刻子 *)
let check_sanshoku_doukou (pattern : Mentsu.agari_pattern) : bool =
  let koutsus = List.filter_map (fun m ->
    match m with
    | Mentsu.Koutsu (Tile.Suhai (s, n)) -> Some (s, n)
    | _ -> None
  ) pattern.mentsu_list in
  let numbers = [1; 2; 3; 4; 5; 6; 7; 8; 9] in
  List.exists (fun n ->
    List.exists (fun (s, n2) -> s = Tile.Manzu && n2 = n) koutsus &&
    List.exists (fun (s, n2) -> s = Tile.Pinzu && n2 = n) koutsus &&
    List.exists (fun (s, n2) -> s = Tile.Souzu && n2 = n) koutsus
  ) numbers

(** 混全帯么九判定: 全ての面子と雀頭に么九牌を含む（字牌あり） *)
let check_chanta (pattern : Mentsu.agari_pattern) : bool =
  let mentsu_has_yaochu m =
    List.exists is_yaochu (tiles_of_mentsu m)
  in
  let jantai_yaochu = is_yaochu pattern.jantai in
  let has_jihai =
    let all = List.concat_map tiles_of_mentsu pattern.mentsu_list @ [pattern.jantai] in
    List.exists (fun t -> match t with Tile.Jihai _ -> true | _ -> false) all
  in
  List.for_all mentsu_has_yaochu pattern.mentsu_list && jantai_yaochu && has_jihai

(** 純全帯么九判定: 全ての面子と雀頭に老頭牌を含む（字牌なし） *)
let check_junchan (pattern : Mentsu.agari_pattern) : bool =
  let mentsu_has_routou m =
    List.exists is_routouhai (tiles_of_mentsu m)
  in
  let jantai_routou = is_routouhai pattern.jantai in
  let no_jihai =
    let all = List.concat_map tiles_of_mentsu pattern.mentsu_list @ [pattern.jantai] in
    List.for_all (fun t -> match t with Tile.Jihai _ -> false | _ -> true) all
  in
  List.for_all mentsu_has_routou pattern.mentsu_list && jantai_routou && no_jihai

(** 食い下がりの翻数（鳴き時に1翻下がる役） *)
let han_of_yaku_open = function
  | Chanta -> 1
  | Ittsu -> 1
  | Sanshoku_doujun -> 1
  | Honitsu -> 2
  | Junchan -> 2
  | Chinitsu -> 5
  | y -> han_of_yaku y  (* 変化なし *)

(** 和了パターンから成立する役を全て判定する *)
let judge_yaku (pattern : Mentsu.agari_pattern) (ctx : agari_context) : yaku list =
  let yakus = ref [] in
  let add y = yakus := y :: !yakus in

  (* 役満チェック *)
  if check_suuankou pattern && ctx.is_tsumo then add Suuankou;
  if check_daisangen pattern then add Daisangen;
  if check_shousuushii pattern then add Shousuushii;
  if check_daisuushii pattern then add Daisuushii;
  if check_tsuuiisou pattern then add Tsuuiisou;
  if check_chinroutou pattern then add Chinroutou;

  (* 役満があれば他の役は不要 *)
  if !yakus <> [] then !yakus
  else begin
    (* 状況役 *)
    if ctx.is_double_riichi then add Riichi;  (* ダブリー: 2翻として扱う（Riichi + 追加1翻は後で加算） *)
    if ctx.is_riichi && not ctx.is_double_riichi then add Riichi;
    if ctx.is_ippatsu then add Ippatsu;
    if ctx.is_tsumo && ctx.is_menzen then add Tsumo;
    if ctx.is_tenhou then add Tenhou;
    if ctx.is_chiihou then add Chiihou;
    if ctx.is_haitei then add Tsumo;  (* 海底ツモ: 1翻追加 *)
    if ctx.is_houtei then add Tsumo;  (* 河底ロン: 1翻追加 *)

    (* 手役: 門前限定の役は鳴いていたら付かない *)
    if check_tanyao pattern then add Tanyao;
    if ctx.is_menzen && check_pinfu pattern ctx then add Pinfu;
    if check_toitoi pattern then add Toitoi;
    if check_sanankou pattern then add Sanankou;
    if check_honroutou pattern then add Honroutou;
    if check_shousangen pattern then add Shousangen;
    if check_honitsu pattern then add Honitsu;
    if check_chinitsu pattern then add Chinitsu;
    if check_ittsu pattern then add Ittsu;
    if check_sanshoku_doujun pattern then add Sanshoku_doujun;
    if check_sanshoku_doukou pattern then add Sanshoku_doukou;
    if check_chanta pattern then add Chanta;
    if check_junchan pattern then add Junchan;
    if ctx.is_menzen then begin
      if check_ryanpeiko pattern then add Ryanpeiko
      else if check_iipeiko pattern then add Iipeiko
    end;

    (* 役牌 *)
    let yh = check_yakuhai pattern ctx in
    List.iter add yh;

    !yakus
  end

(** 翻数を計算（食い下がり対応） *)
let calc_han (yakus : yaku list) (is_menzen : bool) : int =
  let base = List.fold_left (fun acc y ->
    acc + (if is_menzen then han_of_yaku y else han_of_yaku_open y)
  ) 0 yakus in
  base

(** 全手牌から最も高い役の組み合わせを判定 *)
let judge (tiles : Tile.tile list) (ctx : agari_context) : (yaku list * int) option =
  (* 特殊形チェック *)
  let special_yakus = ref [] in
  if check_kokushi tiles then special_yakus := [Kokushi];
  if check_chiitoitsu tiles then special_yakus := [Chiitoitsu];

  (* 通常形チェック *)
  let patterns = Mentsu.find_agari_patterns tiles in
  let normal_results = List.map (fun p ->
    let yakus = judge_yaku p ctx in
    let han = calc_han yakus ctx.is_menzen in
    (* ダブルリーチ: +1翻追加 *)
    let han = if ctx.is_double_riichi then han + 1 else han in
    (yakus, han)
  ) patterns in

  let special_results = List.map (fun yakus ->
    let han = calc_han yakus ctx.is_menzen in
    let han = if ctx.is_double_riichi then han + 1 else han in
    (yakus, han)
  ) [!special_yakus] in

  let all_results = List.filter (fun (yakus, _) -> yakus <> []) (normal_results @ special_results) in

  (* ドラ加算 *)
  let add_dora (yakus, han) = (yakus, han + ctx.dora_count) in

  match all_results with
  | [] -> None
  | _ ->
    let best = List.fold_left (fun best (y, h) ->
      match best with (_, bh) -> if h > bh then (y, h) else best
    ) (List.hd all_results) all_results in
    Some (add_dora best)
