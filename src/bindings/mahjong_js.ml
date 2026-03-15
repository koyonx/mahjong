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
  | Yaku.Chuuren -> "chuuren" | Yaku.Tenhou -> "tenhou" | Yaku.Chiihou -> "chiihou"

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
      Yaku.is_tsumo = true; is_riichi = player.is_riichi; is_double_riichi = false;
      is_ippatsu = false; is_tenhou = false; is_chiihou = false; is_menzen = Player.is_menzen player; is_haitei = false; is_houtei = false; dora_count = dora_n + uradora_n + aka_n;
      bakaze = game.bakaze; jikaze = player.jikaze;
    } in
    let is_oya = player.jikaze = Tile.Ton in
    match Scoring.score_hand player.hand.tiles ctx is_oya with
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
           ("winner_hand", hand_json);
           ("agari_tile", json_null);
           ("is_tsumo", json_bool true)
         ]
       | Error _ -> json_null)
    | None -> json_null

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
        Yaku.is_tsumo = false; is_riichi = player.is_riichi; is_double_riichi = false;
        is_ippatsu = false; is_tenhou = false; is_chiihou = false; is_menzen = Player.is_menzen player; is_haitei = false; is_houtei = false; dora_count = dora_n + uradora_n + aka_n;
        bakaze = game.bakaze; jikaze = player.jikaze;
      } in
      let is_oya = player.jikaze = Tile.Ton in
      (match Scoring.score_hand tiles ctx is_oya with
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
              ("winner_hand", hand_json);
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
    json_arr (List.map tile_to_json (Hand.tenpai_tiles player.hand))

let next_round oya_won : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let new_game = Game.next_round game oya_won in
    game_ref := Some new_game;
    game_state_to_json new_game

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

(** CPU AI の行動を決定 *)
let ai_decide seat : string =
  match !game_ref with
  | None -> json_null
  | Some game ->
    let player = game.players.(seat) in
    match Ai.decide player game.bakaze with
    | Ai.TsumoAgari -> json_obj [("action", json_str "tsumo")]
    | Ai.Discard tile ->
      json_obj [("action", json_str "discard"); ("tile", tile_to_json tile)]
    | Ai.DeclareRiichi tile ->
      json_obj [("action", json_str "riichi"); ("tile", tile_to_json tile)]
