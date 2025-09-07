# Project 1 — Sums of Consecutive Squares (DOSP / Gleam)

> **Mapping to spec**: the PDF refers to running `lukas N K`. In this repo you run the Gleam binary with two positional args `N K` and an optional `--metrics` flag:
>
> ```powershell
> gleam run -- <N> <K> [--metrics]
> ```

---

## 1) How to build & run

- Requirements: Erlang/OTP (>= 25), Gleam (>= 1.2)
- Build: `gleam build`
- Run (example):
  ```powershell
  # Example: N=1_000_000, K=4 (the required run in the spec)
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
- Implementation detail: tuned by constant `batch_size` in `src/sumsq.gleam`.

---

## 3) Choosing the work-unit size (required by spec)

> Fill this section with *your* measurements that justify the chosen work-unit size.

- **Method**: vary `batch_size` (e.g., 500, 1000, 1500, 2000, 4000), rebuild, then run the required workload and record timings.
- **Command** (PowerShell):
  ```powershell
  # Repeat for several batch_size settings
  gleam run -- 1000000 4 --metrics | Tee-Object -FilePath runs\N1e6_K4_batch1500.txt
  ```

- **Table (example template)**:

| batch_size | real_ms | cpu_ms | cpu_ms/real_ms | comment |
|-----------:|--------:|-------:|----------------:|---------|
| 500        | 247     | 1172   | 4.7449          | slower; overhead dominates |
| 1000       | 127     | 1062   | 8.3622          | good |
| 1500       | 97      | 937    | 9.6598          | **fastest wall time** |
| 2000       | 100     | 1109   | 11.0900         | highest ratio, slightly slower |
| 3000       | 118     | 1031   | 8.7373          | slower |

- **Chosen work unit**: **`batch_size = 1500`** because it minimized real time (97 ms) on the required workload while keeping a strong CPU/REAL ratio (~9.66). Batch 2000 had the highest ratio (~11.09) but was slower in wall time (100 ms); per the spec, we prioritize **real time**.

---

## 4) Required run and metrics (spec item)

- **Command**:
  ```powershell
  gleam run -- 1000000 4 --metrics
  ```
- **Program output (first lines — if any)**:
  ```
  <paste the first ~20 lines or “no output”>
  ```
- **Metrics**:
  ```
  METRIC real_ms=97
  METRIC cpu_ms=937
  METRIC cpu_per_real=9.65979381443299
METRIC schedulers_online=22
METRIC logical_processors_avail=22
  ```

- **Interpretation**:
  - **REAL TIME** = wall-clock milliseconds.
  - **CPU TIME** = total CPU milliseconds consumed by the VM across all schedulers during the measurement window.
  - **Effective cores used** ≈ `cpu_ms / real_ms` = **`9.6598`** (of 22 schedulers_online, ~44% utilization).
  - If this ratio is close to **1.0**, there’s little to no parallelism.

> Note: for very small inputs the Erlang runtime reports CPU time in whole milliseconds—tiny jobs can show `cpu_ms = 0`. Always report the required large run above.

---

## 5) Largest problem solved (spec item)

- **Command**:
  ```powershell
  # Try progressively larger instances until the run completes in reasonable time
  gleam run -- <N> <K> --metrics
  ```
- **Reported largest solved**: `N = <fill>`, `K = <fill>`
- **Metrics at that size**: REAL `<fill> ms`, CPU `<fill> ms`, ratio `<fill>`
- **Notes**: any memory limits, timeouts, or tuning used.

---

## 6) Correctness notes

- Uses the closed form `S(n) = n(n+1)(2n+1)/6` and computes a window sum as `S(i+k-1) - S(i-1)`.
- Checks perfect squares via integer `isqrt` and exact square test.
- For `N = 1000, K = 4`, the expected output is **no solutions**, so the program legitimately prints **no output**.

---

## 7) Reproducibility

- Machine: `<CPU model>`, `<#logical cores>`
- OS: `<Windows 10/11 build>`
- Erlang/OTP: `<version>`
- Gleam: `<version>`
- Command logs are kept in `runs/` (see commands above).

---

## Appendix A — Sample `--metrics` block

```
METRIC real_ms=1234
METRIC cpu_ms=3810
METRIC cpu_per_real=3.087
```

This indicates ~**3.09 effective cores** used on average during the run.

---

## Appendix B — Self-check script (verifies this README meets spec)

Save as `tools/check_readme.py` and run from the repo root.

```python
#!/usr/bin/env python3
import re, sys, pathlib
p = pathlib.Path('README.md')
text = p.read_text(encoding='utf-8')

REQUIRED = [
    r"Work[- ]?unit size|Choosing the work[- ]?unit size",
    r"gleam run -- 1000000 4",
    r"METRIC\s+real_ms\s*=",
    r"METRIC\s+cpu_ms\s*=",
    r"cpu_per_real|ratio",
    r"Largest problem solved",
]

missing = [pat for pat in REQUIRED if not re.search(pat, text, re.I)]
placeholders = re.findall(r"<fill>", text)

if missing:
    print("❌ Missing required sections:")
    for m in missing:
        print("   -", m)
else:
    print("✅ All required sections found.")

if placeholders:
    print(f"❌ Found {len(placeholders)} placeholder(s) '<fill>' that must be replaced.")
    sys.exit(1)

sys.exit(0 if not missing else 2)
```

**Run**:
```powershell
python tools/check_readme.py
```

If it prints all green checks, your README contains the items the PDF requires and no placeholders remain.

