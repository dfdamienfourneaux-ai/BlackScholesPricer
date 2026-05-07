# bs-pricer

A Black-Scholes options pricer built in OCaml — my first real step into quantitative finance.

I'm a data engineer transitioning into quant/trading. This project was a way to learn two things at once: the mathematics behind options pricing, and idiomatic OCaml. No shortcuts, no black boxes — I wanted to understand every line.

---

## What it does

Given an underlying asset and market parameters, it computes:

- **Call and Put prices** via the Black-Scholes closed-form formula
- **The Greeks** — Delta, Gamma, Vega, Theta, Rho

```bash
$ bs-pricer --spot 100 --strike 105 --rate 0.05 --time 1.0 --vol 0.20 --type call

=== Black-Scholes Pricer ===
Type   : Call
Spot   : 100.00 | Strike : 105.00
Rate   : 5.0% | Time : 1.00 yr | Vol : 20.0%

--- Prix ---
Call   : 8.0214
Put    : 7.9004

--- Grecques (Call) ---
Delta  :  0.5422
Gamma  :  0.0198
Vega   :  0.3967
Theta : -0.0172  (par jour)
Rho    :  0.4620
```

---

## The math

Black-Scholes prices a European option under the assumption that the underlying follows a geometric Brownian motion:

$$C = S \cdot N(d_1) - K e^{-rT} \cdot N(d_2)$$
$$P = K e^{-rT} \cdot N(-d_2) - S \cdot N(-d_1)$$

Where:

$$d_1 = \frac{\ln(S/K) + (r + \sigma^2/2)T}{\sigma\sqrt{T}}, \quad d_2 = d_1 - \sigma\sqrt{T}$$

| Parameter | Meaning |
|---|---|
| S | Current spot price |
| K | Strike price |
| r | Risk-free interest rate |
| T | Time to expiry (in years) |
| σ | Implied volatility |
| N(·) | Standard normal CDF |

---

## Getting started

**Requirements:** OCaml ≥ 4.14, OPAM, Dune

```bash
git clone https://github.com/dfdamienfourneaux-ai/BlackScholesPricer
cd bs-pricer
dune build
dune exec bin/main.exe -- --spot 100 --strike 100 --rate 0.05 --time 1.0 --vol 0.20 --type call
```

---

## Project structure

```
bs_pricer/
├── lib/
│   ├── black_scholes.ml   # Pricing logic and Greeks
│   └── cli.ml             # Argument parsing and error handling
├── bin/
│   └── main.ml            # Entry point
└── dune-project
```

---

## Roadmap

- [x] Black-Scholes analytical formula (Call & Put)
- [x] Greeks (Delta, Gamma, Vega, Theta, Rho)
- [x] CLI with input validation
- [ ] Monte-Carlo simulation & comparison with analytical price
- [ ] Implied volatility solver

---

## Why OCaml?

OCaml is increasingly used in quantitative finance (Jane Street being the most visible example). Its strong type system catches entire categories of bugs at compile time — a property that matters a lot when the output is a price. It also forced me to think more carefully about every function I wrote, which turned out to be a good thing.