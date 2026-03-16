(** ゲーム進行管理 *)

(** 局の風 *)
type bakaze = Tile.jihai

(** ゲームのフェーズ *)
type phase =
  | WaitingDraw        (** ツモ待ち *)
  | WaitingDiscard      (** 打牌待ち *)
  | WaitingCall         (** 鳴き判定待ち *)
  | RoundEnd            (** 局終了 *)
  | GameEnd             (** ゲーム終了 *)

(** 局の状態 *)
type round = {
  bakaze : bakaze;             (** 場風 *)
  kyoku : int;                 (** 局数 (1-4) *)
  honba : int;                 (** 本場 *)
  riichi_sticks : int;         (** リーチ棒の数 *)
  seat_offset : int;           (** 席順オフセット（ランダム化用） *)
  kan_count : int;             (** カン回数（ドラ増加用） *)
  wall : Wall.t;               (** 牌山 *)
  players : Player.t array;    (** プレイヤー *)
  current_turn : int;          (** 現在の手番 (0-3) *)
  phase : phase;               (** フェーズ *)
  last_discard : Tile.tile option;       (** 直前の捨て牌 *)
  last_discard_player : int option;      (** 直前の捨て牌のプレイヤー *)
  first_turns : bool array;              (** 各プレイヤーの最初のターンか（ダブルリーチ判定用） *)
  no_calls_yet : bool;                   (** まだ鳴きが入っていないか *)
}

(** 自風を局数から決定 *)
let jikaze_of_seat (kyoku : int) (seat : int) : Tile.jihai =
  let pos = (seat - (kyoku - 1) + 4) mod 4 in
  match pos with
  | 0 -> Tile.Ton
  | 1 -> Tile.Nan
  | 2 -> Tile.Sha
  | 3 -> Tile.Pei
  | _ -> Tile.Ton

(** 赤ドラ情報 *)
type aka_info = {
  count : int;
  manzu : bool;
  pinzu : bool;
  souzu : bool;
}

let empty_aka = { count = 0; manzu = false; pinzu = false; souzu = false }

let add_aka (info : aka_info) (tile : Tile.tile) : aka_info =
  { count = info.count + 1;
    manzu = info.manzu || (match tile with Tile.Suhai (Tile.Manzu, 5) -> true | _ -> false);
    pinzu = info.pinzu || (match tile with Tile.Suhai (Tile.Pinzu, 5) -> true | _ -> false);
    souzu = info.souzu || (match tile with Tile.Suhai (Tile.Souzu, 5) -> true | _ -> false);
  }

(** 配牌（赤ドラ情報も返す） *)
let deal (wall : Wall.t) : (Tile.tile list array * aka_info array * Wall.t) =
  let hands = Array.make 4 [] in
  let aka_infos = Array.make 4 empty_aka in
  let w = ref wall in
  for round_num = 0 to 2 do
    ignore round_num;
    for seat = 0 to 3 do
      for _ = 0 to 3 do
        match Wall.draw !w with
        | Some (tile, is_red, new_wall) ->
          hands.(seat) <- tile :: hands.(seat);
          if is_red then aka_infos.(seat) <- add_aka aka_infos.(seat) tile;
          w := new_wall
        | None -> ()
      done
    done
  done;
  for seat = 0 to 3 do
    match Wall.draw !w with
    | Some (tile, is_red, new_wall) ->
      hands.(seat) <- tile :: hands.(seat);
      if is_red then aka_infos.(seat) <- add_aka aka_infos.(seat) tile;
      w := new_wall
    | None -> ()
  done;
  (hands, aka_infos, !w)

