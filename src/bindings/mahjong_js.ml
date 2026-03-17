(** Melange JS バインディング - JSON文字列でJS/OCaml間をブリッジ *)

open Mahjong_core

(** === JSON エンコーダ === *)

let json_str s = "\"" ^ s ^ "\""
let json_int n = string_of_int n
let json_bool b = if b then "true" else "false"
let json_null = "null"
let json_obj fields =
  "{" ^ String.concat "," (List.map (fun (k, v) -> "\"" ^ k ^ "\":" ^ v) fields) ^ "}"
let json_arr items =
  "[" ^ String.concat "," items ^ "]"

let tile_to_json_with_red (tile : Tile.tile) (is_red : bool) : string =
  match tile with
  | Tile.Suhai (suit, n) ->
    let suit_str = match suit with
      | Tile.Manzu -> "manzu" | Tile.Pinzu -> "pinzu" | Tile.Souzu -> "souzu"
    in
    json_obj [("kind", json_str "suhai"); ("suit", json_str suit_str);
              ("number", json_int n); ("label", json_str (Tile.to_string tile));
              ("is_red", json_bool is_red)]
  | Tile.Jihai j ->
    let suit_str = match j with
      | Tile.Ton | Tile.Nan | Tile.Sha | Tile.Pei -> "kaze"
      | Tile.Haku | Tile.Hatsu | Tile.Chun -> "sangen"
    in
    let number = match j with
      | Tile.Ton -> 1 | Tile.Nan -> 2 | Tile.Sha -> 3 | Tile.Pei -> 4
      | Tile.Haku -> 5 | Tile.Hatsu -> 6 | Tile.Chun -> 7
    in
    json_obj [("kind", json_str "jihai"); ("suit", json_str suit_str);
              ("number", json_int number); ("label", json_str (Tile.to_string tile));
              ("is_red", json_bool false)]

let tile_to_json (tile : Tile.tile) : string =
  tile_to_json_with_red tile false

let yaku_id_of (y : Yaku.yaku) : string =
  match y with
  | Yaku.Riichi -> "riichi" | Yaku.Ippatsu -> "ippatsu" | Yaku.Tsumo -> "tsumo"
  | Yaku.Tanyao -> "tanyao" | Yaku.Pinfu -> "pinfu" | Yaku.Iipeiko -> "iipeiko"
  | Yaku.Yakuhai _ -> "yakuhai" | Yaku.Chanta -> "chanta" | Yaku.Ittsu -> "ittsu"
  | Yaku.Sanshoku_doujun -> "sanshoku_doujun" | Yaku.Sanshoku_doukou -> "sanshoku_doukou"
  | Yaku.Toitoi -> "toitoi" | Yaku.Sanankou -> "sanankou" | Yaku.Honroutou -> "honroutou"
  | Yaku.Shousangen -> "shousangen" | Yaku.Chiitoitsu -> "chiitoitsu"
  | Yaku.Honitsu -> "honitsu" | Yaku.Junchan -> "junchan"
  | Yaku.Ryanpeiko -> "ryanpeiko" | Yaku.Chinitsu -> "chinitsu"
  | Yaku.Kokushi -> "kokushi" | Yaku.Suuankou -> "suuankou"
  | Yaku.Daisangen -> "daisangen" | Yaku.Shousuushii -> "shousuushii"
  | Yaku.Daisuushii -> "daisuushii" | Yaku.Tsuuiisou -> "tsuuiisou"
  | Yaku.Ryuuiisou -> "ryuuiisou" | Yaku.Chinroutou -> "chinroutou"
  | Yaku.Chuuren -> "chuuren" | Yaku.Haitei -> "haitei" | Yaku.Houtei -> "houtei"
  | Yaku.Tenhou -> "tenhou" | Yaku.Chiihou -> "chiihou"

let yaku_to_json (y : Yaku.yaku) : string =
  json_obj [("id", json_str (yaku_id_of y)); ("han", json_int (Yaku.han_of_yaku y))]

let payment_to_json (p : Scoring.payment) : string =
  match p with
  | Scoring.Ron n ->
    json_obj [("kind", json_str "ron"); ("ron", json_int n)]
  | Scoring.Tsumo_oya n ->
    json_obj [("kind", json_str "tsumo_oya"); ("ko_pay", json_int n)]
  | Scoring.Tsumo_ko (oya, ko) ->
    json_obj [("kind", json_str "tsumo_ko"); ("oya_pay", json_int oya); ("ko_pay", json_int ko)]

