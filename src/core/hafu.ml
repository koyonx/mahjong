(* 牌譜（ハフ）パーサーと生成 — 対局記録の解析 *)

(* 牌譜のアクション *)
type action =
  | Deal of int * Tile.tile list         (** 配牌: seat * 手牌 *)
  | Draw of int * Tile.tile              (** ツモ: seat * 牌 *)
  | Discard of int * Tile.tile           (** 打牌: seat * 牌 *)
  | Pon of int * Tile.tile * int         (** ポン: seat * 牌 * from_seat *)
  | Chi of int * Tile.tile * Tile.tile * Tile.tile * int  (** チー: seat * t1 * t2 * taken * from_seat *)
  | Ankan of int * Tile.tile             (** 暗槓: seat * 牌 *)
  | Minkan of int * Tile.tile * int      (** 明槓: seat * 牌 * from_seat *)
  | Kakan of int * Tile.tile             (** 加槓: seat * 牌 *)
  | Riichi of int                        (** リーチ宣言: seat *)
  | Tsumo_agari of int                   (** ツモ和了: seat *)
  | Ron_agari of int * int               (** ロン: winner * loser *)
  | Ryuukyoku                            (** 流局 *)
  | Round_start of Tile.jihai * int * int  (** 局開始: bakaze * kyoku * honba *)

(* 局の牌譜 *)
type round_record = {
  bakaze : Tile.jihai;
  kyoku : int;
  honba : int;
  dora_indicators : Tile.tile list;
  actions : action list;
  result : string;            (** "tsumo" / "ron" / "ryuukyoku" *)
  winner : int option;
  scores_before : int array;
  scores_after : int array;
}

(* 対局全体の牌譜 *)
type game_record = {
  date : string;
  player_names : string array;
  rounds : round_record list;
  final_scores : int array;
}

(* === 牌の文字列表現 === *)

(* 牌を短縮表記に変換: 1m, 5p, 3s, 1z等 *)
let tile_to_short (t : Tile.tile) : string =
  Tile.to_string t

(* 短縮表記から牌に変換 *)
let tile_of_short (s : string) : Tile.tile option =
  if String.length s < 2 then None
  else
    let n = Char.code s.[0] - Char.code '0' in
    let suit = s.[1] in
    if n < 1 || n > 9 then None
    else match suit with
    | 'm' -> Some (Tile.Suhai (Tile.Manzu, n))
    | 'p' -> Some (Tile.Suhai (Tile.Pinzu, n))
    | 's' -> Some (Tile.Suhai (Tile.Souzu, n))
    | 'z' -> (match n with
      | 1 -> Some (Tile.Jihai Tile.Ton)
      | 2 -> Some (Tile.Jihai Tile.Nan)
      | 3 -> Some (Tile.Jihai Tile.Sha)
      | 4 -> Some (Tile.Jihai Tile.Pei)
      | 5 -> Some (Tile.Jihai Tile.Haku)
      | 6 -> Some (Tile.Jihai Tile.Hatsu)
      | 7 -> Some (Tile.Jihai Tile.Chun)
      | _ -> None)
    | _ -> None

(* 手牌を短縮表記に変換: "1m2m3m4p5p6p..." *)
let hand_to_short (tiles : Tile.tile list) : string =
  let sorted = List.sort Tile.compare tiles in
  String.concat "" (List.map tile_to_short sorted)

(* 短縮表記から手牌に変換 *)
let hand_of_short (s : string) : Tile.tile list =
  let tiles = ref [] in
  let i = ref 0 in
  while !i < String.length s - 1 do
    let sub = String.sub s !i 2 in
    (match tile_of_short sub with
     | Some t -> tiles := t :: !tiles
     | None -> ());
    i := !i + 2
  done;
  List.rev !tiles

(* === アクションのシリアライズ === *)

