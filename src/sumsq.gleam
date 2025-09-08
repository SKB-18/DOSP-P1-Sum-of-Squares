import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import timekit

@external(erlang, "init", "get_plain_arguments")
fn raw_plain_args() -> List(List(Int))

@external(erlang, "erlang", "list_to_binary")
fn list_to_binary(chars: List(Int)) -> String

fn argv() -> List(String) {
  list.map(raw_plain_args(), list_to_binary)
}

@external(erlang, "erlang", "div")
fn idiv(a: Int, b: Int) -> Int

// ---------- Math utilities ----------

// Sum of squares from 1 to n: n(n+1)(2n+1)/6
fn s(n: Int) -> Int {
  case n <= 0 {
    True -> 0
    False -> idiv(n * { n + 1 } * { 2 * n + 1 }, 6)
  }
}

// Sum of k consecutive squares starting at i: S(i+k-1) - S(i-1)
pub fn window_sum_squares(i: Int, k: Int) -> Int {
  s(i + k - 1) - s(i - 1)
}

// Top-level helper for integer sqrt (binary search, floor)
fn isqrt_loop(lo: Int, hi: Int, n: Int) -> Int {
  case lo > hi {
    True -> hi
    False -> {
      let mid = idiv(lo + hi, 2)
      let sq = mid * mid
      case sq == n {
        True -> mid
        False -> {
          case sq < n {
            True -> isqrt_loop(mid + 1, hi, n)
            False -> isqrt_loop(lo, mid - 1, n)
          }
        }
      }
    }
  }
}

// Integer sqrt via binary search (exact floor)
fn isqrt(n: Int) -> Int {
  case n < 0 {
    True -> 0
    False -> isqrt_loop(0, n, n)
  }
}

pub fn is_perfect_square(n: Int) -> Bool {
  case n < 0 {
    True -> False
    False -> {
      let r = isqrt(n)
      r * r == n
    }
  }
}

// ---------- Work partitioning ----------

const batch_size = 500

fn min(a: Int, b: Int) -> Int {
  case a < b {
    True -> a
    False -> b
  }
}