let player_to_json (p : Player.t) : string =
  (* 赤ドラ判定付きの牌変換 *)
  let tile_with_red (t : Tile.tile) (used_m : bool ref) (used_p : bool ref) (used_s : bool ref) : string =
    match t with
    | Tile.Suhai (Tile.Manzu, 5) when p.aka_manzu && not !used_m ->
      used_m := true; tile_to_json_with_red t true
    | Tile.Suhai (Tile.Pinzu, 5) when p.aka_pinzu && not !used_p ->
      used_p := true; tile_to_json_with_red t true
    | Tile.Suhai (Tile.Souzu, 5) when p.aka_souzu && not !used_s ->
      used_s := true; tile_to_json_with_red t true
    | _ -> tile_to_json t
  in
  let used_m = ref false and used_p = ref false and used_s = ref false in
  (* ツモ牌を分離 *)
  let (sorted_hand, tsumo_tile) = match p.hand.tsumo with
    | Some t ->
      (match Mentsu.remove_one t p.hand.tiles with
       | Some rest -> (List.sort Tile.compare rest, tile_with_red t used_m used_p used_s)
       | None -> (List.sort Tile.compare p.hand.tiles, json_null))
    | None -> (List.sort Tile.compare p.hand.tiles, json_null)
  in
  let hand = json_arr (List.map (fun t -> tile_with_red t used_m used_p used_s) sorted_hand) in
  let kawa = json_arr (List.rev_map tile_to_json p.kawa) in
  let jikaze_str = match p.jikaze with
    | Tile.Ton -> "ton" | Tile.Nan -> "nan"
    | Tile.Sha -> "sha" | Tile.Pei -> "pei"
    | _ -> "ton"
  in
  let furo = json_arr (List.map (fun f ->
    match f with
    | Player.Chi (t1, t2, t3) ->
      json_obj [("type", json_str "chi"); ("tiles", json_arr [tile_to_json t1; tile_to_json t2; tile_to_json t3])]
    | Player.Pon t ->
      json_obj [("type", json_str "pon"); ("tiles", json_arr [tile_to_json t; tile_to_json t; tile_to_json t])]
    | Player.Minkan t ->
      json_obj [("type", json_str "kan"); ("tiles", json_arr [tile_to_json t; tile_to_json t; tile_to_json t; tile_to_json t])]
    | Player.Ankan t ->
      json_obj [("type", json_str "ankan"); ("tiles", json_arr [tile_to_json t; tile_to_json t; tile_to_json t; tile_to_json t])]
  ) p.furo_list) in
  json_obj [
    ("hand", hand); ("tsumo", tsumo_tile); ("furo", furo);
    ("kawa", kawa); ("score", json_int p.score);
    ("is_riichi", json_bool p.is_riichi); ("is_menzen", json_bool (Player.is_menzen p));
    ("jikaze", json_str jikaze_str);
    ("aka_count", json_int p.aka_count)
  ]

let game_state_to_json (game : Game.round) : string =
  let players = json_arr (Array.to_list (Array.map player_to_json game.players)) in
  let phase_str = match game.phase with
    | Game.WaitingDraw -> "waiting_draw" | Game.WaitingDiscard -> "waiting_discard"
    | Game.WaitingCall -> "waiting_call" | Game.RoundEnd -> "round_end"
    | Game.GameEnd -> "game_end"
  in
  let bakaze_str = match game.bakaze with
    | Tile.Ton -> "ton" | Tile.Nan -> "nan"
    | Tile.Sha -> "sha" | Tile.Pei -> "pei"
    | _ -> "ton"
  in
  let last_d = match game.last_discard with
    | Some t -> tile_to_json t | None -> json_null
  in
  let dora = json_arr (List.map tile_to_json (Wall.dora_indicators game.wall game.kan_count)) in
  json_obj [
    ("players", players); ("current_turn", json_int game.current_turn);
    ("phase", json_str phase_str); ("bakaze", json_str bakaze_str);
    ("kyoku", json_int game.kyoku); ("honba", json_int game.honba);
    ("remaining_tiles", json_int (Wall.remaining game.wall));
    ("dora_indicators", dora);
    ("last_discard", last_d)
  ]

(** === JS向けAPI === *)

let game_ref : Game.round option ref = ref None

let tile_of_kind_suit_number kind suit number =
  if kind = "suhai" then
    let s = match suit with
      | "manzu" -> Tile.Manzu | "pinzu" -> Tile.Pinzu | _ -> Tile.Souzu
    in
    Tile.Suhai (s, number)
  else
    match number with
    | 1 -> Tile.Jihai Tile.Ton | 2 -> Tile.Jihai Tile.Nan
    | 3 -> Tile.Jihai Tile.Sha | 4 -> Tile.Jihai Tile.Pei
    | 5 -> Tile.Jihai Tile.Haku | 6 -> Tile.Jihai Tile.Hatsu
    | _ -> Tile.Jihai Tile.Chun

let start_game () : string =
  let game = Game.start () in
  game_ref := Some game;
  game_state_to_json game

let get_state () : string =
  match !game_ref with
  | Some game -> game_state_to_json game
  | None -> json_null

let draw_tile () : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    match Game.draw_tile game with
    | Ok new_game -> game_ref := Some new_game; game_state_to_json new_game
    | Error _ -> json_null

let discard_tile kind suit number : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let tile = tile_of_kind_suit_number kind suit number in
    match Game.discard_tile game tile with
    | Ok new_game -> game_ref := Some new_game; game_state_to_json new_game
    | Error _ -> json_null

let advance_turn () : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let new_game = Game.advance_turn game in
    game_ref := Some new_game;
    game_state_to_json new_game

