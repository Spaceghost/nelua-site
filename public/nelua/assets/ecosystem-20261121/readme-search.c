#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

int main(int argc, char **argv) {
  if (argc != 2) return 1;
  FILE *f = fopen(argv[1], "rb");
  if (!f || fseek(f, 0, SEEK_END)) return 2;
  long length = ftell(f);
  rewind(f);
  char *text = calloc(length + 1, 1);
  if (!text || fread(text, 1, length, f) != (size_t)length) return 3;
  fclose(f);
  const char *terms[] = {"nelibc", "benchmark", "unfindable-term-0831"};
  for (int i = 0; i < 3; i++) {
    size_t n = strlen(terms[i]);
    char *expected = NULL;
    for (size_t j = 0; j + n <= (size_t)length; j++)
      if (!memcmp(text+j, terms[i], n)) { expected = text+j; break; }
    for (int mode = 0; mode < 2; mode++) {
      struct timespec a, b;
      char *(*volatile string_search)(const char *, const char *) = strstr;
      void *(*volatile byte_search)(const void *, size_t, const void *, size_t) = memmem;
      clock_gettime(CLOCK_MONOTONIC, &a);
      for (int j = 0; j < 512; j++) {
        char *found = mode ? byte_search(text,length,terms[i],n) : string_search(text,terms[i]);
        if (found != expected) return 4;
      }
      clock_gettime(CLOCK_MONOTONIC, &b);
      double ns = (b.tv_sec-a.tv_sec)*1e9 + b.tv_nsec-a.tv_nsec;
      printf("%s,%s,%ld,%.2f\n",mode ? "memmem" : "strstr",terms[i],expected ? (long)(expected-text) : -1L,ns/512);
    }
  }
  free(text);
}
