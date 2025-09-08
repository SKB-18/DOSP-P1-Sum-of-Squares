//// src/timekit.gleam

@external(erlang, "time_ffi", "reset")
fn reset() -> Nil

@external(erlang, "time_ffi", "read")
fn read() -> #(Int, Int)

@external(erlang, "time_ffi", "to_float")
fn to_float(i: Int) -> Float

@external(erlang, "time_ffi", "fdiv")
fn fdiv(a: Float, b: Float) -> Float

@external(erlang, "time_ffi", "schedulers")
fn schedulers() -> Int

@external(erlang, "time_ffi", "logical_processors")
fn logical_processors() -> Int

pub type Timer {
  Timer
}

pub fn start() -> Timer {
  let _ = reset()
  Timer
}

pub type Snapshot {
  Snapshot(cpu_ms: Int, real_ms: Int, cpu_per_real: Float)
}

pub fn stop(_t: Timer) -> Snapshot {
  let #(cpu_ms, real_ms) = read()
  let ratio = case real_ms {
    0 -> 0.0
    _ -> fdiv(to_float(cpu_ms), to_float(real_ms))
  }
  Snapshot(cpu_ms, real_ms, ratio)
}

pub fn schedulers_online() -> Int {
  schedulers()
}

pub fn logical_processors_available() -> Int {
  logical_processors()
}