let check_tsumo () : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let player = game.players.(game.current_turn) in
    let dora_n = Wall.count_dora game.wall game.kan_count player.hand.tiles in
    let uradora_n = if player.is_riichi then Wall.count_uradora game.wall game.kan_count player.hand.tiles else 0 in
    let aka_n = player.aka_count in
    let ctx = {
      Yaku.is_tsumo = true; is_riichi = player.is_riichi; is_double_riichi = player.is_double_riichi;
      is_ippatsu = false; is_tenhou = false; is_chiihou = false; is_menzen = Player.is_menzen player; is_haitei = false; is_houtei = false; dora_count = dora_n + uradora_n + aka_n;
      agari_tile = None; bakaze = game.bakaze; jikaze = player.jikaze;
    } in
    let is_oya = player.jikaze = Tile.Ton in
    let furo_count = List.length player.furo_list in
    let furo_mentsu = player.furo_list in
    match Scoring.score_hand ~furo_count ~furo_mentsu player.hand.tiles ctx is_oya with
    | Some result ->
      let dora_tiles = json_arr (List.map tile_to_json (List.map Wall.dora_of_indicator (Wall.dora_indicators game.wall game.kan_count))) in
      let uradora_tiles = if player.is_riichi then
        json_arr (List.map tile_to_json (List.map Wall.dora_of_indicator (Wall.uradora_indicators game.wall game.kan_count)))
      else json_arr [] in
      let used_m = ref false and used_p = ref false and used_s = ref false in
      let hand_json = json_arr (List.map (fun t ->
        match t with
        | Tile.Suhai (Tile.Manzu, 5) when player.aka_manzu && not !used_m ->
          used_m := true; tile_to_json_with_red t true
        | Tile.Suhai (Tile.Pinzu, 5) when player.aka_pinzu && not !used_p ->
          used_p := true; tile_to_json_with_red t true
        | Tile.Suhai (Tile.Souzu, 5) when player.aka_souzu && not !used_s ->
          used_s := true; tile_to_json_with_red t true
        | _ -> tile_to_json t
      ) (List.sort Tile.compare player.hand.tiles)) in
      (match Game.tsumo_agari game with
       | Ok new_game ->
         game_ref := Some new_game;
         json_obj [
           ("state", game_state_to_json new_game);
           ("yakus", json_arr (List.map yaku_to_json result.yakus));
           ("han", json_int result.han_detail);
           ("fu", json_int result.fu_detail);
           ("total", json_int result.total);
           ("payment", payment_to_json result.payments);
           ("dora", dora_tiles);
           ("uradora", uradora_tiles);
           ("dora_count", json_int dora_n);
           ("uradora_count", json_int uradora_n);
           ("aka_count", json_int aka_n);
           ("winner_hand", hand_json); ("winner_furo", json_arr (List.map (fun f -> match f with | Player.Chi (t1, t2, t3) -> json_obj [("type", json_str "chi"); ("tiles", json_arr [tile_to_json t1; tile_to_json t2; tile_to_json t3])] | Player.Pon t -> json_obj [("type", json_str "pon"); ("tiles", json_arr [tile_to_json t; tile_to_json t; tile_to_json t])] | Player.Minkan t | Player.Ankan t -> json_obj [("type", json_str "kan"); ("tiles", json_arr [tile_to_json t; tile_to_json t; tile_to_json t; tile_to_json t])]) player.furo_list));
           ("agari_tile", json_null);
           ("is_tsumo", json_bool true)
         ]
       | Error _ -> json_null)
    | None -> json_null

(** ロン可否判定（副作用なし） *)
let can_ron seat : bool =
  match !game_ref with
  | None -> false
  | Some game ->
    match game.last_discard with
    | None -> false
    | Some tile ->
      let player = game.players.(seat) in
      (* 振聴チェック *)
      if List.exists (fun t -> Tile.compare t tile = 0) player.kawa then false
      else
        let tiles = tile :: player.hand.tiles in
        let ctx = {
          Yaku.is_tsumo = false; is_riichi = player.is_riichi; is_double_riichi = player.is_double_riichi;
          is_ippatsu = false; is_tenhou = false; is_chiihou = false;
          is_menzen = Player.is_menzen player; is_haitei = false; is_houtei = false;
          dora_count = 0; agari_tile = None; bakaze = game.bakaze; jikaze = player.jikaze;
        } in
        let is_oya = player.jikaze = Tile.Ton in
        match Scoring.score_hand ~furo_count:(List.length player.furo_list) ~furo_mentsu:player.furo_list tiles ctx is_oya with
        | Some _ -> true
        | None -> false

