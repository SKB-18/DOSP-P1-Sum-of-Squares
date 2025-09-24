# Project 2 — Gossip & Push–Sum (Gleam Actors)

## Team Members
- Kaushik Bhargav Siddani
- Thandava Rohit Achanta

> Add any additional teammate names above if applicable.

---

## What’s Working
- **Both algorithms**: `gossip` (rumor spread) and `push-sum` (average/sum via s/w ratio).
- **Topologies** implemented and tested: `full`, `3D`, `line`, `imp3D`.
- **Actor-based simulator**: built with **Gleam** actors. The CLI is called as:
  ```bash
  gleam run <numNodes> <topology> <algorithm>
  # example (largest demo): 
  gleam run 2000 full gossip
  ```
- **Output**: program prints the **convergence time in ms** for the given run (captured into `results.txt` during experiments).
- **Plots**: `plot_results.py` parses `results.txt` and generates two graphs with all four topologies overlaid:
  - `gossip_times.png`
  - `pushsum_times.png`

---

## Largest Network Size Reached (per Topology × Algorithm)
> Based on the attached experiment log and screenshots.

| Topology | Gossip (max n) | Push–Sum (max n) | Evidence |
|---|---:|---:|---|
| full  | **2000** | 1000 | 2000 run screenshot (`n=2000 topology=full algorithm=gossip ms=6308`), plus `n=2000 topology=full algorithm=push-sum ms=4019`|
| imp3D | 1000 | 1000 | `results.txt` |
| 3D    | 1000 | 1000 | `results.txt` |
| line  | 1000 | 1000 | `results.txt` |


---

## Files of Interest
- `project2_args.erl` — small Erlang shim to pass raw CLI args into Gleam as proper binaries (so Gleam sees correct `String`s).
- `project2.gleam`, `gossip_actor.gleam`, `project2_test.gleam` — core Gleam sources and test harness.
- `results.txt` — collected timing data.
- `plot_results.py` — plotting utility (headless-safe; produces PNGs).

---

## How to Run

```bash
# Gossip on a full graph (demoing the largest recorded run)
gleam run 2000 full gossip

---

