# Repeat the 64 KiB substring comparison

The three GCC consumers search for the four-byte string `abaa`. All three inputs lack a match. One begins with 16 bytes of `a` followed by `b`, another begins with 16 bytes of `b` followed by `a`, and the third alternates the two bytes. The same C benchmark checks random inputs and guard pages before it times each executable. Each process returns its median time across seven sets of 256 searches.

The [driver](repeat.py) builds the same C input three ways, using system glibc, the previous Nelibc archive, and the updated archive. It runs the six possible orders, then repeats them in reverse. The [compact CSV](strstr-repeat-64k.csv) has 108 measurements for the 64 KiB inputs. The [complete CSV](strstr-repeat-all.csv) also includes 64-byte and 4 KiB inputs. Divide times from the same round before taking the median to reproduce the speedup and observed range. The [manifest](strstr-repeat-manifest.json) records the source, executable and archive hashes, the toolchain, CPU placement and all execution orders.

Use a Linux x86-64 checkout with both GCC production archives built as described in the [main comparison](../comparison-20261121-gap-fixes/reproduce.md). Supply the full path to the current checkout and to the saved previous archive. Run as an unprivileged user. Choose a logical CPU inside the process affinity mask. The reported run used CPU 3 of an Intel Core i5-10400 with GCC 12.2 and glibc 2.36.

```sh
python3 repeat.py --source "$NELIBC" --previous-archive "$PREVIOUS/libnelibc-gcc.a" \
  --revision 70bcd89457f2b1433916747df715ea8546e54ffb \
  --previous-commit f9ae990711f50a3e2b5cec670cd56d1867969ef7 --cpu 3 --out repeat-results
```

For comparison, the [preceding runs](../strstr-repeat-20261121/strstr-repeat-64k.csv) used the same byte distributions with the earlier revisions.
