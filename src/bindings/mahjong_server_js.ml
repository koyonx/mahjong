(** サーバー用Melangeバインディング - マルチルーム対応 *)

open Mahjong_core

(** ルームごとのゲーム状態を保持 *)
let rooms : (string, Game.round) Hashtbl.t = Hashtbl.create 16

(** === JSON エンコーダ（mahjong_js.mlと共通） === *)

let json_str s = "\"" ^ s ^ "\""
let json_int n = string_of_int n
let json_bool b = if b then "true" else "false"
let json_null = "null"
let json_obj fields =
  "{" ^ String.concat "," (List.map (fun (k, v) -> "\"" ^ k ^ "\":" ^ v) fields) ^ "}"
let json_arr items =
  "[" ^ String.concat "," items ^ "]"

let tile_to_json (tile : Tile.tile) : string =
  match tile with
  | Tile.Suhai (suit, n) ->
    let suit_str = match suit with
      | Tile.Manzu -> "manzu" | Tile.Pinzu -> "pinzu" | Tile.Souzu -> "souzu"
    in
    json_obj [("kind", json_str "suhai"); ("suit", json_str suit_str);
              ("number", json_int n); ("label", json_str (Tile.to_string tile))]
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
              ("number", json_int number); ("label", json_str (Tile.to_string tile))]

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

(** プレイヤー状態をJSON変換（手牌を見せるかどうか制御） *)
let player_to_json (p : Player.t) (show_hand : bool) : string =
  let (hand, tsumo_tile) =
    if show_hand then
      match p.hand.tsumo with
      | Some t ->
        (match Mentsu.remove_one t p.hand.tiles with
         | Some rest -> (json_arr (List.map tile_to_json (List.sort Tile.compare rest)), tile_to_json t)
         | None -> (json_arr (List.map tile_to_json (List.sort Tile.compare p.hand.tiles)), json_null))
      | None -> (json_arr (List.map tile_to_json (List.sort Tile.compare p.hand.tiles)), json_null)
    else (json_null, json_null)
  in
  let hand_count = json_int (Hand.count p.hand) in
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
    ("hand", hand); ("tsumo", tsumo_tile); ("hand_count", hand_count);
    ("furo", furo); ("kawa", kawa); ("score", json_int p.score);
    ("is_riichi", json_bool p.is_riichi);
    ("is_menzen", json_bool (Player.is_menzen p));
    ("jikaze", json_str jikaze_str)
  ]

(** ゲーム状態をJSON変換（指定seat用にフィルタ） *)
let game_state_to_json_for_seat (game : Game.round) (viewer_seat : int) : string =
  let players = json_arr (
    Array.to_list (Array.mapi (fun i p ->
      player_to_json p (i = viewer_seat)
    ) game.players)
  ) in
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

(** 全員の手牌を見せるバージョン（和了時等） *)
let game_state_to_json_full (game : Game.round) : string =
  let players = json_arr (
    Array.to_list (Array.map (fun p -> player_to_json p true) game.players)
  ) in
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

(** === ルーム管理API === *)

let create_room room_id : string =
  let game = Game.start () in
  Hashtbl.replace rooms room_id game;
  json_obj [("room_id", json_str room_id); ("ok", json_bool true)]

let destroy_room room_id =
  Hashtbl.remove rooms room_id

let start_game room_id : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_null
  | Some game ->
    match Game.draw_tile game with
    | Ok new_game ->
      Hashtbl.replace rooms room_id new_game;
      json_obj [("ok", json_bool true)]
    | Error _ ->
      Hashtbl.replace rooms room_id game;
      json_obj [("ok", json_bool true)]

let get_state room_id viewer_seat : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_null
  | Some game -> game_state_to_json_for_seat game viewer_seat

let get_current_turn room_id : int =
  match Hashtbl.find_opt rooms room_id with
  | None -> -1
  | Some game -> game.current_turn

let get_phase room_id : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_str "unknown"
  | Some game ->
    match game.phase with
    | Game.WaitingDraw -> json_str "waiting_draw"
    | Game.WaitingDiscard -> json_str "waiting_discard"
    | Game.WaitingCall -> json_str "waiting_call"
    | Game.RoundEnd -> json_str "round_end"
    | Game.GameEnd -> json_str "game_end"

let draw_tile room_id : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_null
  | Some game ->
    match Game.draw_tile game with
    | Ok new_game ->
      Hashtbl.replace rooms room_id new_game;
      json_obj [("ok", json_bool true)]
    | Error _ -> json_null

let discard_tile room_id kind suit number : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_null
  | Some game ->
    let tile = tile_of_kind_suit_number kind suit number in
    match Game.discard_tile game tile with
    | Ok new_game ->
      Hashtbl.replace rooms room_id new_game;
      json_obj [("ok", json_bool true)]
    | Error _ -> json_null

let advance_turn room_id : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_null
  | Some game ->
    let new_game = Game.advance_turn game in
    Hashtbl.replace rooms room_id new_game;
    json_obj [("ok", json_bool true)]

