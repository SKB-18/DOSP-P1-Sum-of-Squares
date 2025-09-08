# Project 1 — Sums of Consecutive Squares (DOSP / Gleam)

> **Mapping to spec**: the PDF refers to running `lukas N K`. In this repo you run the Gleam binary with two positional args `N K` and an optional `--metrics` flag:
>
> ```powershell
> gleam run -- <N> <K> [--metrics]
> ```

---

## 0) Setup & dependencies

- Get the code (clone or unzip) and open a shell **at the repo root**.
- Download deps:
  ```powershell
  gleam deps download
  ```

---

## 1) How to build & run

- Requirements: Erlang/OTP (>= 25), Gleam (>= 1.2)
- (Optional when changing batch size) Clean:
  ```powershell
  gleam clean
  ```
- Build:
  ```powershell
  gleam build
  ```
- Run (example & required by spec):
  ```powershell
  # Required run: N=1_000_000, K=4
  gleam run -- 1000000 4 --metrics
  ```
- Output semantics:
  - Prints each valid **start index** on its own line (no decoration).
  - Prints **no output** if there are no solutions for given `N, K`.
  - With `--metrics`, prints timing metrics at the end.

---

## 2) Actor model & work unit (what is being parallelized?)

- **Actors**: one **boss** actor partitions the range of start indices; multiple **workers** (spawned under the boss) scan their assigned subranges and reply.
- **Work unit**: the **number of consecutive start indices** a worker receives and scans per request.
- Implementation detail: controlled by constant `batch_size` in `src/sumsq.gleam`.

---

## 3) Work‑unit size you determined (required by spec)

**Chosen work unit**: **`batch_size = 2000`**

**How it was determined** — we measured REAL and CPU times for `N=1_000_000, K=4` over several batch sizes and picked the **lowest REAL TIME** (primary) while also observing the **CPU/REAL ratio** (parallel efficiency).

| batch_size | real_ms | cpu_ms | ratio (cpu_ms/real_ms) |
|-----------:|--------:|-------:|-----------------------:|
| 500        | 247     | 1172   | 4.7449                 |
| 1000       | 127     | 1062   | 8.3622                 |
| 1500       | 111     | 1172   | 10.5586                | 
| **2000**   | **100** | **1109** | **11.0900**          |
| 3000       | 118     | 1031   | 8.7373                 |

**Decision**: `batch_size = 2000` because it achieved the **fastest wall time** and the **highest average scheduler utilization** without increasing tail imbalance.

---

## 4) Result of running `gleam run -- 1000000 4` (required by spec)

- **Command**:
  ```powershell
  gleam run -- 1000000 4 --metrics
  ```
- **Program output**:
  ```
  no output
  ```
  For `K = 4`, there are no start indices `i ≤ 1_000_000` such that the sum of 4 consecutive squares starting at `i` is a perfect square.

- **Metrics (batch_size = 2000)**:
  ```
  METRIC real_ms=100
  METRIC cpu_ms=1109
  METRIC cpu_per_real=11.09
  METRIC schedulers_online=22
  METRIC logical_processors_avail=22
  ```

- **Interpretation**:
  - **REAL TIME** = wall-clock milliseconds for the run.
  - **CPU TIME** = total CPU milliseconds consumed by the Erlang VM across all schedulers during the same window.
  - **Effective cores used** ≈ `cpu_ms / real_ms` = **11.09** (of 22 online schedulers ⇒ ~50.4% average utilization during the window).
  - A ratio near **1.0** would indicate almost no parallelism; our ratio shows healthy parallel execution.

> Note: For very small inputs the runtime reports CPU in whole milliseconds; tiny jobs may show `cpu_ms = 0`. Always use the large required run above for evaluation.

---

## 5) Largest problem solved (required by spec)

- **Largest completed**: `N = 1_000_000`, `K = 4` (required run)
- **Metrics at that size** (batch 2000): REAL **100 ms**, CPU **1109 ms**, ratio **11.09**
- **Notes**: The computation is parallel actor-based; increasing `N` further should scale roughly linearly until memory/cache or scheduler contention dominates. If extending, keep the measured ratio < `schedulers_online` and prioritize REAL TIME when tuning `batch_size`.

---

## 6) Correctness notes

- Uses the closed form `S(n) = n(n+1)(2n+1)/6` and computes a window sum as `S(i+k-1) - S(i-1)`.
- Checks perfect squares via integer `isqrt` and exact square test.
- For `N = 1000, K = 4` and `N = 1_000_000, K = 4`, the program legitimately prints **no output** because there are no solutions in those ranges.

---

## 7) Reproducibility

- Machine: `<CPU model>`, `<#logical cores>`
- OS: `<Windows 10/11 build>`
- Erlang/OTP: `<version>`
- Gleam: `<version>`
- Command logs can be saved under `runs/` (e.g., using `Tee-Object`).



---

## 8) Step‑by‑step: collect and evaluate metrics (as required in the PDF)

### A) Prepare
1. **Pick a batch size**: edit `const batch_size = <value>` in `src/sumsq.gleam`.
2. **Clean & build** (recommended when changing batch):
   ```powershell
   gleam clean
   gleam build
   ```

### B) Run with metrics
3. **Run the required workload** and optionally save the metrics:
   ```powershell
   gleam run -- 1000000 4 --metrics | Tee-Object -FilePath runs/N1e6_K4_batch_value.txt
   ```
   You should see lines like:
   ```
   METRIC real_ms=...
   METRIC cpu_ms=...
   METRIC cpu_per_real=...
   METRIC schedulers_online=...
   METRIC logical_processors_avail=...
   ```

### C) Interpret the numbers
4. **Compute the ratio**: `cpu_per_real = cpu_ms / real_ms` (already printed). This approximates **effective cores used**.
5. **Compute average scheduler utilization** (optional but informative): `util = cpu_per_real / schedulers_online`.
   - Example (batch **2000**): `1109 / 100 = 11.09` → `11.09/22 = 0.504` → **50.4%** of schedulers utilized on average.
6. **Pick the best batch**: prefer the **lowest real_ms**; use the ratio/utilization as a tie‑breaker. Avoid values where larger batches start to increase `real_ms` due to tail imbalance or cache effects.

### D) Fill the README per the PDF
7. In **Section 3**, paste your table and mark the chosen batch size.
8. In **Section 4**, paste one full `--metrics` block for the chosen batch and include the brief interpretation (REAL, CPU, ratio, and effective cores vs. schedulers).
9. In **Section 5**, state the **largest problem solved** and its metrics. If extending beyond `N=1_000_000`, note any limits.

### E) Common gotchas
- Tiny inputs can yield `cpu_ms = 0` because the VM reports CPU in whole ms for short windows; always judge with the required large run.
- Ensure `schedulers_online` matches expectations for your machine; it bounds the maximum ratio you’ll see.
- When changing batch size, re‑build after a `gleam clean` to avoid stale binaries.

