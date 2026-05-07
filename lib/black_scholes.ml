(* ===== Types ===== *)

type option_type = Call | Put

type params = {
  option_type : option_type;
  spot        : float;
  strike      : float;
  rate        : float;
  time        : float;
  volatility  : float;
}

type greeks = {
  delta : float;
  gamma : float;
  vega  : float;
  theta : float;
  rho   : float;
}

(* ===== Loi normale ===== *)

let normal_cdf x =
  0.5 *. (1.0 +. Float.erf (x /. sqrt 2.0))

let normal_pdf x =
  let two_pi = 2.0 *. Float.pi in
  exp (-. x *. x /. 2.0) /. sqrt two_pi

(* ===== Helpers d1 et d2 ===== *)

let compute_d1 (p : params) : float =
  (log (p.spot /. p.strike)
   +. (p.rate +. 0.5 *. p.volatility *. p.volatility) *. p.time)
  /. (p.volatility *. Float.sqrt p.time)

let compute_d2 (p : params) : float =
  compute_d1 p -. p.volatility *. Float.sqrt p.time

(* ===== Prix ===== *)

let price (p : params) : float =
  let d1       = compute_d1 p in
  let d2       = compute_d2 p in
  let discount = exp (-. p.rate *. p.time) in
  match p.option_type with
  | Call -> p.spot *. normal_cdf d1 -. p.strike *. discount *. normal_cdf d2
  | Put  -> p.strike *. discount *. normal_cdf (-.d2) -. p.spot *. normal_cdf (-.d1)

(* ===== Grecques ===== *)

let compute_greeks (p : params) : greeks =
  let { spot = s; strike = k; rate = r; time = t; volatility = sigma; _ } = p in
  let d1     = compute_d1 p in
  let d2     = compute_d2 p in
  let sqrt_t = Float.sqrt t in
  let pdf_d1 = normal_pdf d1 in
  let disc   = exp (-. r *. t) in
  let gamma  = pdf_d1 /. (s *. sigma *. sqrt_t) in
  let vega   = s *. pdf_d1 *. sqrt_t /. 100.0 in
  match p.option_type with
  | Call ->
    { delta = normal_cdf d1
    ; gamma
    ; vega
    ; theta = (-. s *. pdf_d1 *. sigma /. (2.0 *. sqrt_t)
               -. r *. k *. disc *. normal_cdf d2) /. 365.0
    ; rho   = k *. t *. disc *. normal_cdf d2 /. 100.0
    }
  | Put ->
    { delta = normal_cdf d1 -. 1.0
    ; gamma
    ; vega
    ; theta = (-. s *. pdf_d1 *. sigma /. (2.0 *. sqrt_t)
               +. r *. k *. disc *. normal_cdf (-.d2)) /. 365.0
    ; rho   = -. k *. t *. disc *. normal_cdf (-.d2) /. 100.0
    }