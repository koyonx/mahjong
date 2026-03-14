(** プレイヤーの管理 *)

(** 副露（鳴き）の種類 *)
type furo =
  | Chi of Tile.tile * Tile.tile * Tile.tile     (** チー: 順子 *)
  | Pon of Tile.tile                              (** ポン: 刻子 *)
  | Minkan of Tile.tile                           (** 明槓 *)
  | Ankan of Tile.tile                            (** 暗槓 *)

(** プレイヤーの状態 *)
type t = {
  hand : Hand.t;               (** 手牌 *)
  furo_list : furo list;       (** 副露リスト *)
  kawa : Tile.tile list;       (** 河（捨て牌） *)
  is_riichi : bool;            (** リーチ宣言済みか *)
  is_ippatsu : bool;           (** 一発の可能性があるか *)
  jikaze : Tile.jihai;         (** 自風 *)
  score : int;                 (** 持ち点 *)
}

(** プレイヤーを初期化 *)
let create (jikaze : Tile.jihai) : t = {
  hand = Hand.empty;
  furo_list = [];
  kawa = [];
  is_riichi = false;
  is_ippatsu = false;
  jikaze;
  score = 25000;
}

(** 門前か（副露なし、暗槓は除く） *)
let is_menzen (player : t) : bool =
  List.for_all (fun f ->
    match f with Ankan _ -> true | _ -> false
  ) player.furo_list

(** 手牌に牌を加える（ツモ） *)
let tsumo (tile : Tile.tile) (player : t) : (t, string) result =
  match Hand.tsumo tile player.hand with
  | Ok hand -> Ok { player with hand; is_ippatsu = player.is_ippatsu }
  | Error e -> Error e

(** 牌を捨てる *)
let discard (tile : Tile.tile) (player : t) : (t, string) result =
  match Hand.discard tile player.hand with
  | Ok hand -> Ok { player with hand; kawa = tile :: player.kawa; is_ippatsu = false }
  | Error e -> Error e

(** リーチ宣言 *)
let declare_riichi (player : t) : (t, string) result =
  if not (is_menzen player) then Error "門前でないためリーチできません"
  else if player.score < 1000 then Error "持ち点が1000点未満のためリーチできません"
  else if player.is_riichi then Error "既にリーチ宣言済みです"
  else Ok { player with is_riichi = true; is_ippatsu = true; score = player.score - 1000 }

(** ポン *)
let pon (tile : Tile.tile) (player : t) : (t, string) result =
  let hand_tiles = player.hand.tiles in
  let count = List.length (List.filter (fun t -> Tile.compare t tile = 0) hand_tiles) in
  if count < 2 then Error "ポンできる牌がありません"
  else
    match Mentsu.remove_one tile hand_tiles with
    | Some rest1 ->
      (match Mentsu.remove_one tile rest1 with
       | Some rest2 ->
         Ok { player with
              hand = Hand.make rest2;
              furo_list = Pon tile :: player.furo_list;
              is_ippatsu = false }
       | None -> Error "ポンできる牌がありません")
    | None -> Error "ポンできる牌がありません"

(** チー *)
let chi (t1 : Tile.tile) (t2 : Tile.tile) (taken : Tile.tile) (player : t) : (t, string) result =
  let all = [t1; t2; taken] in
  let sorted = List.sort Tile.compare all in
  match sorted with
  | [a; b; c] when Mentsu.is_shuntsu a b c ->
    let hand_tiles = player.hand.tiles in
    (match Mentsu.remove_one t1 hand_tiles with
     | Some rest1 ->
       (match Mentsu.remove_one t2 rest1 with
        | Some rest2 ->
          Ok { player with
               hand = Hand.make rest2;
               furo_list = Chi (a, b, c) :: player.furo_list;
               is_ippatsu = false }
        | None -> Error "チーできる牌がありません")
     | None -> Error "チーできる牌がありません")
  | _ -> Error "順子になりません"

(** 明槓（他家の捨て牌 + 手牌3枚） *)
let minkan (tile : Tile.tile) (player : t) : (t, string) result =
  let hand_tiles = player.hand.tiles in
  let count = List.length (List.filter (fun t -> Tile.compare t tile = 0) hand_tiles) in
  if count < 3 then Error "明槓できる牌がありません"
  else
    match Mentsu.remove_one tile hand_tiles with
    | Some r1 ->
      (match Mentsu.remove_one tile r1 with
       | Some r2 ->
         (match Mentsu.remove_one tile r2 with
          | Some r3 ->
            Ok { player with
                 hand = Hand.make r3;
                 furo_list = Minkan tile :: player.furo_list;
                 is_ippatsu = false }
          | None -> Error "明槓できる牌がありません")
       | None -> Error "明槓できる牌がありません")
    | None -> Error "明槓できる牌がありません"

(** 暗槓（手牌4枚） *)
let ankan (tile : Tile.tile) (player : t) : (t, string) result =
  let hand_tiles = player.hand.tiles in
  let count = List.length (List.filter (fun t -> Tile.compare t tile = 0) hand_tiles) in
  if count < 4 then Error "暗槓できる牌がありません"
  else
    match Mentsu.remove_one tile hand_tiles with
    | Some r1 ->
      (match Mentsu.remove_one tile r1 with
       | Some r2 ->
         (match Mentsu.remove_one tile r2 with
          | Some r3 ->
            (match Mentsu.remove_one tile r3 with
             | Some r4 ->
               Ok { player with
                    hand = Hand.make r4;
                    furo_list = Ankan tile :: player.furo_list;
                    is_ippatsu = false }
             | None -> Error "暗槓できる牌がありません")
          | None -> Error "暗槓できる牌がありません")
       | None -> Error "暗槓できる牌がありません")
    | None -> Error "暗槓できる牌がありません"

(** 加槓（既にポンしている牌の4枚目をツモった時） *)
let kakan (tile : Tile.tile) (player : t) : (t, string) result =
  let has_pon = List.exists (fun f ->
    match f with Pon t -> Tile.compare t tile = 0 | _ -> false
  ) player.furo_list in
  if not has_pon then Error "加槓できません"
  else
    match Mentsu.remove_one tile player.hand.tiles with
    | Some rest ->
      let new_furo = List.map (fun f ->
        match f with
        | Pon t when Tile.compare t tile = 0 -> Minkan t
        | other -> other
      ) player.furo_list in
      Ok { player with
           hand = Hand.make rest;
           furo_list = new_furo;
           is_ippatsu = false }
    | None -> Error "加槓できません"

(** 持ち点を加減する *)
let add_score (diff : int) (player : t) : t =
  { player with score = player.score + diff }
