open OUnit2
open Mahjong_core

(** ヘルパー: 数牌を簡単に作る *)
let m n = Tile.Suhai (Tile.Manzu, n)
let p n = Tile.Suhai (Tile.Pinzu, n)
let s n = Tile.Suhai (Tile.Souzu, n)
let ton = Tile.Jihai Tile.Ton
let haku = Tile.Jihai Tile.Haku
let hatsu = Tile.Jihai Tile.Hatsu
let chun = Tile.Jihai Tile.Chun

let default_ctx = Yaku.default_context

(* === Tile tests === *)

let test_tile_to_string _ =
  assert_equal "1m" (Tile.to_string (m 1));
  assert_equal "9p" (Tile.to_string (p 9));
  assert_equal "5s" (Tile.to_string (s 5));
  assert_equal "1z" (Tile.to_string ton);
  assert_equal "5z" (Tile.to_string haku)

let test_tile_compare _ =
  assert_equal 0 (Tile.compare (m 1) (m 1));
  assert_bool "1m < 2m" (Tile.compare (m 1) (m 2) < 0);
  assert_bool "manzu < pinzu" (Tile.compare (m 9) (p 1) < 0);
  assert_bool "suhai < jihai" (Tile.compare (s 9) ton < 0)

let test_all_tiles_count _ =
  assert_equal 136 (List.length Tile.all_tiles)

(* === Mentsu tests === *)

let test_is_shuntsu _ =
  assert_bool "1m2m3m is shuntsu" (Mentsu.is_shuntsu (m 1) (m 2) (m 3));
  assert_bool "7p8p9p is shuntsu" (Mentsu.is_shuntsu (p 7) (p 8) (p 9));
  assert_bool "1m2m3p is not shuntsu" (not (Mentsu.is_shuntsu (m 1) (m 2) (p 3)));
  assert_bool "1m3m5m is not shuntsu" (not (Mentsu.is_shuntsu (m 1) (m 3) (m 5)))

let test_is_koutsu _ =
  assert_bool "1m1m1m is koutsu" (Mentsu.is_koutsu (m 1) (m 1) (m 1));
  assert_bool "ton ton ton is koutsu" (Mentsu.is_koutsu ton ton ton);
  assert_bool "1m2m3m is not koutsu" (not (Mentsu.is_koutsu (m 1) (m 2) (m 3)))

(* === Hand tests === *)

let test_hand_tsumo _ =
  let hand = Hand.make [m 1; m 2; m 3] in
  assert_equal 3 (Hand.count hand);
  match Hand.tsumo (m 4) hand with
  | Ok hand2 ->
    assert_equal 4 (Hand.count hand2);
    assert_equal (Some (m 4)) hand2.tsumo
  | Error _ -> assert_failure "tsumo should succeed"

let test_hand_discard _ =
  let hand = Hand.make [m 1; m 2; m 3] in
  match Hand.discard (m 2) hand with
  | Ok hand2 ->
    assert_equal 2 (Hand.count hand2);
    assert_equal None hand2.tsumo
  | Error _ -> assert_failure "discard should succeed"

let test_hand_discard_not_found _ =
  let hand = Hand.make [m 1; m 2; m 3] in
  match Hand.discard (m 9) hand with
  | Ok _ -> assert_failure "discard should fail"
  | Error _ -> ()

(* === Agari tests === *)

let test_agari_basic _ =
  (* 1m2m3m 4m5m6m 7m8m9m 1p2p3p 5s5s : 基本的な和了形 *)
  let tiles = [m 1; m 2; m 3; m 4; m 5; m 6; m 7; m 8; m 9;
               p 1; p 2; p 3; s 5; s 5] in
  assert_bool "should be agari" (Mentsu.is_agari tiles)

let test_agari_all_koutsu _ =
  (* 1m1m1m 5p5p5p 9s9s9s 東東東 白白 : 対々和 *)
  let tiles = [m 1; m 1; m 1; p 5; p 5; p 5; s 9; s 9; s 9;
               ton; ton; ton; haku; haku] in
  assert_bool "should be agari (toitoi)" (Mentsu.is_agari tiles)

let test_not_agari _ =
  let tiles = [m 1; m 2; m 4; m 5; m 6; m 7; m 8; m 9;
               p 1; p 2; p 3; s 5; s 5; s 6] in
  assert_bool "should not be agari" (not (Mentsu.is_agari tiles))

