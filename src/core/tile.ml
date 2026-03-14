(** 牌の種類 *)
type suit =
  | Manzu  (** 萬子 *)
  | Pinzu  (** 筒子 *)
  | Souzu  (** 索子 *)

(** 字牌の種類 *)
type jihai =
  | Ton     (** 東 *)
  | Nan     (** 南 *)
  | Sha     (** 西 *)
  | Pei     (** 北 *)
  | Haku    (** 白 *)
  | Hatsu   (** 發 *)
  | Chun    (** 中 *)

(** 牌 *)
type tile =
  | Suhai of suit * int   (** 数牌: 種類 * 数字(1-9) *)
  | Jihai of jihai        (** 字牌 *)

(** 牌の総数: 各牌4枚 = 136枚 *)
let all_tiles : tile list =
  let suits = [Manzu; Pinzu; Souzu] in
  let numbers = [1; 2; 3; 4; 5; 6; 7; 8; 9] in
  let jihais = [Ton; Nan; Sha; Pei; Haku; Hatsu; Chun] in
  let suhai_tiles =
    List.concat_map (fun s ->
      List.concat_map (fun n ->
        List.init 4 (fun _ -> Suhai (s, n))
      ) numbers
    ) suits
  in
  let jihai_tiles =
    List.concat_map (fun j ->
      List.init 4 (fun _ -> Jihai j)
    ) jihais
  in
  suhai_tiles @ jihai_tiles

(** 牌を文字列に変換 *)
let to_string = function
  | Suhai (Manzu, n) -> Printf.sprintf "%dm" n
  | Suhai (Pinzu, n) -> Printf.sprintf "%dp" n
  | Suhai (Souzu, n) -> Printf.sprintf "%ds" n
  | Jihai Ton   -> "1z"
  | Jihai Nan   -> "2z"
  | Jihai Sha   -> "3z"
  | Jihai Pei   -> "4z"
  | Jihai Haku  -> "5z"
  | Jihai Hatsu -> "6z"
  | Jihai Chun  -> "7z"

(** 牌の比較 *)
let compare a b =
  match (a, b) with
  | Suhai (s1, n1), Suhai (s2, n2) ->
    let sc = Stdlib.compare s1 s2 in
    if sc <> 0 then sc else Stdlib.compare n1 n2
  | Jihai j1, Jihai j2 -> Stdlib.compare j1 j2
  | Suhai _, Jihai _ -> -1
  | Jihai _, Suhai _ -> 1
