import gleam/list
import gleeunit
import gleeunit/should
import sumsq

pub fn main() {
  gleeunit.main()
}

pub fn math_is_square_test() {
  should.equal(sumsq.is_perfect_square(1), True)
  should.equal(sumsq.is_perfect_square(16), True)
  should.equal(sumsq.is_perfect_square(15), False)
  should.equal(sumsq.is_perfect_square(0), True)
}

pub fn window_sum_test() {
  // 3^2 + 4^2 = 25
  should.equal(sumsq.window_sum_squares(3, 2), 25)
  should.equal(sumsq.is_perfect_square(sumsq.window_sum_squares(3, 2)), True)
}

pub fn small_range_finds_known_solution_test() {
  // For k = 2 within 1..10 we expect starting index 3 to be valid
  let found = sumsq.valid_in_range(1, 10, 2)
  should.equal(list.contains(found, 3), True)
}

pub fn batching_bounds_test() {
  // No panics when k > n; expect empty work.
  let found = sumsq.valid_in_range(1, 0, 5)
  should.equal(found, [])
}
