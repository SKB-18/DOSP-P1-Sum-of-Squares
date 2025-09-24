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
| full  | **2000** | 1000 | 2000 run screenshot (`/mnt/data/9e2a2f77-a31c-465f-86c8-d89a2a1dbbe6.png`), plus `results.txt` up to 1000 |
| imp3D | 1000 | 1000 | `results.txt` |
| 3D    | 1000 | 1000 | `results.txt` |
| line  | 1000 | 1000 | `results.txt` |

> If you run larger sizes later (e.g., 1500–3000) for other topologies/algorithms, update the table accordingly.

---

## Reproducing the Plots

1. Run experiments and append each result as a line to `results.txt` in either of the accepted formats:
   - Pretty: `n=<N> topology=<top> algorithm=<alg> ms=<time_ms>`
   - CSV:    `PLOT,<N>,<top>,<alg>,<time_ms>`
2. Generate graphs:
   ```bash
   python3 plot_results.py results.txt
   # optional flags
   #   --no-nudge  (turn off small y–nudges that prevent line crossings)
   #   --ymax 12000
   #   --logy
   ```
3. Check output files created in the same folder:
   - `gossip_times.png`
   - `pushsum_times.png`

> The script auto-detects UTF-8/UTF-16 encodings in `results.txt` and safely merges duplicate (N, topology, algorithm) entries by keeping the latest value. It overlays all four topologies on a single chart for each algorithm.

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

# A few smaller examples
gleam run 1000 imp3D push-sum
gleam run 500 3D gossip
gleam run 100 line push-sum
```

If you want to benchmark at scale, script multiple runs and append the output lines into `results.txt`, then re-run `plot_results.py`.

---

## Notes / Deviations (if any)
- Plots are provided as PNGs. If your course portal requests a **Report.pdf**, you can paste these two figures with a short commentary and export to PDF.
- The termination conditions follow the spec: **Gossip** actors stop after hearing the rumor a fixed number of times; **Push–Sum** actors stop when the `s/w` ratio stabilizes below a small epsilon over consecutive rounds.
- No failure model is included in this base submission. Add a `Report-bonus.pdf` if you later implement node/edge failure experiments.

---

## Screenshots
- Largest run (2000 nodes, full, gossip): `/mnt/data/9e2a2f77-a31c-465f-86c8-d89a2a1dbbe6.png`
- Plots: `gossip_times.png`, `pushsum_times.png`

---

## License
Academic use for the course project.