(* === Tenpai tests === *)

let test_tenpai _ =
  (* 1m2m3m 4m5m6m 7m8m9m 1p2p3p 5s : 5s待ち *)
  let hand = Hand.make [m 1; m 2; m 3; m 4; m 5; m 6; m 7; m 8; m 9;
                         p 1; p 2; p 3; s 5] in
  let waits = Hand.tenpai_tiles hand in
  assert_bool "5s should be a wait" (List.exists (fun t -> Tile.compare t (s 5) = 0) waits)

(* === Yaku tests === *)

let test_tanyao _ =
  (* 2m3m4m 5p6p7p 3s4s5s 6s7s8s 5m5m *)
  let tiles = [m 2; m 3; m 4; p 5; p 6; p 7; s 3; s 4; s 5;
               s 6; s 7; s 8; m 5; m 5] in
  match Yaku.judge tiles default_ctx with
  | Some (yakus, _) ->
    assert_bool "tanyao" (List.exists (fun y -> y = Yaku.Tanyao) yakus)
  | None -> assert_failure "should have yaku"

let test_toitoi _ =
  (* 1m1m1m 5p5p5p 9s9s9s 東東東 白白 *)
  let tiles = [m 1; m 1; m 1; p 5; p 5; p 5; s 9; s 9; s 9;
               ton; ton; ton; haku; haku] in
  match Yaku.judge tiles default_ctx with
  | Some (yakus, _) ->
    assert_bool "toitoi" (List.exists (fun y -> y = Yaku.Toitoi) yakus)
  | None -> assert_failure "should have yaku"

let test_chinitsu _ =
  (* 1m1m1m 2m3m4m 5m6m7m 8m8m8m 9m9m *)
  let tiles = [m 1; m 1; m 1; m 2; m 3; m 4; m 5; m 6; m 7;
               m 8; m 8; m 8; m 9; m 9] in
  match Yaku.judge tiles default_ctx with
  | Some (yakus, _) ->
    assert_bool "chinitsu" (List.exists (fun y -> y = Yaku.Chinitsu) yakus)
  | None -> assert_failure "should have yaku"

let test_kokushi _ =
  (* 1m9m1p9p1s9s 東南西北白發中 + 1m *)
  let tiles = [m 1; m 9; p 1; p 9; s 1; s 9;
               ton; Tile.Jihai Tile.Nan; Tile.Jihai Tile.Sha; Tile.Jihai Tile.Pei;
               haku; hatsu; chun; m 1] in
  match Yaku.judge tiles default_ctx with
  | Some (yakus, han) ->
    assert_bool "kokushi" (List.exists (fun y -> y = Yaku.Kokushi) yakus);
    assert_equal 13 han
  | None -> assert_failure "should be kokushi"

let test_chiitoitsu _ =
  (* 7対子: 1m1m 3m3m 5p5p 7p7p 2s2s 4s4s 東東 *)
  let tiles = [m 1; m 1; m 3; m 3; p 5; p 5; p 7; p 7;
               s 2; s 2; s 4; s 4; ton; ton] in
  match Yaku.judge tiles default_ctx with
  | Some (yakus, _) ->
    assert_bool "chiitoitsu" (List.exists (fun y -> y = Yaku.Chiitoitsu) yakus)
  | None -> assert_failure "should be chiitoitsu"

let test_daisangen _ =
  (* 白白白 發發發 中中中 1m2m3m 5s5s *)
  let tiles = [haku; haku; haku; hatsu; hatsu; hatsu; chun; chun; chun;
               m 1; m 2; m 3; s 5; s 5] in
  match Yaku.judge tiles default_ctx with
  | Some (yakus, han) ->
    assert_bool "daisangen" (List.exists (fun y -> y = Yaku.Daisangen) yakus);
    assert_equal 13 han
  | None -> assert_failure "should be daisangen"

let test_yakuhai _ =
  (* 白白白 1m2m3m 4p5p6p 7s8s9s 2m2m *)
  let tiles = [haku; haku; haku; m 1; m 2; m 3; p 4; p 5; p 6;
               s 7; s 8; s 9; m 2; m 2] in
  match Yaku.judge tiles default_ctx with
  | Some (yakus, _) ->
    assert_bool "yakuhai haku" (List.exists (fun y -> y = Yaku.Yakuhai Tile.Haku) yakus)
  | None -> assert_failure "should have yakuhai"

