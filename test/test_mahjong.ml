open OUnit2
open Mahjong_core

(** ヘルパー: 数牌を簡単に作る *)
let m n = Tile.Suhai (Tile.Manzu, n)
let p n = Tile.Suhai (Tile.Pinzu, n)
let s n = Tile.Suhai (Tile.Souzu, n)
let ton = Tile.Jihai Tile.Ton
let haku = Tile.Jihai Tile.Haku

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
  ]

let () = run_test_tt_main suite
