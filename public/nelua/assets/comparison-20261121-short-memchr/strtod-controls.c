#define _GNU_SOURCE
#include <errno.h>
#include <inttypes.h>
#include <sched.h>
#include <stdalign.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

struct test_case {
  const char *name;
  const char *text;
  uint64_t bits;
  size_t end_offset;
  int expected_errno;
};

/* Expected binary64 values are fixed IEEE-754 bit patterns, independent of
   the libc under test. End offsets count bytes from the aligned input start. */
static const struct test_case cases[] = {
    {"zero_short", "0", UINT64_C(0x0000000000000000), 1, 0},
    {"one_point_five", "1.5", UINT64_C(0x3ff8000000000000), 3, 0},
    {"exact_half", "0.5", UINT64_C(0x3fe0000000000000), 3, 0},
    {"original_pi", "3.141592653589793", UINT64_C(0x400921fb54442d18), 17, 0},
    {"decimal_exponent_suffix", "1.25e+2x", UINT64_C(0x405f400000000000), 7, 0},
    {"hex_exact", "0x1.8p+1", UINT64_C(0x4008000000000000), 8, 0},
    {"long_decimal_exact_0_1",
     "0.1000000000000000055511151231257827021181583404541015625",
     UINT64_C(0x3fb999999999999a), 57, 0},
    {"round_tie_to_even",
     "1.00000000000000011102230246251565404236316680908203125",
     UINT64_C(0x3ff0000000000000), 55, 0},
    {"max_finite_boundary", "1.7976931348623157e308",
     UINT64_C(0x7fefffffffffffff), 22, 0},
    {"invalid_suffix", "12.5tail", UINT64_C(0x4029000000000000), 4, 0},
    {"no_conversion", "not-a-number", UINT64_C(0x0000000000000000), 0, 0},
    {"overflow_errno", "1e9999", UINT64_C(0x7ff0000000000000), 6, ERANGE},
    {"underflow_errno", "1e-9999", UINT64_C(0x0000000000000000), 7, ERANGE},
};

static const size_t offsets[] = {0, 1, 7, 15, 31};
static alignas(64) unsigned char input_storage[256];
static volatile uint64_t benchmark_sink;

static uint64_t double_bits(double value) {
  uint64_t bits;
  memcpy(&bits, &value, sizeof bits);
  return bits;
}

static int check_one(const struct test_case *test, size_t offset,
                     uint64_t *actual_bits, size_t *actual_end, int *actual_errno) {
  char *input = (char *)input_storage + offset;
  memcpy(input, test->text, strlen(test->text) + 1);
  errno = 0;
  char *end = NULL;
  double value = strtod(input, &end);
  int error = errno;
  size_t end_offset = end ? (size_t)(end - input) : SIZE_MAX;
  uint64_t bits = double_bits(value);

  if (actual_bits) *actual_bits = bits;
  if (actual_end) *actual_end = end_offset;
  if (actual_errno) *actual_errno = error;
  return bits == test->bits && end_offset == test->end_offset && error == test->expected_errno;
}

static int check_all(const char *profile) {
  for (size_t ci = 0; ci < sizeof cases / sizeof cases[0]; ++ci) {
    for (size_t oi = 0; oi < sizeof offsets / sizeof offsets[0]; ++oi) {
      uint64_t bits;
      size_t end;
      int error;
      if (!check_one(&cases[ci], offsets[oi], &bits, &end, &error)) {
        fprintf(stderr,
                "CHECK_FAIL profile=%s case=%s offset=%zu bits=%016" PRIx64
                " expected_bits=%016" PRIx64 " end=%zu expected_end=%zu errno=%d expected_errno=%d\n",
                profile, cases[ci].name, offsets[oi], bits, cases[ci].bits,
                end, cases[ci].end_offset, error, cases[ci].expected_errno);
        return 1;
      }
    }
  }
  printf("CHECK_PASS,%s,%zu_cases,%zu_offsets\n", profile,
         sizeof cases / sizeof cases[0], sizeof offsets / sizeof offsets[0]);
  return 0;
}

