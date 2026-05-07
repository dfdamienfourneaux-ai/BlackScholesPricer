open Black_scholes

(* ===== Parsing d'un float depuis une string ===== *)

(* float_of_string_opt : string -> float option
   Retourne Some f si la conversion réussit, None sinon.
   C'est une fonction de la stdlib OCaml. *)

let parse_float (name : string) (s : string) : (float, string) result =
  match float_of_string_opt s with
  | None   -> Error (Printf.sprintf "invalid value for %s: '%s' is not a number" name s)
  | Some f -> Ok f

(* ===== Validation des valeurs ===== *)

(* On veut rejeter les valeurs absurdes : spot négatif, vol à 0, etc. *)
let validate_positive (name : string) (f : float) : (float, string) result =
  if f > 0.0 then Ok f
  else Error (Printf.sprintf "%s must be strictly positive, got %g" name f)

let validate_non_negative (name : string) (f : float) : (float, string) result =
  if f >= 0.0 then Ok f
  else Error (Printf.sprintf "%s must be non-negative, got %g" name f)

(* ===== L'opérateur >>= (bind) ===== *)

(* Nouveau concept : chaîner des résultats sans if/else imbriqués.
   Si le résultat est Ok, on applique la fonction f.
   Si c'est Error, on court-circuite et on propage l'erreur. *)
let ( >>= ) (r : ('a, 'e) result) (f : 'a -> ('b, 'e) result) : ('b, 'e) result =
  match r with
  | Error e -> Error e
  | Ok v    -> f v

(* Exemple d'utilisation :
   parse_float "spot" "100.0" >>= validate_positive "spot"
   
   Si "100.0" parse bien → Ok 100.0 → validate_positive "spot" 100.0 → Ok 100.0
   Si "-5.0"  parse bien → Ok -5.0  → validate_positive "spot" (-5.0) → Error "..."
   Si "abc"   ne parse pas → Error "..."  →  court-circuit, validate jamais appelée *)

(* ===== Chercher un argument dans argv ===== *)

(* Reçoit la liste argv et un nom de flag (ex: "--spot")
   Retourne Ok "100.0" si trouvé, Error "..." si absent *)
let find_arg (args : string list) (flag : string) : (string, string) result =
  let rec loop = function
    | []              -> Error (Printf.sprintf "missing argument %s" flag)
    | [_]             -> Error (Printf.sprintf "missing value for %s" flag)
    | k :: v :: rest  ->
      if k = flag then Ok v
      else loop (v :: rest)
  in
  loop args

(* ===== Parser le type d'option ===== *)

let parse_option_type (s : string) : (option_type, string) result =
  match String.lowercase_ascii s with
  | "call" -> Ok Call
  | "put"  -> Ok Put
  | other  -> Error (Printf.sprintf "unknown option type '%s': use 'call' or 'put'" other)

(* ===== Parser tous les arguments d'un coup ===== *)

(* Ici on chaîne tous les parsers avec >>= 
   Si n'importe lequel échoue, l'erreur remonte directement *)
let parse_args (args : string list) : (params, string) result =
  find_arg args "--spot"   >>= parse_float "spot"   >>= validate_positive "spot"   >>= fun spot ->
  find_arg args "--strike" >>= parse_float "strike" >>= validate_positive "strike" >>= fun strike ->
  find_arg args "--rate"   >>= parse_float "rate"   >>= validate_non_negative "rate"   >>= fun rate ->
  find_arg args "--time"   >>= parse_float "time"   >>= validate_positive "time"   >>= fun time ->
  find_arg args "--vol"    >>= parse_float "vol"    >>= validate_positive "vol"    >>= fun vol ->
  find_arg args "--type"   >>= parse_option_type                                   >>= fun otype ->
  Ok {
    option_type = otype;
    spot;
    strike;
    rate;
    time;
    volatility = vol;
  }

(* ===== Affichage des résultats ===== *)

let print_results (p : params) : unit =
  let call_p = { p with option_type = Call } in
  let put_p  = { p with option_type = Put  } in
  let call_price = price call_p in
  let put_price  = price put_p  in
  let g = compute_greeks p in
  let type_str = match p.option_type with Call -> "Call" | Put -> "Put" in
  Printf.printf "\n=== Black-Scholes Pricer ===\n";
  Printf.printf "Type   : %s\n" type_str;
  Printf.printf "Spot   : %.2f | Strike : %.2f\n" p.spot p.strike;
  Printf.printf "Rate   : %.1f%% | Time : %.2f yr | Vol : %.1f%%\n"
    (p.rate *. 100.0) p.time (p.volatility *. 100.0);
  Printf.printf "\n--- Prix ---\n";
  Printf.printf "Call   : %.4f\n" call_price;
  Printf.printf "Put    : %.4f\n" put_price;
  Printf.printf "\n--- Grecques (%s) ---\n" type_str;
  Printf.printf "Delta  : % .4f\n" g.delta;
  Printf.printf "Gamma  : % .4f\n" g.gamma;
  Printf.printf "Vega   : % .4f\n" g.vega;
  Printf.printf "Theta  : % .4f  (par jour)\n" g.theta;
  Printf.printf "Rho    : % .4f\n" g.rho