let check_ron seat : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    match game.last_discard with
    | None -> json_null
    | Some tile ->
      let player = game.players.(seat) in
      let tiles = tile :: player.hand.tiles in
      let dora_n = Wall.count_dora game.wall game.kan_count tiles in
      let uradora_n = if player.is_riichi then Wall.count_uradora game.wall game.kan_count tiles else 0 in
      let aka_n = player.aka_count in
      let ctx = {
        Yaku.is_tsumo = false; is_riichi = player.is_riichi; is_double_riichi = player.is_double_riichi;
        is_ippatsu = false; is_tenhou = false; is_chiihou = false; is_menzen = Player.is_menzen player; is_haitei = false; is_houtei = false; dora_count = dora_n + uradora_n + aka_n;
        agari_tile = None; bakaze = game.bakaze; jikaze = player.jikaze;
      } in
      let is_oya = player.jikaze = Tile.Ton in
      (match Scoring.score_hand ~furo_count:(List.length player.furo_list) ~furo_mentsu:player.furo_list tiles ctx is_oya with
       | Some result ->
         let dora_tiles = json_arr (List.map tile_to_json (List.map Wall.dora_of_indicator (Wall.dora_indicators game.wall game.kan_count))) in
         let uradora_tiles = if player.is_riichi then
           json_arr (List.map tile_to_json (List.map Wall.dora_of_indicator (Wall.uradora_indicators game.wall game.kan_count)))
         else json_arr [] in
         let used_m = ref false and used_p = ref false and used_s = ref false in
         let hand_json = json_arr (List.map (fun t ->
           match t with
           | Tile.Suhai (Tile.Manzu, 5) when player.aka_manzu && not !used_m ->
             used_m := true; tile_to_json_with_red t true
           | Tile.Suhai (Tile.Pinzu, 5) when player.aka_pinzu && not !used_p ->
             used_p := true; tile_to_json_with_red t true
           | Tile.Suhai (Tile.Souzu, 5) when player.aka_souzu && not !used_s ->
             used_s := true; tile_to_json_with_red t true
           | _ -> tile_to_json t
         ) (List.sort Tile.compare player.hand.tiles)) in
         (match Game.ron game seat with
          | Ok new_game ->
            game_ref := Some new_game;
            json_obj [
              ("state", game_state_to_json new_game);
              ("yakus", json_arr (List.map yaku_to_json result.yakus));
              ("han", json_int result.han_detail);
              ("fu", json_int result.fu_detail);
              ("total", json_int result.total);
              ("payment", payment_to_json result.payments);
              ("dora", dora_tiles);
              ("uradora", uradora_tiles);
              ("dora_count", json_int dora_n);
              ("uradora_count", json_int uradora_n);
              ("aka_count", json_int aka_n);
              ("winner_hand", hand_json); ("winner_furo", json_arr (List.map (fun f -> match f with | Player.Chi (t1, t2, t3) -> json_obj [("type", json_str "chi"); ("tiles", json_arr [tile_to_json t1; tile_to_json t2; tile_to_json t3])] | Player.Pon t -> json_obj [("type", json_str "pon"); ("tiles", json_arr [tile_to_json t; tile_to_json t; tile_to_json t])] | Player.Minkan t | Player.Ankan t -> json_obj [("type", json_str "kan"); ("tiles", json_arr [tile_to_json t; tile_to_json t; tile_to_json t; tile_to_json t])]) player.furo_list));
              ("agari_tile", tile_to_json tile);
              ("is_tsumo", json_bool false)
            ]
          | Error _ -> json_null)
       | None -> json_null)

let declare_riichi () : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    match Game.declare_riichi game with
    | Ok new_game -> game_ref := Some new_game; game_state_to_json new_game
    | Error _ -> json_null

let get_tenpai () : string =
  match !game_ref with
  | None -> json_arr []
  | Some game ->
    let player = game.players.(game.current_turn) in
    let tiles = player.hand.tiles in
    if List.length tiles = 13 then
      json_arr (List.map tile_to_json (Hand.tenpai_tiles player.hand))
    else if List.length tiles = 14 then
      (* 14枚: 各牌を1枚ずつ除いてテンパイ牌を集める *)
      let all_waits = ref [] in
      let tried = ref [] in
      List.iter (fun t ->
        if not (List.exists (fun s -> Tile.compare s t = 0) !tried) then begin
          tried := t :: !tried;
          match Mentsu.remove_one t tiles with
          | Some rest ->
            let waits = Hand.tenpai_tiles (Hand.make rest) in
            List.iter (fun w ->
              if not (List.exists (fun x -> Tile.compare x w = 0) !all_waits) then
                all_waits := w :: !all_waits
            ) waits
          | None -> ()
        end
      ) tiles;
      json_arr (List.map tile_to_json !all_waits)
    else json_arr []

(** リーチ可能か（14枚手牌から1枚捨ててテンパイになるか） *)
let can_declare_riichi seat : bool =
  match !game_ref with
  | None -> false
  | Some game ->
    let player = game.players.(seat) in
    if player.is_riichi then false
    else if not (Player.is_menzen player) then false
    else if player.score < 1000 then false
    else
      let tiles = player.hand.tiles in
      if List.length tiles <> 14 then false
      else
        let tried = ref [] in
        let found = ref false in
        List.iter (fun t ->
          if not !found && not (List.exists (fun s -> Tile.compare s t = 0) !tried) then begin
            tried := t :: !tried;
            match Mentsu.remove_one t tiles with
            | Some rest ->
              if Hand.tenpai_tiles (Hand.make rest) <> [] then found := true
            | None -> ()
          end
        ) tiles;
        !found

