#include "lz4.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
static double now(void) {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return ts.tv_sec + ts.tv_nsec * 1.e-9;
}
int main(int argc, char **argv) {
  if (argc != 5) return 1;
  FILE *in = fopen(argv[1], "rb");
  if (!in || fseek(in, 0, SEEK_END)) return 2;
  long size = ftell(in);
  if (size <= 0 || size > LZ4_MAX_INPUT_SIZE) return 3;
  rewind(in);
  int n = (int)size, bound = LZ4_compressBound(n);
  char *src = malloc(n), *compressed = malloc(bound), *decoded = malloc(n);
  if (!src || !compressed || !decoded || fread(src, 1, n, in) != (size_t)n) return 4;
  fclose(in);
  int acceleration = atoi(argv[2]), repeats = atoi(argv[3]), bytes = 0;
  double start = now();
  for (int i=0; i<repeats; ++i) {
    bytes = LZ4_compress_fast(src, compressed, n, bound, acceleration);
    if (!bytes) return 5;
  }
  double encode = now()-start;
  start = now();
  for (int i=0; i<repeats; ++i)
    if (LZ4_decompress_safe(compressed, decoded, bytes, n) != n) return 6;
  double decode = now()-start;
  if (memcmp(src, decoded, n)) return 7;
  FILE *out = fopen(argv[4], "wb");
  if (!out || fwrite(compressed,1,bytes,out) != (size_t)bytes || fclose(out)) return 8;
  printf("%d %.6f %.6f\n", bytes, 1000*encode/repeats, 1000*decode/repeats);
  return 0;
}
