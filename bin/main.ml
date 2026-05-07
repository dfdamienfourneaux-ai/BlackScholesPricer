
let usage () =
  Printf.printf "Usage:\n";
  Printf.printf "  bs_pricer --spot <f> --strike <f> --rate <f> --time <f> --vol <f> --type <call|put>\n";
  Printf.printf "\nExample:\n";
  Printf.printf "  bs_pricer --spot 100 --strike 105 --rate 0.05 --time 1.0 --vol 0.20 --type call\n"

let () =
  (* Sys.argv est un array — on le convertit en liste et on retire le nom du programme *)
  let args = Array.to_list Sys.argv |> List.tl in

  (* Cas spécial : aucun argument → afficher l'aide *)
  if args = [] then (usage (); exit 0);

  (* Parser et brancher sur Ok/Error *)
  match Cli.parse_args args with
  | Error msg ->
    Printf.eprintf "Error: %s\n\n" msg;   (* eprintf : écrit sur stderr *)
    usage ();
    exit 1
  | Ok params ->
    Cli.print_results params