(** リーチ宣言時に捨てられる牌のリスト（捨ててもテンパイを維持できる牌） *)
let riichi_discard_candidates seat : string =
  match !game_ref with
  | None -> json_arr []
  | Some game ->
    let player = game.players.(seat) in
    let tiles = player.hand.tiles in
    if List.length tiles <> 14 then json_arr []
    else
      let tried = ref [] in
      let candidates = ref [] in
      List.iter (fun t ->
        if not (List.exists (fun s -> Tile.compare s t = 0) !tried) then begin
          tried := t :: !tried;
          match Mentsu.remove_one t tiles with
          | Some rest ->
            if Hand.tenpai_tiles (Hand.make rest) <> [] then
              candidates := tile_to_json t :: !candidates
          | None -> ()
        end
      ) tiles;
      json_arr (List.rev !candidates)

(** リーチ宣言時の各捨て牌候補に対する待ち牌リストを返す *)
let riichi_discard_with_waits seat : string =
  match !game_ref with
  | None -> json_arr []
  | Some game ->
    let player = game.players.(seat) in
    let tiles = player.hand.tiles in
    if List.length tiles <> 14 then json_arr []
    else
      let tried = ref [] in
      let results = ref [] in
      List.iter (fun t ->
        if not (List.exists (fun s -> Tile.compare s t = 0) !tried) then begin
          tried := t :: !tried;
          match Mentsu.remove_one t tiles with
          | Some rest ->
            let waits = Hand.tenpai_tiles (Hand.make rest) in
            if waits <> [] then
              results := json_obj [
                ("discard", tile_to_json t);
                ("waits", json_arr (List.map tile_to_json waits))
              ] :: !results
          | None -> ()
        end
      ) tiles;
      json_arr (List.rev !results)

let next_round oya_won was_agari : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let new_game = Game.next_round ~was_agari game oya_won in
    game_ref := Some new_game;
    game_state_to_json new_game

(** 九種九牌判定: 最初のツモ後に手牌に9種以上の么九牌がある *)
let can_kyuushu seat : bool =
  match !game_ref with
  | None -> false
  | Some game ->
    if not game.first_turns.(seat) then false  (* 最初のターンでない *)
    else if not game.no_calls_yet then false   (* 鳴きが入った *)
    else
      let player = game.players.(seat) in
      let tiles = player.hand.tiles in
      let yaochu_types = ref [] in
      List.iter (fun t ->
        let is_yao = match t with
          | Tile.Suhai (_, n) -> n = 1 || n = 9
          | Tile.Jihai _ -> true
        in
        if is_yao && not (List.exists (fun s -> Tile.compare s t = 0) !yaochu_types) then
          yaochu_types := t :: !yaochu_types
      ) tiles;
      List.length !yaochu_types >= 9

(** 九種九牌で流局 *)
let declare_kyuushu () : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    game_ref := Some { game with phase = Game.RoundEnd };
    game_state_to_json { game with phase = Game.RoundEnd }

(** ポン可否判定 *)
let can_pon seat : bool =
  match !game_ref with
  | None -> false
  | Some game ->
    match game.last_discard with
    | None -> false
    | Some tile ->
      let player = game.players.(seat) in
      let count = List.length (List.filter (fun t -> Tile.compare t tile = 0) player.hand.tiles) in
      count >= 2

(** ポン実行 *)
let do_pon seat : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    match game.last_discard with
    | None -> json_null
    | Some tile ->
      let player = game.players.(seat) in
      match Player.pon tile player with
      | Ok new_player ->
        let players = Array.copy game.players in
        players.(seat) <- new_player;
        let new_game = { game with
          players;
          current_turn = seat;
          phase = Game.WaitingDiscard;
          no_calls_yet = false;
          last_discard = None;
          last_discard_player = None;
        } in
        game_ref := Some new_game;
        game_state_to_json new_game
      | Error _ -> json_null

(** チー可否判定 *)
let can_chi seat : string =
  match !game_ref with
  | None -> json_arr []
  | Some game ->
    match game.last_discard with
    | None -> json_arr []
    | Some tile ->
      match game.last_discard_player with
      | None -> json_arr []
      | Some discarder ->
        if (discarder + 1) mod 4 <> seat then json_arr []
        else
          let player = game.players.(seat) in
          let hand = player.hand.tiles in
          let results = ref [] in
          (match tile with
           | Tile.Suhai (suit, n) ->
             if n >= 3 then begin
               let t1 = Tile.Suhai (suit, n - 2) in
               let t2 = Tile.Suhai (suit, n - 1) in
               if List.exists (fun t -> Tile.compare t t1 = 0) hand &&
                  List.exists (fun t -> Tile.compare t t2 = 0) hand then
                 results := json_arr [tile_to_json t1; tile_to_json t2] :: !results
             end;
             if n >= 2 && n <= 8 then begin
               let t1 = Tile.Suhai (suit, n - 1) in
               let t2 = Tile.Suhai (suit, n + 1) in
               if List.exists (fun t -> Tile.compare t t1 = 0) hand &&
                  List.exists (fun t -> Tile.compare t t2 = 0) hand then
                 results := json_arr [tile_to_json t1; tile_to_json t2] :: !results
             end;
             if n <= 7 then begin
               let t1 = Tile.Suhai (suit, n + 1) in
               let t2 = Tile.Suhai (suit, n + 2) in
               if List.exists (fun t -> Tile.compare t t1 = 0) hand &&
                  List.exists (fun t -> Tile.compare t t2 = 0) hand then
                 results := json_arr [tile_to_json t1; tile_to_json t2] :: !results
             end
           | _ -> ());
          json_arr !results