(** 新しい局を開始 *)
let new_round (bakaze : bakaze) (kyoku : int) (honba : int) (riichi_sticks : int)
    (seat_offset : int) (scores : int array) : round =
  let wall = Wall.create () in
  let (dealt_hands, aka_infos, wall_after_deal) = deal wall in
  (* 親(東家)のseat: kyokuとoffsetで決定 *)
  let oya = ((kyoku - 1) + seat_offset) mod 4 in
  let players = Array.init 4 (fun i ->
    let dist = (i - oya + 4) mod 4 in
    let jikaze = match dist with
      | 0 -> Tile.Ton | 1 -> Tile.Nan | 2 -> Tile.Sha | _ -> Tile.Pei
    in
    let p = Player.create jikaze in
    let ai = aka_infos.(i) in
    { p with hand = Hand.make dealt_hands.(i); score = scores.(i);
      aka_count = ai.count; aka_manzu = ai.manzu; aka_pinzu = ai.pinzu; aka_souzu = ai.souzu }
  ) in
  {
    bakaze;
    kyoku;
    honba;
    riichi_sticks;
    seat_offset;
    kan_count = 0;
    wall = wall_after_deal;
    players;
    current_turn = oya;
    phase = WaitingDraw;
    last_discard = None;
    last_discard_player = None;
    first_turns = [| true; true; true; true |];
    no_calls_yet = true;
  }

(** ゲーム開始（席順ランダム、東1局から） *)
let start () : round =
  let offset = Random.int 4 in
  new_round Tile.Ton 1 0 0 offset [|25000; 25000; 25000; 25000|]

(** ツモを実行 *)
let draw_tile (game : round) : (round, string) result =
  if game.phase <> WaitingDraw then Error "ツモのフェーズではありません"
  else
    match Wall.draw game.wall with
    | None -> Ok { game with phase = RoundEnd }  (* 流局 *)
    | Some (tile, is_red, new_wall) ->
      let player = game.players.(game.current_turn) in
      match Player.tsumo tile player with
      | Ok new_player ->
        let new_player = if is_red then
          { new_player with
            aka_count = new_player.aka_count + 1;
            aka_manzu = new_player.aka_manzu || (match tile with Tile.Suhai (Tile.Manzu, 5) -> true | _ -> false);
            aka_pinzu = new_player.aka_pinzu || (match tile with Tile.Suhai (Tile.Pinzu, 5) -> true | _ -> false);
            aka_souzu = new_player.aka_souzu || (match tile with Tile.Suhai (Tile.Souzu, 5) -> true | _ -> false);
          }
        else new_player in
        let players = Array.copy game.players in
        players.(game.current_turn) <- new_player;
        Ok { game with wall = new_wall; players; phase = WaitingDiscard }
      | Error e -> Error e

(** 打牌を実行 *)
let discard_tile (game : round) (tile : Tile.tile) : (round, string) result =
  if game.phase <> WaitingDiscard then Error "打牌のフェーズではありません"
  else
    let player = game.players.(game.current_turn) in
    match Player.discard tile player with
    | Ok new_player ->
      let players = Array.copy game.players in
      players.(game.current_turn) <- new_player;
      let ft = Array.copy game.first_turns in
      ft.(game.current_turn) <- false;
      Ok { game with
           players;
           phase = WaitingCall;
           last_discard = Some tile;
           last_discard_player = Some game.current_turn;
           first_turns = ft }
    | Error e -> Error e

(** 鳴きがなければ次の手番に進む *)
let advance_turn (game : round) : round =
  let next = (game.current_turn + 1) mod 4 in
  { game with current_turn = next; phase = WaitingDraw }

(** 振聴チェック: 捨て牌にある牌でロンできない *)
let is_furiten (player : Player.t) (tile : Tile.tile) : bool =
  (* 自分の河に同じ牌があれば振聴 *)
  List.exists (fun t -> Tile.compare t tile = 0) player.kawa

(** 海底かどうか（残り0枚） *)
let is_haitei (game : round) : bool =
  Wall.remaining game.wall = 0