let test_ittsu _ =
  (* 1m2m3m 4m5m6m 7m8m9m 1p2p3p 5s5s *)
  let tiles = [m 1; m 2; m 3; m 4; m 5; m 6; m 7; m 8; m 9;
               p 1; p 2; p 3; s 5; s 5] in
  match Yaku.judge tiles default_ctx with
  | Some (yakus, _) ->
    assert_bool "ittsu" (List.exists (fun y -> y = Yaku.Ittsu) yakus)
  | None -> assert_failure "should have ittsu"

(* === Scoring tests === *)

let test_scoring_mangan _ =
  (* 満貫: 子ロン = 8000点 *)
  let payment = Scoring.calculate { han = 5; fu = 30; is_oya = false; is_tsumo = false } in
  match payment with
  | Scoring.Ron n -> assert_equal 8000 n
  | _ -> assert_failure "should be ron"

let test_scoring_oya_ron _ =
  (* 親ロン 3翻30符 = 30*2^5=960 基本点, ×6=5760 → 5800 *)
  let payment = Scoring.calculate { han = 3; fu = 30; is_oya = true; is_tsumo = false } in
  match payment with
  | Scoring.Ron n -> assert_equal 5800 n
  | _ -> assert_failure "should be ron"

let test_scoring_ko_tsumo _ =
  (* 子ツモ 3翻30符: 基本点960, 親2000 子1000 *)
  let payment = Scoring.calculate { han = 3; fu = 30; is_oya = false; is_tsumo = true } in
  match payment with
  | Scoring.Tsumo_ko (oya, ko) ->
    assert_equal 2000 oya;
    assert_equal 1000 ko
  | _ -> assert_failure "should be tsumo_ko"

let test_scoring_yakuman _ =
  (* 役満: 子ロン = 32000点 *)
  let payment = Scoring.calculate { han = 13; fu = 0; is_oya = false; is_tsumo = false } in
  match payment with
  | Scoring.Ron n -> assert_equal 32000 n
  | _ -> assert_failure "should be ron"

let test_score_hand_integration _ =
  (* 1m1m1m 5p5p5p 9s9s9s 東東東 白白 : 対々和+役牌東+役牌白 *)
  let tiles = [m 1; m 1; m 1; p 5; p 5; p 5; s 9; s 9; s 9;
               ton; ton; ton; haku; haku] in
  let ctx = { default_ctx with is_tsumo = false } in
  match Scoring.score_hand tiles ctx false with
  | Some result ->
    assert_bool "han >= 4" (result.han_detail >= 4)
  | None -> assert_failure "should score"

(* === Test suite === *)

let suite =
  "Mahjong" >::: [
    "tile_to_string" >:: test_tile_to_string;
    "tile_compare" >:: test_tile_compare;
    "all_tiles_count" >:: test_all_tiles_count;
    "is_shuntsu" >:: test_is_shuntsu;
    "is_koutsu" >:: test_is_koutsu;
    "hand_tsumo" >:: test_hand_tsumo;
    "hand_discard" >:: test_hand_discard;
    "hand_discard_not_found" >:: test_hand_discard_not_found;
    "agari_basic" >:: test_agari_basic;
    "agari_all_koutsu" >:: test_agari_all_koutsu;
    "not_agari" >:: test_not_agari;
    "tenpai" >:: test_tenpai;
    "tanyao" >:: test_tanyao;
    "toitoi" >:: test_toitoi;
    "chinitsu" >:: test_chinitsu;
    "kokushi" >:: test_kokushi;
    "chiitoitsu" >:: test_chiitoitsu;
    "daisangen" >:: test_daisangen;
    "yakuhai" >:: test_yakuhai;
    "ittsu" >:: test_ittsu;
    "scoring_mangan" >:: test_scoring_mangan;
    "scoring_oya_ron" >:: test_scoring_oya_ron;
    "scoring_ko_tsumo" >:: test_scoring_ko_tsumo;
    "scoring_yakuman" >:: test_scoring_yakuman;
    "score_hand_integration" >:: test_score_hand_integration;
  ]

let () = run_test_tt_main suite