(** チー実行 *)
let do_chi seat t1_kind t1_suit t1_num t2_kind t2_suit t2_num : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    match game.last_discard with
    | None -> json_null
    | Some taken ->
      let t1 = tile_of_kind_suit_number t1_kind t1_suit t1_num in
      let t2 = tile_of_kind_suit_number t2_kind t2_suit t2_num in
      let player = game.players.(seat) in
      match Player.chi t1 t2 taken player with
      | Ok new_player ->
        let players = Array.copy game.players in
        players.(seat) <- new_player;
        let new_game = { game with
          players;
          current_turn = seat;
          phase = Game.WaitingDiscard;
          no_calls_yet = false;
          last_discard = None;
          last_discard_player = None;
        } in
        game_ref := Some new_game;
        game_state_to_json new_game
      | Error _ -> json_null

(** 4カン流局チェック: 異なるプレイヤーによる4回目のカンで流局 *)
let check_4kan (game : Game.round) : Game.round =
  if game.kan_count >= 4 then
    (* 同一プレイヤーの4カンか確認 *)
    let kan_players = Array.to_list (Array.mapi (fun i (p : Player.t) ->
      let kan_n = List.length (List.filter (fun f ->
        match f with Player.Minkan _ | Player.Ankan _ -> true | _ -> false
      ) p.furo_list) in
      (i, kan_n)
    ) game.players) in
    let has_4kan_player = List.exists (fun (_, n) -> n >= 4) kan_players in
    if has_4kan_player then game  (* 四槓子の可能性 *)
    else { game with phase = Game.RoundEnd }  (* 流局 *)
  else game

(** 明槓可否判定 *)
let can_minkan seat : bool =
  match !game_ref with
  | None -> false
  | Some game ->
    match game.last_discard with
    | None -> false
    | Some tile ->
      let player = game.players.(seat) in
      let count = List.length (List.filter (fun t -> Tile.compare t tile = 0) player.hand.tiles) in
      count >= 3

(** 明槓実行 *)
let do_minkan seat : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    match game.last_discard with
    | None -> json_null
    | Some tile ->
      let player = game.players.(seat) in
      match Player.minkan tile player with
      | Ok new_player ->
        let players = Array.copy game.players in
        players.(seat) <- new_player;
        let new_game = { game with
          players; current_turn = seat;
          phase = Game.WaitingDraw;
          kan_count = game.kan_count + 1;
          last_discard = None; last_discard_player = None;
        } in
        let new_game = check_4kan new_game in
        game_ref := Some new_game;
        game_state_to_json new_game
      | Error _ -> json_null

(** 暗槓可否判定: 手牌に4枚同じ牌があるか *)
let can_ankan seat : string =
  match !game_ref with
  | None -> json_arr []
  | Some game ->
    let player = game.players.(seat) in
    let tiles = player.hand.tiles in
    let seen = ref [] in
    let results = ref [] in
    List.iter (fun t ->
      if not (List.exists (fun s -> Tile.compare s t = 0) !seen) then begin
        seen := t :: !seen;
        let count = List.length (List.filter (fun x -> Tile.compare x t = 0) tiles) in
        if count >= 4 then results := tile_to_json t :: !results
      end
    ) tiles;
    json_arr !results

(** 暗槓実行 *)
let do_ankan seat kind suit number : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let tile = tile_of_kind_suit_number kind suit number in
    let player = game.players.(seat) in
    match Player.ankan tile player with
    | Ok new_player ->
      let players = Array.copy game.players in
      players.(seat) <- new_player;
      let new_game = { game with
        players; current_turn = seat;
        phase = Game.WaitingDraw;
        kan_count = game.kan_count + 1;
      } in
      let new_game = check_4kan new_game in
      game_ref := Some new_game;
      game_state_to_json new_game
    | Error _ -> json_null

(** 加槓可否判定: ポン済み牌の4枚目を持っているか *)
let can_kakan seat : string =
  match !game_ref with
  | None -> json_arr []
  | Some game ->
    let player = game.players.(seat) in
    let results = ref [] in
    List.iter (fun f ->
      match f with
      | Player.Pon t ->
        if List.exists (fun x -> Tile.compare x t = 0) player.hand.tiles then
          results := tile_to_json t :: !results
      | _ -> ()
    ) player.furo_list;
    json_arr !results