static uint64_t now_ns(void) {
  struct timespec time;
  if (clock_gettime(CLOCK_MONOTONIC_RAW, &time) != 0) {
    perror("clock_gettime");
    exit(2);
  }
  return (uint64_t)time.tv_sec * UINT64_C(1000000000) + (uint64_t)time.tv_nsec;
}

static uint64_t run_iterations(char *input, char **end, uint64_t iterations) {
  uint64_t sum = 0;
  for (uint64_t i = 0; i < iterations; ++i) {
    errno = 0;
    double value = strtod(input, end);
    sum += double_bits(value) ^ (uint64_t)(*end - input) ^ (uint64_t)errno;
  }
  return sum;
}

static void benchmark_one(const char *profile, uint64_t round,
                          const struct test_case *test, size_t offset,
                          uint64_t target_ns) {
  char *input = (char *)input_storage + offset;
  memcpy(input, test->text, strlen(test->text) + 1);
  char *end = NULL;
  const uint64_t probe_iterations = 8;
  uint64_t calibration_start = now_ns();
  benchmark_sink ^= run_iterations(input, &end, probe_iterations);
  uint64_t calibration_ns = now_ns() - calibration_start;
  uint64_t calibration_iterations = probe_iterations;

  /* A short probe detects expensive overflow/underflow conversions. Avoid
     thousands of such calls during calibration; use a longer sample only for
     inputs that complete the probe quickly. */
  if (calibration_ns < UINT64_C(100000)) {
    calibration_iterations = 2000;
    calibration_start = now_ns();
    benchmark_sink ^= run_iterations(input, &end, calibration_iterations);
    calibration_ns = now_ns() - calibration_start;
  }
  if (calibration_ns == 0) calibration_ns = 1;
  uint64_t iterations = target_ns * calibration_iterations / calibration_ns;
  if (iterations == 0) iterations = 1;
  if (iterations > UINT64_C(100000000)) iterations = UINT64_C(100000000);

  int cpu_before = sched_getcpu();
  uint64_t start = now_ns();
  uint64_t sum = run_iterations(input, &end, iterations);
  uint64_t elapsed = now_ns() - start;
  int cpu_after = sched_getcpu();
  benchmark_sink ^= sum;

  uint64_t bits;
  size_t end_offset;
  int error;
  (void)check_one(test, offset, &bits, &end_offset, &error);
  printf("%s,%" PRIu64 ",%s,%zu,%" PRIu64 ",%" PRIu64 ",%.3f,%016" PRIx64 ",%zu,%d,%d,%d\n",
         profile, round, test->name, offset, iterations, elapsed,
         (double)elapsed / (double)iterations, bits, end_offset, error,
         cpu_before, cpu_after);
}

int main(int argc, char **argv) {
  const char *profile = "unspecified";
  uint64_t target_ms = 0;
  uint64_t round = 0;
  int check = 0;
  for (int i = 1; i < argc; ++i) {
    if (strcmp(argv[i], "--profile") == 0 && i + 1 < argc) profile = argv[++i];
    else if (strcmp(argv[i], "--check") == 0) check = 1;
    else if (strcmp(argv[i], "--round") == 0 && i + 1 < argc) round = strtoull(argv[++i], NULL, 10);
    else if (strcmp(argv[i], "--bench-ms") == 0 && i + 1 < argc) target_ms = strtoull(argv[++i], NULL, 10);
    else {
      fprintf(stderr, "usage: %s --profile NAME [--round N] (--check | --bench-ms MILLISECONDS)\n", argv[0]);
      return 2;
    }
  }
  if (check == (target_ms != 0)) {
    fprintf(stderr, "select exactly one of --check or --bench-ms MILLISECONDS\n");
    return 2;
  }
  if (check) return check_all(profile);

  puts("profile,round,case,offset,iterations,elapsed_ns,ns_per_call,bits,end_offset,errno,cpu_before,cpu_after");
  for (size_t ci = 0; ci < sizeof cases / sizeof cases[0]; ++ci) {
    for (size_t oi = 0; oi < sizeof offsets / sizeof offsets[0]; ++oi) {
      benchmark_one(profile, round, &cases[ci], offsets[oi], target_ms * UINT64_C(1000000));
    }
  }
  fprintf(stderr, "sink=%016" PRIx64 "\n", benchmark_sink);
  return 0;
}