let action_to_string = function
  | Deal (seat, tiles) ->
    Printf.sprintf "D%d:%s" seat (hand_to_short tiles)
  | Draw (seat, tile) ->
    Printf.sprintf "T%d:%s" seat (tile_to_short tile)
  | Discard (seat, tile) ->
    Printf.sprintf "d%d:%s" seat (tile_to_short tile)
  | Pon (seat, tile, from) ->
    Printf.sprintf "P%d:%s:%d" seat (tile_to_short tile) from
  | Chi (seat, t1, t2, taken, from) ->
    Printf.sprintf "C%d:%s%s%s:%d" seat
      (tile_to_short t1) (tile_to_short t2) (tile_to_short taken) from
  | Ankan (seat, tile) ->
    Printf.sprintf "K%d:%s" seat (tile_to_short tile)
  | Minkan (seat, tile, from) ->
    Printf.sprintf "M%d:%s:%d" seat (tile_to_short tile) from
  | Kakan (seat, tile) ->
    Printf.sprintf "A%d:%s" seat (tile_to_short tile)
  | Riichi seat ->
    Printf.sprintf "R%d" seat
  | Tsumo_agari seat ->
    Printf.sprintf "W%d:tsumo" seat
  | Ron_agari (winner, loser) ->
    Printf.sprintf "W%d:ron:%d" winner loser
  | Ryuukyoku ->
    "RYUUKYOKU"
  | Round_start (bakaze, kyoku, honba) ->
    let bk = match bakaze with
      | Tile.Ton -> "E" | Tile.Nan -> "S" | Tile.Sha -> "W" | Tile.Pei -> "N"
      | _ -> "E"
    in
    Printf.sprintf "START:%s%d:%d" bk kyoku honba

(* 局の牌譜を文字列に変換 *)
let round_to_string (record : round_record) : string =
  String.concat "\n" (List.map action_to_string record.actions)

(* 対局全体の牌譜を文字列に変換 *)
let game_to_string (record : game_record) : string =
  let header = Printf.sprintf "# %s\n# %s\n"
    record.date
    (String.concat "," (Array.to_list record.player_names))
  in
  let rounds = List.mapi (fun i r ->
    Printf.sprintf "## Round %d\n%s\n## Result: %s\n## Scores: %s"
      (i + 1)
      (round_to_string r)
      r.result
      (String.concat "," (Array.to_list (Array.map string_of_int r.scores_after)))
  ) record.rounds in
  header ^ String.concat "\n\n" rounds

(* === 牌譜からの統計分析 === *)

type game_stats = {
  total_rounds : int;
  wins_per_player : int array;
  deal_ins_per_player : int array;     (** 放銃回数 *)
  riichi_count_per_player : int array;
  tsumo_count : int;
  ron_count : int;
  ryuukyoku_count : int;
  avg_winning_score : float;
}

let analyze_game_record (record : game_record) : game_stats =
  let wins = Array.make 4 0 in
  let deal_ins = Array.make 4 0 in
  let riichis = Array.make 4 0 in
  let tsumo_n = ref 0 in
  let ron_n = ref 0 in
  let ryuu_n = ref 0 in
  let total_win_score = ref 0 in
  let win_count = ref 0 in

  List.iter (fun round ->
    List.iter (fun act ->
      match act with
      | Riichi seat -> riichis.(seat) <- riichis.(seat) + 1
      | Tsumo_agari seat ->
        wins.(seat) <- wins.(seat) + 1;
        incr tsumo_n;
        incr win_count;
        (* スコア差分を計算 *)
        let diff = round.scores_after.(seat) - round.scores_before.(seat) in
        total_win_score := !total_win_score + diff
      | Ron_agari (winner, loser) ->
        wins.(winner) <- wins.(winner) + 1;
        deal_ins.(loser) <- deal_ins.(loser) + 1;
        incr ron_n;
        incr win_count;
        let diff = round.scores_after.(winner) - round.scores_before.(winner) in
        total_win_score := !total_win_score + diff
      | Ryuukyoku -> incr ryuu_n
      | _ -> ()
    ) round.actions
  ) record.rounds;

  {
    total_rounds = List.length record.rounds;
    wins_per_player = wins;
    deal_ins_per_player = deal_ins;
    riichi_count_per_player = riichis;
    tsumo_count = !tsumo_n;
    ron_count = !ron_n;
    ryuukyoku_count = !ryuu_n;
    avg_winning_score = if !win_count > 0 then
      float_of_int !total_win_score /. float_of_int !win_count else 0.0;
  }
