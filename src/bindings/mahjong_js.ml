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

let yaku_to_json (y : Yaku.yaku) : string =
  json_obj [("name", json_str (Yaku.name_of_yaku y)); ("han", json_int (Yaku.han_of_yaku y))]

let payment_to_json (p : Scoring.payment) : string =
  match p with
  | Scoring.Ron n ->
    json_obj [("kind", json_str "ron"); ("ron", json_int n)]
  | Scoring.Tsumo_oya n ->
    json_obj [("kind", json_str "tsumo_oya"); ("ko_pay", json_int n)]
  | Scoring.Tsumo_ko (oya, ko) ->
    json_obj [("kind", json_str "tsumo_ko"); ("oya_pay", json_int oya); ("ko_pay", json_int ko)]

let player_to_json (p : Player.t) : string =
  let hand = json_arr (List.map tile_to_json p.hand.tiles) in
  let kawa = json_arr (List.rev_map tile_to_json p.kawa) in
  let jikaze_str = match p.jikaze with
    | Tile.Ton -> "ton" | Tile.Nan -> "nan"
    | Tile.Sha -> "sha" | Tile.Pei -> "pei"
    | _ -> "ton"
  in
  json_obj [
    ("hand", hand); ("kawa", kawa); ("score", json_int p.score);
    ("is_riichi", json_bool p.is_riichi); ("is_menzen", json_bool (Player.is_menzen p));
    ("jikaze", json_str jikaze_str)
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
  let dora = json_arr (List.map tile_to_json (Wall.dora_indicators game.wall 0)) in
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
    let ctx = {
      Yaku.is_tsumo = true; is_riichi = player.is_riichi;
      is_ippatsu = false; is_tenhou = false; is_chiihou = false;
      bakaze = game.bakaze; jikaze = player.jikaze;
    } in
    let is_oya = player.jikaze = Tile.Ton in
    match Scoring.score_hand player.hand.tiles ctx is_oya with
    | Some result ->
      (match Game.tsumo_agari game with
       | Ok new_game ->
         game_ref := Some new_game;
         json_obj [
           ("state", game_state_to_json new_game);
           ("yakus", json_arr (List.map yaku_to_json result.yakus));
           ("han", json_int result.han_detail);
           ("fu", json_int result.fu_detail);
           ("total", json_int result.total);
           ("payment", payment_to_json result.payments)
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
      let ctx = {
        Yaku.is_tsumo = false; is_riichi = player.is_riichi;
        is_ippatsu = false; is_tenhou = false; is_chiihou = false;
        bakaze = game.bakaze; jikaze = player.jikaze;
      } in
      let is_oya = player.jikaze = Tile.Ton in
      (match Scoring.score_hand tiles ctx is_oya with
       | Some result ->
         (match Game.ron game seat with
          | Ok new_game ->
            game_ref := Some new_game;
            json_obj [
              ("state", game_state_to_json new_game);
              ("yakus", json_arr (List.map yaku_to_json result.yakus));
              ("han", json_int result.han_detail);
              ("fu", json_int result.fu_detail);
              ("total", json_int result.total);
              ("payment", payment_to_json result.payments)
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