(** 加槓実行 *)
let do_kakan seat kind suit number : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let tile = tile_of_kind_suit_number kind suit number in
    let player = game.players.(seat) in
    match Player.kakan tile player with
    | Ok new_player ->
      let players = Array.copy game.players in
      players.(seat) <- new_player;
      let new_game = { game with
        players; current_turn = seat;
        phase = Game.WaitingDraw;
        kan_count = game.kan_count + 1;
      } in
      let new_game = check_4kan new_game in
      game_ref := Some new_game;
      game_state_to_json new_game
    | Error _ -> json_null

(* === fu_detail: 符の詳細 === *)

let get_fu_breakdown seat : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let player = game.players.(seat) in
    let furo_count = List.length player.furo_list in
    let patterns = Mentsu.find_agari_patterns_furo player.hand.tiles furo_count in
    let extra = List.map Yaku.furo_to_mentsu player.furo_list in
    let full_patterns = List.map (fun (p : Mentsu.agari_pattern) ->
      { p with Mentsu.mentsu_list = p.mentsu_list @ extra }
    ) patterns in
    match Fu_detail.best_fu_breakdown full_patterns player.hand.tsumo
      game.Game.players.(seat).is_riichi (* is_tsumo approximation *)
      (Player.is_menzen player) furo_count game.bakaze player.jikaze with
    | None -> json_null
    | Some bd ->
      let mentsu_json = json_arr (List.map (fun d ->
        json_obj [("type", json_str d.Fu_detail.mentsu_type);
                  ("tile", json_str d.tile_label); ("fu", json_int d.fu)]
      ) bd.mentsu_fu_list) in
      json_obj [
        ("base_fu", json_int bd.base_fu);
        ("mentsu", mentsu_json);
        ("jantai_fu", json_int bd.jantai_fu);
        ("wait_type", json_str (Fu_detail.wait_type_to_string bd.wait_type));
        ("wait_type_ja", json_str (Fu_detail.wait_type_to_ja bd.wait_type));
        ("wait_fu", json_int bd.wait_fu);
        ("tsumo_fu", json_int bd.tsumo_fu);
        ("total_fu", json_int bd.total_fu);
        ("rounded_fu", json_int bd.rounded_fu)
      ]

(* === analyzer: 手牌分析 === *)

let get_hand_analysis seat : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let player = game.players.(seat) in
    let furo_count = List.length player.furo_list in
    let visible = ref [] in
    Array.iter (fun (p : Player.t) ->
      visible := List.rev_append p.kawa !visible
    ) game.players;
    let has_riichi = Array.exists (fun (p : Player.t) ->
      p.is_riichi && Tile.compare (Tile.Jihai p.jikaze) (Tile.Jihai player.jikaze) <> 0
    ) game.players in
    let dora = List.map Wall.dora_of_indicator (Wall.dora_indicators game.wall game.kan_count) in
    let analysis = Analyzer.analyze_hand player.hand.tiles furo_count
      !visible game.bakaze player.jikaze dora has_riichi in
    let discards_json = json_arr (List.map (fun (d : Analyzer.discard_analysis) ->
      json_obj [
        ("tile", tile_to_json d.tile);
        ("shanten", json_int d.shanten_after);
        ("acceptance", json_int d.acceptance);
        ("waits", json_arr (List.map tile_to_json d.wait_tiles));
        ("han", json_int d.estimated_han);
        ("reason", json_str d.reason)
      ]
    ) (List.filteri (fun i _ -> i < 5) analysis.best_discards)) in
    json_obj [
      ("shanten", json_int analysis.current_shanten);
      ("is_tenpai", json_bool analysis.is_tenpai);
      ("direction", json_str analysis.hand_direction);
      ("action", json_str analysis.recommended_action);
      ("discards", discards_json)
    ]

(* === simulation: 勝率推定 === *)

let get_win_probability seat trials : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let player = game.players.(seat) in
    let furo_count = List.length player.furo_list in
    let visible = ref [] in
    Array.iter (fun (p : Player.t) ->
      visible := List.rev_append p.kawa !visible
    ) game.players;
    let remaining = Wall.remaining game.wall in
    let sim = Simulation.run_simulation player.hand.tiles furo_count
      !visible game.bakaze player.jikaze trials (min 18 remaining) in
    json_obj [
      ("trials", json_int sim.trials);
      ("win_rate", json_str (Printf.sprintf "%.1f" (sim.win_rate *. 100.0)));
      ("avg_score", json_str (Printf.sprintf "%.0f" sim.avg_score));
      ("tenpai_rate", json_str (Printf.sprintf "%.1f" (sim.tenpai_rate *. 100.0)))
    ]

(* === hafu: 牌譜 === *)

let hand_to_hafu_short seat : string =
  match !game_ref with
  | None -> json_str ""
  | Some game ->
    let player = game.players.(seat) in
    json_str (Hafu.hand_to_short player.hand.tiles)

(** === ゲームプレイ補助 === *)