(** ロン和了の処理 *)
let ron (game : round) (winner : int) : (round, string) result =
  match game.last_discard with
  | None -> Error "ロンできる捨て牌がありません"
  | Some tile ->
    let player = game.players.(winner) in
    (* 振聴チェック *)
    if is_furiten player tile then Error "振聴のためロンできません"
    else
    let tiles = tile :: player.hand.tiles in
    let dora_count = Wall.count_dora game.wall game.kan_count tiles in
    let uradora_count = if player.is_riichi then Wall.count_uradora game.wall game.kan_count tiles else 0 in
    let total_dora = dora_count + uradora_count + player.aka_count in
    let ctx = {
      Yaku.is_tsumo = false;
      is_riichi = player.is_riichi;
      is_double_riichi = player.is_double_riichi;
      is_ippatsu = player.is_ippatsu;
      is_tenhou = false;
      is_chiihou = false;
      is_menzen = Player.is_menzen player;
      is_haitei = false;
      is_houtei = is_haitei game;
      dora_count = total_dora;
      agari_tile = Some tile;
      bakaze = game.bakaze;
      jikaze = player.jikaze;
    } in
    let is_oya = player.jikaze = Tile.Ton in
    let furo_count = List.length player.furo_list in
    let furo_mentsu = player.furo_list in
    match Scoring.score_hand ~furo_count ~furo_mentsu tiles ctx is_oya with
    | None -> Error "役がありません"
    | Some result ->
      let loser = match game.last_discard_player with Some p -> p | None -> 0 in
      let players = Array.copy game.players in
      let total_with_honba = result.total + game.honba * 300 in
      let total_with_riichi = total_with_honba + game.riichi_sticks * 1000 in
      players.(winner) <- Player.add_score total_with_riichi players.(winner);
      players.(loser) <- Player.add_score (-total_with_honba) players.(loser);
      Ok { game with players; phase = RoundEnd; riichi_sticks = 0 }

(** ツモ和了の処理 *)
let tsumo_agari (game : round) : (round, string) result =
  let player = game.players.(game.current_turn) in
  let dora_count = Wall.count_dora game.wall game.kan_count player.hand.tiles in
  let uradora_count = if player.is_riichi then Wall.count_uradora game.wall game.kan_count player.hand.tiles else 0 in
  let total_dora = dora_count + uradora_count + player.aka_count in
  let is_first = game.first_turns.(game.current_turn) && game.no_calls_yet in
  let is_oya_player = player.jikaze = Tile.Ton in
  let ctx = {
    Yaku.is_tsumo = true;
    is_riichi = player.is_riichi;
    is_double_riichi = player.is_double_riichi;
    is_ippatsu = player.is_ippatsu;
    is_tenhou = is_first && is_oya_player;
    is_chiihou = is_first && not is_oya_player;
    is_menzen = Player.is_menzen player;
    is_haitei = is_haitei game;
    is_houtei = false;
    dora_count = total_dora;
    agari_tile = player.hand.tsumo;
    bakaze = game.bakaze;
    jikaze = player.jikaze;
  } in
  let is_oya = player.jikaze = Tile.Ton in
  let furo_count = List.length player.furo_list in
  let furo_mentsu = player.furo_list in
  match Scoring.score_hand ~furo_count ~furo_mentsu player.hand.tiles ctx is_oya with
  | None -> Error "役がありません"
  | Some result ->
    let players = Array.copy game.players in
    let winner = game.current_turn in
    (match result.payments with
     | Scoring.Tsumo_oya ko_pay ->
       let total_each = ko_pay + game.honba * 100 in
       for i = 0 to 3 do
         if i <> winner then
           players.(i) <- Player.add_score (-total_each) players.(i)
       done;
       players.(winner) <- Player.add_score (total_each * 3 + game.riichi_sticks * 1000) players.(winner)
     | Scoring.Tsumo_ko (oya_pay, ko_pay) ->
       for i = 0 to 3 do
         if i <> winner then begin
           let pay = (if players.(i).jikaze = Tile.Ton then oya_pay else ko_pay) + game.honba * 100 in
           players.(i) <- Player.add_score (-pay) players.(i)
         end
       done;
       let total_in = (oya_pay + ko_pay * 2) + game.honba * 300 + game.riichi_sticks * 1000 in
       players.(winner) <- Player.add_score total_in players.(winner)
     | Scoring.Ron _ -> ());  (* ツモなのにロンにはならない *)
    Ok { game with players; phase = RoundEnd; riichi_sticks = 0 }