// Top-level batch builder
fn make_batches_go(
  i: Int,
  max_start: Int,
  unit: Int,
  acc: List(#(Int, Int)),
) -> List(#(Int, Int)) {
  case i > max_start {
    True -> list.reverse(acc)
    False -> {
      let j = min(max_start, i + unit - 1)
      make_batches_go(i + unit, max_start, unit, [#(i, j), ..acc])
    }
  }
}

// Make batches of (start, stop) indices for i in 1..max_start
fn make_batches(max_start: Int, unit: Int) -> List(#(Int, Int)) {
  make_batches_go(1, max_start, unit, [])
}

// Range scanner
fn valid_in_range_loop(i: Int, stop: Int, k: Int, acc: List(Int)) -> List(Int) {
  case i > stop {
    True -> list.reverse(acc)
    False -> {
      let sum = window_sum_squares(i, k)
      let acc2 = case is_perfect_square(sum) {
        True -> [i, ..acc]
        False -> acc
      }
      valid_in_range_loop(i + 1, stop, k, acc2)
    }
  }
}

// Find valid starting indices within [start..stop] for fixed k
pub fn valid_in_range(start: Int, stop: Int, k: Int) -> List(Int) {
  valid_in_range_loop(start, stop, k, [])
}

// ---------- Messages & Actors ----------

pub type Signal {
  Completed
}

pub type WorkerMsg {
  Do(start: Int, stop: Int, k: Int, reply_to: process.Subject(BossMsg))
}

pub type BossMsg {
  Run(
    boss: process.Subject(BossMsg),
    n: Int,
    k: Int,
    done: process.Subject(Signal),
  )
  BatchDone(valid: List(Int))
}

pub type BossState {
  BossState(
    outstanding: Int,
    results: List(Int),
    done: Option(process.Subject(Signal)),
    unit: Int,
  )
}

fn worker_handle(_state: Nil, msg: WorkerMsg) -> actor.Next(Nil, WorkerMsg) {
  case msg {
    Do(start, stop, k, reply_to) -> {
      let found = valid_in_range(start, stop, k)
      actor.send(reply_to, BatchDone(found))
      actor.stop()
    }
  }
}

fn boss_handle(state: BossState, msg: BossMsg) -> actor.Next(BossState, BossMsg) {
  case msg {
    Run(boss, n, k, done) -> {
      // NEW: handle degenerate inputs without hanging and print the requested message
      case n <= 0 || k <= 0 {
        True -> {
          io.println("no output")
          process.send(done, Completed)
          actor.stop()
        }
        False -> {
          let batches = make_batches(n, state.unit)

          // Spawn one worker per batch
          list.each(batches, fn(batch) {
            let #(start, stop) = batch

            let assert Ok(started) =
              actor.new(Nil)
              |> actor.on_message(worker_handle)
              |> actor.start()

            let worker = started.data
            actor.send(worker, Do(start, stop, k, boss))
          })

          actor.continue(
            BossState(
              ..state,
              outstanding: list.length(batches),
              done: Some(done),
            ),
          )
        }
      }
    }

    BatchDone(valid) -> {
      let remaining = state.outstanding - 1
      let results2 = list.append(valid, state.results)

      case remaining == 0 {
        True -> {
          let sorted = list.sort(results2, by: int.compare)

          case sorted {
            [] -> io.println("no output")
            _ -> list.each(sorted, fn(i) { io.println(int.to_string(i)) })
          }

          case state.done {
            Some(done) -> process.send(done, Completed)
            None -> Nil
          }
          actor.stop()
        }
        False ->
          actor.continue(
            BossState(..state, outstanding: remaining, results: results2),
          )
      }
    }
  }
}

// ---------- Public entrypoint ----------

pub fn main() {
  let usage = fn() { io.println("Usage: gleam run -- <N> <K> [--metrics]") }

  case argv() {
    [n_s, k_s] -> run(n_s, k_s, False, usage)
    [n_s, k_s, flag] -> {
      case flag {
        "--metrics" -> run(n_s, k_s, True, usage)
        "-m" -> run(n_s, k_s, True, usage)
        _ -> usage()
      }
    }
    _ -> usage()
  }
}

fn run(n_s: String, k_s: String, metrics: Bool, usage: fn() -> Nil) {
  case int.parse(n_s), int.parse(k_s) {
    Ok(n), Ok(k) -> {
      case n >= 1 && k >= 1 {
        True -> {
          let t = timekit.start()

          let assert Ok(started) =
            actor.new(BossState(0, [], None, batch_size))
            |> actor.on_message(boss_handle)
            |> actor.start()

          let boss = started.data
          let done = process.new_subject()
          actor.send(boss, Run(boss, n, k, done))

          let _ = process.receive_forever(done)

          case metrics {
            True -> {
              let timekit.Snapshot(cpu_ms, real_ms, ratio) = timekit.stop(t)

              io.println("METRIC real_ms=" <> int.to_string(real_ms))
              io.println("METRIC cpu_ms=" <> int.to_string(cpu_ms))
              io.println("METRIC cpu_per_real=" <> float.to_string(ratio))
              io.println(
                "METRIC schedulers_online="
                <> int.to_string(timekit.schedulers_online()),
              )
              io.println(
                "METRIC logical_processors_avail="
                <> int.to_string(timekit.logical_processors_available()),
              )

              // Optional hint when the window is too small to judge parallelism
              case real_ms < 10 {
                True -> io.println("NOTE metrics_window_too_small_for_ratio")
                False -> Nil
              }
            }
            False -> Nil
          }

          Nil
        }
        False -> usage()
      }
    }
    _, _ -> usage()
  }
}
