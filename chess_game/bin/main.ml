open GMain

(** Initialize GTK library. *)
let _ = GtkMain.Main.init ()

(** Static variables for the GUI Window width and height. *)
let width = 600

let height = 600

let state =
  [|
    [|
      Some "B_Rook";
      Some "B_Knight";
      Some "B_Bishop";
      Some "B_Queen";
      Some "B_King";
      Some "B_Bishop";
      Some "B_Knight";
      Some "B_Rook";
    |];
    [|
      Some "B_Pawn";
      Some "B_Pawn";
      Some "B_Pawn";
      Some "B_Pawn";
      Some "B_Pawn";
      Some "B_Pawn";
      Some "B_Pawn";
      Some "B_Pawn";
    |];
    [| None; None; None; None; None; None; None; None |];
    [| None; None; None; None; None; None; None; None |];
    [| None; None; None; None; None; None; None; None |];
    [| None; None; None; None; None; None; None; None |];
    [|
      Some "W_Pawn";
      Some "W_Pawn";
      Some "W_Pawn";
      Some "W_Pawn";
      Some "W_Pawn";
      Some "W_Pawn";
      Some "W_Pawn";
      Some "W_Pawn";
    |];
    [|
      Some "W_Rook";
      Some "W_Knight";
      Some "W_Bishop";
      Some "W_Queen";
      Some "W_King";
      Some "W_Bishop";
      Some "W_Knight";
      Some "W_Rook";
    |];
  |]

let buttons = Array.make_matrix 8 8 (GButton.button ~label:"" ())

type f = {
  mutable row : int;
  mutable col : int;
}

let prev = { row = 4; col = 4 }

(**[piece_square r c] is the type of piece at row [r] and column [c] at the
   beginning of the game*)
let piece_square (row : int) (col : int) =
  match state.(row).(col) with
  | Some piece -> piece
  | None -> ""

(**[set_square_img r c] generates the image to be shown at row [r] and column
   [c] as specified by [piece_square]*)
let set_square_img row col =
  let dim = 65 in
  let img = GdkPixbuf.create ~width:dim ~height:dim ~has_alpha:true () in
  GdkPixbuf.scale ~dest:img ~width:dim ~height:dim
    (GdkPixbuf.from_file ("assets/" ^ piece_square row col ^ ".png"));
  img

(**[create_chessboard_window] creates a window with a standard chess board setup*)
let create_chessboard_window () =
  let window = GWindow.window ~width ~height ~title:"Board" () in
  ignore (window#connect#destroy ~callback:Main.quit);

  (* Vertical box for the Quit button + chessboard *)
  let vbox = GPack.vbox ~packing:window#add () in

  (* Quit button *)
  let quit_button = GButton.button ~label:"Quit" ~packing:vbox#pack () in
  ignore (quit_button#connect#clicked ~callback:Main.quit);

  (* Table for chessbaord *)
  let table =
    GPack.table ~rows:8 ~columns:8 ~homogeneous:true ~packing:vbox#add ()
  in
  (* Function to create a square *)
  let create_square row col =
    let button = GButton.button ~label:"" () in
    if piece_square row col != "" then
      ignore
        (GMisc.image ~pixbuf:(set_square_img row col) ~packing:button#set_image
           ());
    let color =
      if (row + col) mod 2 = 0 then `NAME "white" else `NAME "green"
    in
    button#misc#modify_bg [ (`NORMAL, color) ];
    ignore
      (button#connect#clicked ~callback:(fun () ->
           (* If prev square is a piece *)
           if
             piece_square prev.row prev.col <> ""
             && Chess_game.Movement.is_valid_move
                  (piece_square prev.row prev.col)
                  prev.row prev.col row col state
           then (
             (* Then set new piece at new square *)
             ignore
               (GMisc.image
                  ~pixbuf:(set_square_img prev.row prev.col)
                  ~packing:button#set_image ());
             (* Change prev piece to blank *)
             ignore
               (GMisc.image ~packing:buttons.(prev.row).(prev.col)#set_image ());
             (* move prev piece to new location *)
             state.(row).(col) <- state.(prev.row).(prev.col);
             state.(prev.row).(prev.col) <- None)
           else (
             prev.row <- row;
             prev.col <- col)));

    button
  in
  for row = 0 to 7 do
    for col = 0 to 7 do
      let square = create_square row col in
      table#attach ~left:col ~top:row ~expand:`BOTH ~fill:`BOTH square#coerce;
      buttons.(row).(col) <- square
    done
  done;

  window#show ();
  ()

(**[create_homescreen_window] creates the inital wondow for game mode selection*)
let create_homescreen_window () =
  let window = GWindow.window ~width ~height ~title:"Home Screen" () in
  ignore (window#connect#destroy ~callback:Main.quit);

  let vbox = GPack.vbox ~packing:window#add () in

  let two_player_button = GButton.button ~packing:vbox#pack () in
  two_player_button#misc#set_size_request ~width:100 ~height:100 ();
  two_player_button#misc#modify_bg [ (`NORMAL, `NAME "gray") ];
  two_player_button#set_border_width 10;
  ignore
    (let lbl = GMisc.label ~packing:two_player_button#set_image () in
     lbl#set_text "Two Player";
     lbl#set_justify `CENTER);
  ignore
    (two_player_button#connect#clicked ~callback:(fun () ->
         window#destroy ();
         create_chessboard_window ();
         Main.main ()));

  window#show ();
  ()

let main () =
  create_homescreen_window ();
  Main.main ()

let () = main ()