let get_wait_counts seat : string =
  match !game_ref with
  | None -> json_arr []
  | Some game ->
    let player = game.players.(seat) in
    let tiles = player.hand.tiles in
    let furo_count = List.length player.furo_list in
    let expected = (4 - furo_count) * 3 + 1 in
    let hand_13 =
      if List.length tiles = expected + 1 then
        match player.hand.tsumo with
        | Some t -> (match Mentsu.remove_one t tiles with Some r -> r | None -> tiles)
        | None -> tiles
      else if List.length tiles = expected then tiles
      else []
    in
    if hand_13 = [] then json_arr []
    else
      let waits = Hand.tenpai_tiles (Hand.make hand_13) in
      let visible_tiles = ref [] in
      Array.iter (fun (p : Player.t) ->
        visible_tiles := List.rev_append p.kawa !visible_tiles
      ) game.players;
      Array.iter (fun (p : Player.t) ->
        List.iter (fun f ->
          match f with
          | Player.Chi (t1, t2, t3) -> visible_tiles := t1 :: t2 :: t3 :: !visible_tiles
          | Player.Pon t -> visible_tiles := t :: t :: t :: !visible_tiles
          | Player.Minkan t | Player.Ankan t -> visible_tiles := t :: t :: t :: t :: !visible_tiles
        ) p.furo_list
      ) game.players;
      visible_tiles := List.rev_append tiles !visible_tiles;
      let count_visible tile =
        List.length (List.filter (fun t -> Tile.compare t tile = 0) !visible_tiles)
      in
      json_arr (List.map (fun w ->
        json_obj [("tile", tile_to_json w); ("remaining", json_int (max 0 (4 - count_visible w)))]
      ) waits)

let get_shanten seat : int =
  match !game_ref with
  | None -> -1
  | Some game ->
    let player = game.players.(seat) in
    Ai.estimate_shanten player.hand.tiles (List.length player.furo_list)

let get_danger_tiles seat : string =
  match !game_ref with
  | None -> json_arr []
  | Some game ->
    let player = game.players.(seat) in
    let tiles = player.hand.tiles in
    let riichi_exists = Array.exists (fun (p : Player.t) -> p.is_riichi) game.players in
    if not riichi_exists then json_arr []
    else
      let other_kawas = ref [] in
      Array.iteri (fun i (p : Player.t) ->
        if i <> seat then other_kawas := List.rev_append p.kawa !other_kawas
      ) game.players;
      let is_safe t = List.exists (fun k -> Tile.compare k t = 0) !other_kawas in
      let unique = Ai.unique_tiles tiles in
      json_arr (List.filter_map (fun t ->
        if is_safe t then None
        else
          let danger_level = match t with
            | Tile.Suhai (_, n) when n >= 3 && n <= 7 -> "high"
            | Tile.Suhai (_, n) when n = 2 || n = 8 -> "medium"
            | _ -> "low"
          in
          Some (json_obj [("tile", tile_to_json t); ("level", json_str danger_level)])
      ) unique)

let ai_difficulty_ref : Ai.difficulty ref = ref Ai.Normal
let ai_level_ref : int ref = ref 5

let set_ai_difficulty level =
  ai_difficulty_ref := (match level with
    | "easy" -> Ai.Easy
    | "hard" -> Ai.Hard
    | _ -> Ai.Normal)

let set_ai_level n =
  ai_level_ref := (max 1 (min 10 n));
  ai_difficulty_ref := (if n <= 3 then Ai.Easy else if n <= 6 then Ai.Normal else Ai.Hard)

(** AIのポン判断（レベル対応） *)
let ai_should_pon seat : bool =
  match !game_ref with
  | None -> false
  | Some game ->
    let level = !ai_level_ref in
    match game.last_discard with
    | None -> false
    | Some tile ->
      let player = game.players.(seat) in
      Ai.should_pon_leveled ~level player tile game.bakaze

(** AIのチー判断（レベル対応） *)
let ai_should_chi seat t1_kind t1_suit t1_num t2_kind t2_suit t2_num : bool =
  match !game_ref with
  | None -> false
  | Some game ->
    let level = !ai_level_ref in
    let player = game.players.(seat) in
    let t1 = tile_of_kind_suit_number t1_kind t1_suit t1_num in
    let t2 = tile_of_kind_suit_number t2_kind t2_suit t2_num in
    Ai.should_chi_leveled ~level player t1 t2

let ai_decide seat : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let player = game.players.(seat) in
    let level = !ai_level_ref in
    let other_kawas = Array.to_list (Array.mapi (fun i (p : Player.t) ->
      if i = seat then [] else List.rev p.kawa
    ) game.players) in
    let riichi_players = Array.to_list (Array.map (fun (p : Player.t) -> p.is_riichi) game.players) in
    let remaining = Wall.remaining game.wall in
    let visible = List.concat (other_kawas @ [List.rev player.kawa]) in
    match Ai.decide_leveled ~level ~other_kawas ~riichi_players ~remaining_tiles:remaining ~visible_tiles:visible player game.bakaze with
    | Ai.TsumoAgari -> json_obj [("action", json_str "tsumo")]
    | Ai.Discard tile ->
      json_obj [("action", json_str "discard"); ("tile", tile_to_json tile)]
    | Ai.DeclareRiichi tile ->
      json_obj [("action", json_str "riichi"); ("tile", tile_to_json tile)]