(** リーチ宣言 *)
let declare_riichi (game : round) : (round, string) result =
  let player = game.players.(game.current_turn) in
  match Player.declare_riichi player with
  | Ok new_player ->
    (* ダブルリーチ: 最初のターンかつ鳴きなし *)
    let is_double = game.first_turns.(game.current_turn) && game.no_calls_yet in
    let new_player = { new_player with is_double_riichi = is_double } in
    let players = Array.copy game.players in
    players.(game.current_turn) <- new_player;
    Ok { game with players; riichi_sticks = game.riichi_sticks + 1 }
  | Error e -> Error e

(** テンパイ判定（副露考慮） *)
let is_tenpai (player : Player.t) : bool =
  let furo_count = List.length player.furo_list in
  let expected = 13 - furo_count * 3 in
  let n = List.length player.hand.tiles in
  if n <> expected then false
  else
    (* 全候補牌を加えてみて和了になるものがあるか *)
    let suits = [Tile.Manzu; Tile.Pinzu; Tile.Souzu] in
    let numbers = [1; 2; 3; 4; 5; 6; 7; 8; 9] in
    let jihais = [Tile.Ton; Tile.Nan; Tile.Sha; Tile.Pei; Tile.Haku; Tile.Hatsu; Tile.Chun] in
    let candidates =
      List.concat_map (fun s -> List.map (fun n -> Tile.Suhai (s, n)) numbers) suits @
      List.map (fun j -> Tile.Jihai j) jihais
    in
    List.exists (fun t ->
      Mentsu.find_agari_patterns_furo (List.sort Tile.compare (t :: player.hand.tiles)) furo_count <> []
    ) candidates

(** 流局時のテンパイ/ノーテン精算 *)
let ryuukyoku_payments (game : round) : round =
  let players = Array.copy game.players in
  let tenpai_count = Array.fold_left (fun acc (p : Player.t) ->
    if is_tenpai p then acc + 1 else acc
  ) 0 players in
  if tenpai_count > 0 && tenpai_count < 4 then begin
    (* テンパイ者が受け取る合計3000点をノーテン者が払う *)
    let pay_per_noten = 3000 / (4 - tenpai_count) in
    let recv_per_tenpai = 3000 / tenpai_count in
    Array.iteri (fun i (p : Player.t) ->
      if is_tenpai p then
        players.(i) <- Player.add_score recv_per_tenpai p
      else
        players.(i) <- Player.add_score (-pay_per_noten) p
    ) players
  end;
  { game with players }

(** 次の局に進む *)
(* oya_won: 親が和了したか。子の和了ならfalseだが流局もfalse。
   区別のために was_agari パラメータで和了があったかを示す *)
let next_round ?(was_agari=false) (game : round) (oya_won : bool) : round =
  (* 流局時（和了なし）のみテンパイ精算 *)
  let game =
    if not was_agari && not oya_won && game.phase = RoundEnd then
      ryuukyoku_payments game
    else game
  in
  let scores = Array.map (fun (p : Player.t) -> p.score) game.players in
  let offset = game.seat_offset in
  let oya_seat = ((game.kyoku - 1) + offset) mod 4 in
  let oya_tenpai = is_tenpai game.players.(oya_seat) in
  if oya_won || oya_tenpai then
    (* 親の連荘 *)
    new_round game.bakaze game.kyoku (game.honba + 1) game.riichi_sticks offset scores
  else
    let next_kyoku = game.kyoku + 1 in
    if next_kyoku > 4 then
      match game.bakaze with
      | Tile.Ton ->
        new_round Tile.Nan 1 0 game.riichi_sticks offset scores
      | _ ->
        { game with phase = GameEnd }
    else
      new_round game.bakaze next_kyoku 0 game.riichi_sticks offset scores
