
# Project 1 — Sums of Consecutive Squares (DOSP / Gleam)

> **Mapping to spec**: the PDF refers to running `lukas N K`in the pdf. In this repo you run the Gleam binary with two positional args `N K` and an optional `--metrics` flag:
>
> ```powershell
> gleam run -- <N> <K> [--metrics]
> ```

---

## 1) How to build & run

- Requirements: Erlang/OTP (>= 25), Gleam (>= 1.2)
- Go to the path where the toml file is present
- (Optional when changing batch size) Clean:
  ```powershell
  gleam clean
  ```
  - Download deps:
  ```powershell
  gleam deps download
  ```
- Build:
  ```powershell
  gleam build
  ```
- Run (example & required by spec):
  ```powershell
  # Required run: N=1_000_000, K=4
  gleam run -- 1000000 4 --metrics
  gleam test  # Run the tests
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

**How it was determined** — we measured REAL and CPU times for `N=1000000, K=4` over several batch sizes and picked the **lowest REAL TIME** (primary) while also observing the **CPU/REAL ratio** (parallel efficiency).

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
  For `K = 4`, there are no start indices `i ≤ 1000000` such that the sum of 4 consecutive squares starting at `i` is a perfect square.

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

## 5) Largest problem solved (spec item)

- **Command**:
  ```powershell
  gleam run -- 9999999 999 --metrics
  ```
- **Program output**: `no output` (no solutions for these parameters).
- **Metrics**:
  ```
  METRIC real_ms=1934
  METRIC cpu_ms=23312
  METRIC cpu_per_real=12.05377456049638
  METRIC schedulers_online=22
  METRIC logical_processors_avail=22

---
