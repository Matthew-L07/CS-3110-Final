let state =
  [|
    [|
      Some "B_Rook"; Some "B_Knight"; Some "B_Bishop"; Some "B_Queen";
      Some "B_King"; Some "B_Bishop"; Some "B_Knight"; Some "B_Rook";
    |];
    [|
      Some "B_Pawn"; Some "B_Pawn"; Some "B_Pawn"; Some "B_Pawn"; Some "B_Pawn";
      Some "B_Pawn"; Some "B_Pawn"; Some "B_Pawn";
    |]; [| None; None; None; None; None; None; None; None |];
    [| None; None; None; None; None; None; None; None |];
    [| None; None; None; None; None; None; None; None |];
    [| None; None; None; None; None; None; None; None |];
    [|
      Some "W_Pawn"; Some "W_Pawn"; Some "W_Pawn"; Some "W_Pawn"; Some "W_Pawn";
      Some "W_Pawn"; Some "W_Pawn"; Some "W_Pawn";
    |];
    [|
      Some "W_Rook"; Some "W_Knight"; Some "W_Bishop"; Some "W_Queen";
      Some "W_King"; Some "W_Bishop"; Some "W_Knight"; Some "W_Rook";
    |];
  |]

(* Top of the file: define the structure to store the last move's details *)
let last_move = ref ("", (-1, -1), (-1, -1), false)

(**[piece_at r c] is the type of piece at row [r] and column [c]. Returns [""]
   if no piece is present*)
let piece_at row col =
  match state.(row).(col) with
  | Some piece -> piece
  | None -> ""

let is_enpassant pr pc er ec =
  let last_piece, (last_pr, last_pc), (last_er, _), was_two_square_move =
    !last_move
  in
  let piece = piece_at pr pc in
  (* Check if the current move's piece is a pawn moving diagonally to an empty
     square *)
  piece.[2] = 'P'
  && state.(er).(ec) = None
  && abs (pr - er) = 1
  && abs (pc - ec) = 1
  (* Check if the last move was a pawn moving two squares directly ahead of the
     current piece's end square *)
  && was_two_square_move
  && abs (last_pr - last_er) = 2
  && last_pc = ec
  && (* Ensure the pawns are different colors *)
  piece.[0] <> last_piece.[0]

let update_state pr pc er ec =
  let piece = piece_at pr pc in
  let is_two_square_move =
    (piece = "W_Pawn" || piece = "B_Pawn") && abs (pr - er) = 2
  in
  state.(er).(ec) <- state.(pr).(pc);
  state.(pr).(pc) <- None;
  last_move := (piece, (pr, pc), (er, ec), is_two_square_move);
  (* Handle en passant capture *)
  if abs (pr - er) = 1 && abs (pc - ec) = 1 && piece.[2] = 'P' then
    match !last_move with
    | _, (_, prev_col), _, true when prev_col = ec ->
        state.(pr).(ec) <- None (* Clear the captured pawn due to en passant *)
    | _ -> ()

let has_piece row col = piece_at row col <> ""

(**[same_color piece end_row end_col state] is true if the piece at the position
   of ([end_row], [end_column] in state has the same color as [piece] and false
   otherwise)*)
let same_color piece end_row end_col =
  let end_piece =
    match state.(end_row).(end_col) with
    | Some p -> p
    | None -> "n"
  in
  if piece.[0] = end_piece.[0] then true else false

(**[turn] contains the color of the player to move. ["W"] means white to move
   and ["B"] means black to move.*)
let turn = ref "W"

(**[update_turn ()] allows the next player to move.*)
let update_turn () =
  match !turn with
  | "W" -> turn := "B"
  | "B" -> turn := "W"
  | _ -> failwith ""

let play_turn p =
  if p then (
    update_turn ();
    true)
  else false

(*------------------------------------------------------------------*)
(*------------------------------------------------------------------*)
(*------------------------------------------------------------------*)
(******************** Regular Moves/Captures ************************)
let rec bishop_move_h start_row start_col end_row end_col acc =
  if start_row < end_row && start_col < end_col then
    if start_row = end_row - 1 && start_col = end_col - 1 then acc
    else
      bishop_move_h (start_row + 1) (start_col + 1) end_row end_col
        ((start_row + 1, start_col + 1) :: acc)
  else if start_row < end_row && start_col > end_col then
    if start_row = end_row - 1 && start_col = end_col + 1 then acc
    else
      bishop_move_h (start_row + 1) (start_col - 1) end_row end_col
        ((start_row + 1, start_col - 1) :: acc)
  else if start_row > end_row && start_col < end_col then
    if start_row = end_row + 1 && start_col = end_col - 1 then acc
    else
      bishop_move_h (start_row - 1) (start_col + 1) end_row end_col
        ((start_row - 1, start_col + 1) :: acc)
  else if start_row = end_row + 1 && start_col = end_col + 1 then acc
  else
    bishop_move_h (start_row - 1) (start_col - 1) end_row end_col
      ((start_row - 1, start_col - 1) :: acc)

(** [is_valid_bishop_move start_row start_col end_row end_col] checks if a move
    from [start_row, start_col] to [end_row, end_col] is a valid bishop move.
    Bishops move diagonally. *)
let is_valid_bishop_move start_row start_col end_row end_col =
  (not (start_row = end_row))
  && abs (end_row - start_row) = abs (end_col - start_col)
  && List.for_all
       (fun ele -> state.(fst ele).(snd ele) = None)
       (bishop_move_h start_row start_col end_row end_col [])

let rec rook_move_h same start_n end_n acc =
  if start_n < end_n then
    if start_n = end_n - 1 then acc
      (*Allows for capture of pieces by having start_n = end_n +- 1*)
    else rook_move_h same (start_n + 1) end_n ((same, start_n + 1) :: acc)
  else if start_n = end_n + 1 then acc
  else rook_move_h same (start_n - 1) end_n ((same, start_n - 1) :: acc)

(** [is_valid_rook_move start_row start_col end_row end_col] checks if a move
    from [start_row, start_col] to [end_row, end_col] is a valid rook move.
    Rooks move horizontally or vertically. *)
let is_valid_rook_move start_row start_col end_row end_col =
  (not (start_row = end_row && start_col = end_col))
  && (start_row = end_row
      && List.for_all
           (fun ele -> state.(fst ele).(snd ele) = None)
           (rook_move_h start_row start_col end_col [])
     || start_col = end_col
        && List.for_all
             (fun ele -> state.(snd ele).(fst ele) = None)
             (rook_move_h start_col start_row end_row []))

(** [is_valid_knight_move start_row start_col end_row end_col] checks if a move
    from [start_row, start_col] to [end_row, end_col] is a valid knight move.
    Knights move in an 'L' shape: two squares vertically and one horizontally or
    one vertically and two horizontally. *)
let is_valid_knight_move start_row start_col end_row end_col =
  let row_diff = abs (end_row - start_row) in
  let col_diff = abs (end_col - start_col) in
  (row_diff = 2 && col_diff = 1) || (row_diff = 1 && col_diff = 2)

(** [is_valid_queen_move start_row start_col end_row end_col] checks if a move
    from [start_row, start_col] to [end_row, end_col] is a valid queen move. The
    queen can move both horizontally/vertically and diagonally. *)
let is_valid_queen_move start_row start_col end_row end_col =
  is_valid_rook_move start_row start_col end_row end_col
  || is_valid_bishop_move start_row start_col end_row end_col

(** [is_valid_king_move start_row start_col end_row end_col] checks if a move
    from [start_row, start_col] to [end_row, end_col] is a valid king move. The
    king moves one square in any direction. *)
let is_valid_king_move start_row start_col end_row end_col =
  let row_diff = abs (end_row - start_row) in
  let col_diff = abs (end_col - start_col) in
  (not (start_row = end_row && start_col = end_col))
  && row_diff <= 1 && col_diff <= 1

(** [is_valid_pawn_move piece start_row start_col end_row end_col state] checks
    if a move from [start_row, start_col] to [end_row, end_col] is a valid pawn
    move, based on the current [state] of the board. Pawns move forward one
    square, but can move two squares from their initial position, and capture
    diagonally. *)
let is_valid_pawn_move piece start_row start_col end_row end_col =
  let forward = if piece = "W_Pawn" then -1 else 1 in
  let en_passant_row = if piece = "W_Pawn" then 3 else 4 in
  let is_two_square_move = ref false in
  let pawn_initial_row = if piece = "W_Pawn" then 6 else 1 in
  match (end_row - start_row, end_col - start_col) with
  | r, 0 when r = forward && state.(end_row).(end_col) = None -> true
  | r, 0
    when r = 2 * forward
         && start_row = pawn_initial_row
         && state.(start_row + forward).(start_col) = None
         && state.(end_row).(end_col) = None ->
      is_two_square_move := true;
      true
  | r, c when r = forward && abs c = 1 && state.(end_row).(end_col) <> None ->
      true
  | r, c when r = forward && abs c = 1 && start_row = en_passant_row -> (
      match !last_move with
      | "W_Pawn", (_, prev_col), _, true when prev_col = end_col -> true
      | "B_Pawn", (_, prev_col), _, true when prev_col = end_col -> true
      | _ -> false)
  | _ -> false

let is_valid_move piece start_row start_col end_row end_col =
  match piece with
  | "B_Bishop" | "W_Bishop" ->
      is_valid_bishop_move start_row start_col end_row end_col
  | "B_Rook" | "W_Rook" ->
      is_valid_rook_move start_row start_col end_row end_col
  | "B_Knight" | "W_Knight" ->
      is_valid_knight_move start_row start_col end_row end_col
  | "B_Queen" | "W_Queen" ->
      is_valid_queen_move start_row start_col end_row end_col
  | "B_King" -> is_valid_king_move start_row start_col end_row end_col
  | "W_King" -> is_valid_king_move start_row start_col end_row end_col
  | "B_Pawn" | "W_Pawn" ->
      is_valid_pawn_move piece start_row start_col end_row end_col
  | _ -> false

(************************* Regular Moving/Capturing ********************)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)

(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
(**************************  CASTLING **********************************)
let has_moved = [| false; false; false; false; false; false |]

(* Corresponds to [wksr, wqsr, bksr, bqsr, wk, bk] *)
let update_rook_moved r c =
  match (r, c) with
  | 7, 7 -> has_moved.(0) <- true (* White kingside rook has moved *)
  | 7, 0 -> has_moved.(1) <- true (* White queenside rook has moved *)
  | 0, 7 -> has_moved.(2) <- true (* Black kingside rook has moved *)
  | 0, 0 -> has_moved.(3) <- true (* Black queenside rook has moved *)
  | _ -> ()

let checks_for_castle a b c d =
  (* a, b, c, d are just factored out variables (not especially meaningful) *)
  state.(a).(b) = None
  && state.(a).(c) = None
  && (!turn = if a = 7 then "W" else "B")
  && (not has_moved.(if a = 7 then 4 else 5))
  && not has_moved.(d)

let is_valid_castle start_row start_col end_row end_col =
  let piece = piece_at start_row start_col in
  if not (piece = "B_King" || piece = "W_King") then false
  else
    match (start_row, start_col, end_row, end_col) with
    | 7, 4, 7, 6 -> checks_for_castle 7 5 6 0
    | 7, 4, 7, 2 -> state.(7).(1) = None && checks_for_castle 7 2 3 1
    | 0, 4, 0, 6 -> checks_for_castle 0 5 6 2
    | 0, 4, 0, 2 -> state.(0).(1) = None && checks_for_castle 0 2 3 3
    | _ -> false

let type_castle start_row start_col end_row end_col =
  match (start_row, start_col, end_row, end_col) with
  | 7, 4, 7, 6 ->
      update_turn ();
      has_moved.(4) <- true;
      "wksc" (* White kingside castle*)
  | 7, 4, 7, 2 ->
      update_turn ();
      has_moved.(4) <- true;
      "wqsc" (* White queenside castle*)
  | 0, 4, 0, 6 ->
      update_turn ();
      has_moved.(5) <- true;
      "bksc" (* Black kingside castle*)
  | 0, 4, 0, 2 ->
      update_turn ();
      has_moved.(5) <- true;
      "bqsc" (* Black queenside castle*)
  | _ -> ""

let castle_state c ke rs re =
  state.(c).(ke) <- state.(c).(4);
  state.(c).(4) <- None;
  state.(c).(re) <- state.(c).(rs);
  state.(c).(rs) <- None

(************************** CASTLING ***********************************)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)

(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
(************************** SQUARE BEING ATTACKED **********************)
let board_list =
  [
    (0, 1); (0, 2); (0, 3); (0, 4); (0, 5); (0, 6); (0, 7); (1, 1); (1, 2);
    (1, 3); (1, 4); (1, 5); (1, 6); (1, 7); (2, 1); (2, 2); (2, 3); (2, 4);
    (2, 5); (2, 6); (2, 7); (3, 1); (3, 2); (3, 3); (3, 4); (3, 5); (3, 6);
    (3, 7); (4, 1); (4, 2); (4, 3); (4, 4); (4, 5); (4, 6); (4, 7); (5, 1);
    (5, 2); (5, 3); (5, 4); (5, 5); (5, 6); (5, 7); (6, 1); (6, 2); (6, 3);
    (6, 4); (6, 5); (6, 6); (6, 7); (7, 1); (7, 2); (7, 3); (7, 4); (7, 5);
    (7, 6); (7, 7);
  ]

let piece_valid_moves piece start_row start_col =
  List.filter
    (fun e -> is_valid_move piece start_row start_col (fst e) (snd e))
    board_list

let add_valid_sqs color acc row col =
  if String.starts_with ~prefix:color (piece_at row col) then
    acc @ piece_valid_moves (piece_at row col) row col
  else acc

let rec valid_moves_aux color acc row col =
  if row = 7 && col = 7 then acc
  else if row = 7 then
    valid_moves_aux color (add_valid_sqs color acc row col) 0 (col + 1)
  else valid_moves_aux color (add_valid_sqs color acc row col) (row + 1) col

let valid_b_moves () =
  List.sort_uniq
    (fun e1 e2 -> if fst e1 = fst e2 then snd e1 - snd e2 else fst e1 - fst e2)
    (valid_moves_aux "B" [] 0 0)

let valid_w_moves () =
  List.sort_uniq
    (fun e1 e2 -> if fst e1 = fst e2 then snd e1 - snd e2 else fst e1 - fst e2)
    (valid_moves_aux "W" [] 0 0)

let rec get_piece_square piece row col =
  if row = 7 && col = 7 then (row, col)
  else if row = 7 then
    if piece_at row col = piece then (row, col)
    else get_piece_square piece 0 (col + 1)
  else if piece_at row col = piece then (row, col)
  else get_piece_square piece (row + 1) col

let in_check () =
  if !turn = "B" then
    List.mem (get_piece_square "B_King" 0 0) (valid_w_moves ())
  else List.mem (get_piece_square "W_King" 0 0) (valid_b_moves ())

let _ = in_check
let promote row col piece = state.(row).(col) <- Some piece

(************************** SQUARE BEING ATTACKED **********************)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)

let valid_move start_row start_col end_row end_col =
  if not (has_piece start_row start_col) then false
  else
    let piece = piece_at start_row start_col in
    (*only a valid move if the correct player is moving a piece and is not
      landing on a square occupied by one of that player's pieces*)
    if String.sub piece 0 1 <> !turn || same_color piece end_row end_col then
      false (* else if in_check state then ( print_endline "in check"; false) *)
    else
      let piece = piece_at start_row start_col in
      (*only a valid move if the correct player is moving a piece and is not
        landing on a square occupied by one of that player's pieces*)
      print_endline "play move";
      if String.sub piece 0 1 <> !turn || same_color piece end_row end_col then
        false
        (* else if in_check state then ( print_endline "in check"; false) *)
      else
        match piece with
        (*if a player makes a valid move, it is now the next player's turn*)
        | "B_Bishop" | "W_Bishop" ->
            play_turn (is_valid_bishop_move start_row start_col end_row end_col)
        | "B_Rook" | "W_Rook" ->
            if is_valid_rook_move start_row start_col end_row end_col then
              update_rook_moved start_row start_col;
            play_turn (is_valid_rook_move start_row start_col end_row end_col)
        | "B_Knight" | "W_Knight" ->
            play_turn (is_valid_knight_move start_row start_col end_row end_col)
        | "B_Queen" | "W_Queen" ->
            play_turn (is_valid_queen_move start_row start_col end_row end_col)
        | "B_King" ->
            if is_valid_king_move start_row start_col end_row end_col then
              has_moved.(5) <- true;
            play_turn (is_valid_king_move start_row start_col end_row end_col)
        | "W_King" ->
            if is_valid_king_move start_row start_col end_row end_col then
              has_moved.(4) <- true;
            play_turn (is_valid_king_move start_row start_col end_row end_col)
        | "B_Pawn" | "W_Pawn" ->
            play_turn
              (is_valid_pawn_move piece start_row start_col end_row end_col)
        | _ -> false

(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
(*************************** INFO BAR **********************************)

(**[material piece] returns the material value of a piece *)
let material piece =
  match String.sub piece 2 (String.length piece - 2) with
  | "Pawn" -> 1
  | "Rook" -> 5
  | "Bishop" -> 3
  | "Knight" -> 3
  | "Queen" -> 9
  | _ -> 0

(**[captured_W] contains a list of all the white pieces that have been captured,
   sorted based on the pieces' material value*)
let captured_W = ref []

(**[captured_B] contains a list of all the black pieces that have been captured,
   sorted based on the pieces' material value*)
let captured_B = ref []

(**[update_captures row col] adds the piece at row [row] and column [col] into
   [captured_W] if it is a white piece and [captured_B] if it is black*)
let update_captures row col =
  if state.(row).(col) = None then ()
  else
    match state.(row).(col) with
    | Some p -> (
        match p.[0] with
        | 'W' ->
            captured_W :=
              List.sort
                (fun p1 p2 -> material p1 - material p2)
                (p :: !captured_W)
        | 'B' ->
            captured_B :=
              List.sort
                (fun p1 p2 -> material p1 - material p2)
                (p :: !captured_B)
        | _ -> failwith "un")
    | _ -> failwith "un"

(**[total_material captured] returns the sum of the material value of all pieces
   in [captured]*)
let rec total_material captured =
  match captured with
  | [] -> 0
  | h :: t -> material h + total_material t

(**[material_advantage ()] is a tuple whose first element is the color that has
   the material advantage and whose second element is the value of the
   advantage. returns [("same", 0)] if the two sides are equal in terms of
   material*)
let material_advantage () =
  let adv = abs (total_material !captured_B - total_material !captured_W) in
  if total_material !captured_B - total_material !captured_W = 0 then ("same", 0)
  else if total_material !captured_B - total_material !captured_W > 0 then
    ("W", adv)
  else ("B", adv)

(*************************** INFO BAR **********************************)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
(*---------------------------------------------------------------------*)
