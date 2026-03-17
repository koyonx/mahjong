(* モンテカルロシミュレーション — 勝率・期待点数の推定 *)

(* シミュレーション結果 *)
type sim_result = {
  trials : int;              (** 試行回数 *)
  tsumo_wins : int;          (** ツモ和了回数 *)
  win_rate : float;          (** 和了率 *)
  avg_score : float;         (** 平均獲得点数（和了時） *)
  tenpai_rate : float;       (** テンパイ到達率 *)
}

(* 全34種の牌リスト *)
let all_tile_types : Tile.tile list =
  let suits = [Tile.Manzu; Tile.Pinzu; Tile.Souzu] in
  let numbers = [1; 2; 3; 4; 5; 6; 7; 8; 9] in
  let jihais = [Tile.Ton; Tile.Nan; Tile.Sha; Tile.Pei; Tile.Haku; Tile.Hatsu; Tile.Chun] in
  List.concat_map (fun s -> List.map (fun n -> Tile.Suhai (s, n)) numbers) suits @
  List.map (fun j -> Tile.Jihai j) jihais

(* 未見牌のプールを構築 *)
let build_unseen_pool (hand : Tile.tile list) (visible : Tile.tile list) : Tile.tile list =
  let counts = Array.make 34 4 in  (* 各牌は4枚 *)
  let dec t =
    let idx = Ai.tile_to_index t in
    counts.(idx) <- max 0 (counts.(idx) - 1)
  in
  List.iter dec hand;
  List.iter dec visible;
  (* 未見牌をリストに展開 *)
  let pool = ref [] in
  for idx = 0 to 33 do
    for _ = 1 to counts.(idx) do
      pool := Analyzer.tile_of_index idx :: !pool
    done
  done;
  !pool

(* 配列のシャッフル *)
let shuffle_array arr =
  let n = Array.length arr in
  for i = n - 1 downto 1 do
    let j = Random.int (i + 1) in
    let tmp = arr.(i) in
    arr.(i) <- arr.(j);
    arr.(j) <- tmp
  done

(* 1回のシミュレーション: 手牌から残り牌をランダムにツモって和了できるか *)
let simulate_once (hand : Tile.tile list) (furo_count : int)
    (pool : Tile.tile array) (max_draws : int)
    (bakaze : Tile.jihai) (jikaze : Tile.jihai)
  : (bool * int * bool) =
  (* returns: (is_agari, score_if_win, reached_tenpai) *)
  let current = ref hand in
  let reached_tenpai = ref false in
  let draws = min max_draws (Array.length pool) in
  let result = ref (false, 0, false) in
  let i = ref 0 in
  while !i < draws && not (let (won, _, _) = !result in won) do
    let drawn = pool.(!i) in
    let with_drawn = drawn :: !current in
    let sh = Ai.estimate_shanten with_drawn furo_count in
    if sh <= 0 then reached_tenpai := true;
    if sh < 0 then begin
      (* 和了チェック *)
      let is_agari = Mentsu.find_agari_patterns_furo
        (List.sort Tile.compare with_drawn) furo_count <> [] in
      if is_agari then begin
        let ctx = {
          Yaku.is_tsumo = true; is_riichi = false; is_double_riichi = false;
          is_ippatsu = false; is_tenhou = false; is_chiihou = false;
          is_menzen = furo_count = 0; is_haitei = false; is_houtei = false;
          dora_count = 0; agari_tile = Some drawn; bakaze; jikaze;
        } in
        let is_oya = jikaze = Tile.Ton in
        match Scoring.score_hand ~furo_count with_drawn ctx is_oya with
        | Some r -> result := (true, r.total, true)
        | None -> ()  (* 役なし *)
      end
    end;
    (* 最低値の牌を捨てる（簡易AI） *)
    if not (let (won, _, _) = !result in won) then begin
      let discard = Ai.choose_discard_leveled ~level:5
        with_drawn [] [] [] in
      match Mentsu.remove_one discard with_drawn with
      | Some rest -> current := rest
      | None -> current := with_drawn  (* フォールバック *)
    end;
    incr i
  done;
  let (won, score, _) = !result in
  (won, score, !reached_tenpai)

(* モンテカルロシミュレーション実行 *)
let run_simulation
    (hand : Tile.tile list)
    (furo_count : int)
    (visible : Tile.tile list)
    (bakaze : Tile.jihai)
    (jikaze : Tile.jihai)
    (trials : int)
    (max_draws : int)
  : sim_result =
  let pool_list = build_unseen_pool hand visible in
  let pool_base = Array.of_list pool_list in
  let wins = ref 0 in
  let total_score = ref 0 in
  let tenpai_count = ref 0 in
  for _ = 1 to trials do
    let pool = Array.copy pool_base in
    shuffle_array pool;
    let (won, score, tenpai) = simulate_once hand furo_count pool max_draws bakaze jikaze in
    if won then begin incr wins; total_score := !total_score + score end;
    if tenpai then incr tenpai_count
  done;
  let ft = float_of_int trials in
  {
    trials;
    tsumo_wins = !wins;
    win_rate = float_of_int !wins /. ft;
    avg_score = if !wins > 0 then float_of_int !total_score /. float_of_int !wins else 0.0;
    tenpai_rate = float_of_int !tenpai_count /. ft;
  }

(* 各捨て牌候補のシミュレーション比較 *)
type discard_sim = {
  tile : Tile.tile;
  sim : sim_result;
}

let compare_discards
    (hand : Tile.tile list)
    (furo_count : int)
    (visible : Tile.tile list)
    (bakaze : Tile.jihai)
    (jikaze : Tile.jihai)
    (trials_per_discard : int)
    (max_draws : int)
  : discard_sim list =
  let unique = Ai.unique_tiles hand in
  let results = List.filter_map (fun t ->
    match Mentsu.remove_one t hand with
    | None -> None
    | Some rest ->
      let sim = run_simulation rest furo_count visible bakaze jikaze
        trials_per_discard max_draws in
      Some { tile = t; sim }
  ) unique in
  (* 勝率×期待点数でソート *)
  List.sort (fun a b ->
    let ev_a = a.sim.win_rate *. a.sim.avg_score in
    let ev_b = b.sim.win_rate *. b.sim.avg_score in
    compare ev_b ev_a
  ) results