let check_tsumo room_id : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_null
  | Some game ->
    let player = game.players.(game.current_turn) in
    let ctx = {
      Yaku.is_tsumo = true; is_riichi = player.is_riichi; is_double_riichi = false;
      is_ippatsu = false; is_tenhou = false; is_chiihou = false; is_menzen = Player.is_menzen player; is_haitei = false; is_houtei = false; dora_count = 0;
      bakaze = game.bakaze; jikaze = player.jikaze;
    } in
    let is_oya = player.jikaze = Tile.Ton in
    match Scoring.score_hand ~furo_count:(List.length player.furo_list) ~furo_mentsu:player.furo_list player.hand.tiles ctx is_oya with
    | Some result ->
      (match Game.tsumo_agari game with
       | Ok new_game ->
         Hashtbl.replace rooms room_id new_game;
         json_obj [
           ("state", game_state_to_json_full new_game);
           ("yakus", json_arr (List.map yaku_to_json result.yakus));
           ("han", json_int result.han_detail);
           ("fu", json_int result.fu_detail);
           ("total", json_int result.total);
           ("payment", payment_to_json result.payments);
           ("winner", json_int game.current_turn)
         ]
       | Error _ -> json_null)
    | None -> json_null

let check_ron room_id seat : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_null
  | Some game ->
    match game.last_discard with
    | None -> json_null
    | Some tile ->
      let player = game.players.(seat) in
      let tiles = tile :: player.hand.tiles in
      let ctx = {
        Yaku.is_tsumo = false; is_riichi = player.is_riichi; is_double_riichi = false;
        is_ippatsu = false; is_tenhou = false; is_chiihou = false; is_menzen = Player.is_menzen player; is_haitei = false; is_houtei = false; dora_count = 0;
        bakaze = game.bakaze; jikaze = player.jikaze;
      } in
      let is_oya = player.jikaze = Tile.Ton in
      (match Scoring.score_hand ~furo_count:(List.length player.furo_list) ~furo_mentsu:player.furo_list tiles ctx is_oya with
       | Some result ->
         (match Game.ron game seat with
          | Ok new_game ->
            Hashtbl.replace rooms room_id new_game;
            json_obj [
              ("state", game_state_to_json_full new_game);
              ("yakus", json_arr (List.map yaku_to_json result.yakus));
              ("han", json_int result.han_detail);
              ("fu", json_int result.fu_detail);
              ("total", json_int result.total);
              ("payment", payment_to_json result.payments);
              ("winner", json_int seat)
            ]
          | Error _ -> json_null)
       | None -> json_null)

let declare_riichi room_id : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_null
  | Some game ->
    match Game.declare_riichi game with
    | Ok new_game ->
      Hashtbl.replace rooms room_id new_game;
      json_obj [("ok", json_bool true)]
    | Error _ -> json_null

let ai_decide room_id seat : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_null
  | Some game ->
    let player = game.players.(seat) in
    match Ai.decide player game.bakaze with
    | Ai.TsumoAgari -> json_obj [("action", json_str "tsumo")]
    | Ai.Discard tile ->
      json_obj [("action", json_str "discard"); ("tile", tile_to_json tile)]
    | Ai.DeclareRiichi tile ->
      json_obj [("action", json_str "riichi"); ("tile", tile_to_json tile)]

let get_tenpai room_id : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_arr []
  | Some game ->
    let player = game.players.(game.current_turn) in
    json_arr (List.map tile_to_json (Hand.tenpai_tiles player.hand))

(** ポン可否判定（副作用なし） *)
let can_pon room_id seat : bool =
  match Hashtbl.find_opt rooms room_id with
  | None -> false
  | Some game ->
    match game.last_discard with
    | None -> false
    | Some tile ->
      let player = game.players.(seat) in
      let count = List.length (List.filter (fun t -> Tile.compare t tile = 0) player.hand.tiles) in
      count >= 2

(** ポン実行 *)
let do_pon room_id seat : string =
  match Hashtbl.find_opt rooms room_id with
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
        Hashtbl.replace rooms room_id new_game;
        json_obj [("ok", json_bool true)]
      | Error _ -> json_null

(** チー可否判定: 上家からのみ *)
let can_chi room_id seat : string =
  match Hashtbl.find_opt rooms room_id with
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
             (* n-2, n-1, tile *)
             if n >= 3 then begin
               let t1 = Tile.Suhai (suit, n - 2) in
               let t2 = Tile.Suhai (suit, n - 1) in
               if List.exists (fun t -> Tile.compare t t1 = 0) hand &&
                  List.exists (fun t -> Tile.compare t t2 = 0) hand then
                 results := json_arr [tile_to_json t1; tile_to_json t2] :: !results
             end;
             (* n-1, tile, n+1 *)
             if n >= 2 && n <= 8 then begin
               let t1 = Tile.Suhai (suit, n - 1) in
               let t2 = Tile.Suhai (suit, n + 1) in
               if List.exists (fun t -> Tile.compare t t1 = 0) hand &&
                  List.exists (fun t -> Tile.compare t t2 = 0) hand then
                 results := json_arr [tile_to_json t1; tile_to_json t2] :: !results
             end;
             (* tile, n+1, n+2 *)
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
let do_chi room_id seat t1_kind t1_suit t1_num t2_kind t2_suit t2_num : string =
  match Hashtbl.find_opt rooms room_id with
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
        Hashtbl.replace rooms room_id new_game;
        json_obj [("ok", json_bool true)]
      | Error _ -> json_null

let next_round room_id oya_won was_agari : string =
  match Hashtbl.find_opt rooms room_id with
  | None -> json_null
  | Some game ->
    let new_game = Game.next_round ~was_agari game oya_won in
    Hashtbl.replace rooms room_id new_game;
    json_obj [("ok", json_bool true)]
