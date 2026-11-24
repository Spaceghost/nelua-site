import { readFileSync } from 'node:fs'
export const title = "nelibc · a C library written in Nelua · spacegho.st/nelua"
export const description = "nelibc replaces C library functions with Nelua implementations: hybrid archives over glibc, musl or Cosmopolitan, a standalone Linux x86-64 runtime, and a host profile for kernels. Compare symbol coverage for glibc, musl and Cosmopolitan."

const nelibcPassRows = [
	["strstr · ab / aa", "39.00", "3.58", "2.39"]
	["strstr · 63 / 64 a bytes", "1.62", "1.70", "5.83"]
	["strstr · One interior b", "116.86", "1.30", "268.19"]
	["memmem · ab / aa", "217.42", "2.86", "43.11"]
	["memmem · 63 / 64 a bytes", "0.98", "1.05", "7.91"]
	["memmem · One interior b", "115.01", "0.68", "269.24"]
]

export def body comparison, stats
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"> "Core"
			<h1> "nelibc"
			<p className="tagline"> "A C library, rebuilt piece by piece in Nelua."
			<p className="blurb">
				"Replace selected libc functions with Nelua implementations, using glibc, musl or Cosmopolitan for the rest; or use the standalone runtime with no external libc. "
				<a html:href="https://github.com/Spaceghost/nelibc"> "Spaceghost/nelibc"
				" is experimental, Linux x86-64, with hybrid builds working and the standalone profile in progress. The implementations are Nelua, with x86-64 assembly for memory primitives and C adapters at the runtime boundaries."
			<p className="stats" innerHTML=stats>
		<div className="page-details">
			<h2 className="section" id="linux-arm64"> 'Linux AArch64 status'
			<p>
				'Nelibc’s library profiles currently target x86-64. On '
				<time html:datetime="2026-11-24"> '24 November 2026'
				', the character classification module from '
				<a href="https://github.com/Spaceghost/nelibc/commit/4f498d3"> 'revision 4f498d3'
				' compiled to an AArch64 object and passed a C ABI smoke test under QEMU in Fedora Incus. The test covered '
				<code> 'isalpha'
				', '
				<code> 'isdigit'
				' and '
				<code> 'isalnum'
				'.'
			<p>
				'The AArch64 memory archive builds the portable byte operations with GCC. Its Fedora Incus differential test exercised bytewise references, guard pages and overlapping moves. See the '
				<a href="https://github.com/Spaceghost/nelibc/blob/main/docs/quickstart.md#aarch64-memory-archive"> 'archive build and test commands'
				'.'
			<p>
				'In Fedora Incus, the '
				<a href="https://github.com/Spaceghost/nelibc/blob/6033734/docs/quickstart.md#aarch64-freestanding-startup"> 'AArch64 build and test commands'
				' checked thread-local storage, file metadata, descriptor waits and signals. The select test covered readiness and timeout writeback. The setjmp tests checked saved registers and signal-mask restoration.'
			<p> 'A static startup fixture verified constructor order, atexit handlers, destructors, the stdio flush call, and the exit status from main.'
			<p> 'The standalone pthread test passed in Fedora Incus and on a Fedora AArch64 kernel booted through Neboot. It checked thread creation, join, detach, cancellation, and isolation of thread-local storage and errno.'
			<p> 'The AArch64 floating-point environment test verified rounding modes, exception flags, and restoring saved state. The binary64 remainder primitive matched glibc in 50,121 cases. Mixed arguments passed in narrow and wide stdio formatting and scanning.'
			<p> 'Full standalone AArch64 coverage still needs binary128 and the remaining math routines.'
			<p>
				<a href="/nelua/compiler/#linux-arm64"> 'Build the Nelua compiler on Linux AArch64'
			<h2 className="section" html:id="profiles"> "Five runtime arrangements"
			<p className="lead"> "The C interface stays familiar while ownership changes. Compiler choice (GCC, Zig or TinyCC) is a separate axis from the runtime supplying the missing functions."
			<div className="table-wrap">
				<table>
					<caption> "Who owns the parts Nelibc has not replaced?"
					<thead>
						<tr>
							<th> "Profile"
							<th> "Nelibc owns"
							<th> "Underlying runtime"
					<tbody>
						<tr>
							<td> "glibc hybrid"
							<td> "The selected Nelua implementations and adapters"
							<td> "GNU libc supplies uncovered APIs and runtime support"
						<tr>
							<td> "musl hybrid"
							<td> "The selected Nelua implementations, with musl-specific adapters"
							<td> "musl supplies uncovered APIs and runtime support"
						<tr>
							<td> "Cosmopolitan hybrid"
							<td> "Memory, strings, narrow character classification, floating conversion, IP conversion, real and complex math"
							<td> "Cosmopolitan owns startup, allocation, FILE streams, threads, filesystem calls, resolver and integer conversion"
						<tr>
							<td> "Standalone"
							<td> "Its own startup, allocator, stdio, threading subset, locale and other implemented APIs"
							<td> "Linux x86-64 kernel services; uncovered functionality remains implementation work"
						<tr>
							<td> "Host"
							<td> "The standalone implementations over a callback dispatcher"
							<td> "A kernel or embedding host supplies console, memory, clocks, TLS and exit; current pthreads are cooperative lanes on one hardware thread"
			<p className="note"> "The Cosmopolitan profile is deliberately narrower than the older hybrids. A FILE stream, allocation or thread must stay with the runtime that owns its state. Removing glibc does not mean removing the fallback libc. Linux x86-64 is the tested platform; cross-platform runtime conformance is not established."
			<div className="actions">
				<a className="button button-ghost" html:href="#completion"> "Completion"
				<a className="button button-ghost" html:href="#conformance"> "Conformance"
				<a className="button button-ghost" html:href="#performance"> "Matched performance"
			<h3 id="repeated-byte-search"> "Repeated-byte substring search"
			<p> "Median microseconds for a 64 KiB miss on 22 November 2026. GCC 12.2, glibc 2.36 and Nelibc’s GCC hybrid ran in nine rotating rounds on an i5-10400."
			<div className="table-wrap">
				<table>
					<thead>
						<tr>
							<th scope="col"> "Miss"
							<th scope="col"> "70bcd89 (µs)"
							<th scope="col"> "eef2cef (µs)"
							<th scope="col"> "glibc (\u00b5s)"
					<tbody>
						for row in nelibcPassRows
							<tr>
								<th scope="row"> row[0]
								<td className="num"> row[1]
								<td className="num"> row[2]
								<td className="num"> row[3]
			<h4> "First-match timings"
			<p> "Each cell shows the previous revision, updated revision and glibc medians in microseconds. Early matches begin near the start of the buffer. Late matches end at the last haystack byte."
			<div className="table-wrap">
				<table>
					<thead>
						<tr>
							<th> "Function and input"
							<th> "Early match (µs)"
							<th> "Late match (µs)"
					<tbody>
						<tr>
							<th scope="row"> "strstr · alternating"
							<td> "0.619 / 0.010 / 0.010"
							<td> "38.937 / 3.560 / 2.430"
						<tr>
							<th scope="row"> "strstr · interior"
							<td> "0.994 / 0.999 / 0.331"
							<td> "116.652 / 1.681 / 265.188"
						<tr>
							<th scope="row"> "strstr · runs63"
							<td> "0.853 / 0.035 / 0.038"
							<td> "1.659 / 1.734 / 5.847"
						<tr>
							<th scope="row"> "memmem · alternating"
							<td> "0.029 / 0.004 / 0.008"
							<td> "219.554 / 2.902 / 43.304"
						<tr>
							<th scope="row"> "memmem · interior"
							<td> "0.353 / 0.346 / 0.133"
							<td> "116.126 / 1.061 / 266.417"
						<tr>
							<th scope="row"> "memmem · runs63"
							<td> "0.221 / 0.253 / 0.051"
							<td> "1.063 / 1.057 / 8.031"
			<p> "The same harness covers early and late hits, binary data, text, and seeded random bytes. Each timed call checked the first offset against a bytewise oracle. The previous archive and current archive used the same consumer with compiler builtins disabled."
			<details id="substring-samples">
				<summary> '22 November substring samples and first offsets'
				<pre> readFileSync('src/content/substring-current.csv', 'utf8').trimEnd()
			<p className="upstream-links">
				<a href="/nelua/assets/ecosystem-20261121/readme-search.csv"> "Searches in the project README"
				<a href="/nelua/assets/ecosystem-20261121/nelibc-gates.csv"> "Manual gate results"
				<a href="https://github.com/Spaceghost/nelibc/actions/runs/44938088906"> "Fedora CI"
				<a href="/nelua/assets/ecosystem-20261121/substring-rounds.sh"> "Replay script"
				<a href="/nelua/assets/ecosystem-20261121/substring-anchor.tar.gz"> "Existing benchmark controls"
				<a href="/nelua/assets/ecosystem-20261121/substring.csv"> "21 November substring samples"
				<a href="/nelua/assets/ecosystem-20261121/summary.csv"> "21 November quartiles and observed ranges"
				<a href="/nelua/assets/ecosystem-20261121/reproduce.txt"> "Versions and reproduction"
			<div innerHTML=comparison>
			<h2 className="section"> "What works today"
			<div className="table-wrap">
				<table>
					<thead>
						<tr>
							<th> "Area"
							<th> "Hybrid builds"
							<th> "Standalone"
					<tbody>
						<tr>
							<td> "Memory, strings, conversions"
							<td> "Broad Nelua implementation"
							<td> "Broad and growing"
						<tr>
							<td> "Math"
							<td> "Broad real and complex coverage, incl. x86-64 long double and fenv"
							<td> "Broad; edge cases remain"
						<tr>
							<td> "Stdio"
							<td> "Mostly host libc"
							<td> "Partial Nelua implementation"
						<tr>
							<td> "Files, processes, threads"
							<td> "Host and Nelua mix"
							<td> "Linux x86-64 base; gaps remain"
						<tr>
							<td> "Locale, wide chars, networking"
							<td> "Host and Nelua mix"
							<td> "Partial; resolver APIs remain"
						<tr>
							<td> "Terminals, non-local jumps, accounts"
							<td> "Host libc"
							<td>
								<code> "<termios.h>"
								" with pty functions and "
								<code> "tcgetpgrp"
								"/"
								<code> "tcsetpgrp"
								"; "
								<code> "<setjmp.h>"
								" in x86-64 assembly (musl's "
								<code> "jmp_buf"
								"); "
								<code> "<pwd.h>"
								"/"
								<code> "<grp.h>"
								" from "
								<code> "/etc"
								" files, no NSS; "
								<code> "<libgen.h>"
								", "
								<code> "<sys/statvfs.h>"
								", "
								<code> "<sys/syscall.h>"
								", the "
								<code> "rand48"
								" and "
								<code> "random"
								" generators, "
								<code> "execl"
								"/"
								<code> "execle"
								"/"
								<code> "execlp"
								", "
								<code> "vfork"
								", System V IPC ("
								<code> "msg*"
								", "
								<code> "sem*"
								", "
								<code> "shm*"
								", "
								<code> "ftok"
								"), "
								<code> "popen"
								"/"
								<code> "pclose"
								", "
								<code> "<mntent.h>"
								", "
								<code> "mktemp"
								", "
								<code> "daemon"
			<p className="note">
				"Counts track exported names, not behavioral conformance. \"Implemented\" means the symbol is present in the archive. See the "
				<a html:href="https://github.com/Spaceghost/nelibc/blob/main/docs/api-coverage.md"> "coverage notes"
				" for the methodology and the "
				<a html:href="https://github.com/Spaceghost/nelibc/blob/main/docs/core-roadmap.md"> "roadmap"
				" for the priority order."
			<h2 className="section" html:id="coverage"> "Coverage explorer"
			<p className="lead">
				"Choose a header or archive inventory and a runtime to see which symbols Nelibc supplies."
			<p className="muted">
				"Download the "
				<a html:href="/nelua/assets/nelibc-coverage-profiles.json"> "current inventory and profile data"
				" or open the "
				<a html:href="/nelua/assets/nelibc-coverage.json"> "historical musl coverage snapshot"
				"."
			<div html:id="explorer" className="explorer">
			<noscript>
				<p className="muted">
					"The interactive explorer needs JavaScript. Download the complete "
					<a html:href="/nelua/assets/nelibc-coverage-profiles.json"> "inventory and runtime profile data"
					" as JSON. The older "
					<a html:href="/nelua/assets/nelibc-coverage.json"> "musl coverage snapshot"
					" remains available."
			<h2 className="section"> "Build and historical gates"
			<dl className="kv">
				<dt> "Requirements"
				<dd>
					"Nelua and the Cosmopolitan compiler wrapper for the default hybrid build; Zig ("
					<code> "zig cc"
					") for the older profiles. GCC for the GCC profile; TinyCC mob branch for the TinyCC profile."
				<dt> "Build the measured revision"
				<dd>
					"Use the Nelibc revision and toolchain versions recorded with the comparison. The target "
					<code> "make smoke-cosmo"
					" uses "
					<code> "x86_64-unknown-cosmo-cc"
					" from Cosmopolitan 4.0.2, checks the full archive link and rejects a glibc dependency. Supply "
					<code> "COSMOCC=/path/to/cosmocc/bin/x86_64-unknown-cosmo-cc"
					". Compile consumers with Cosmopolitan headers, without "
					<code> "-Iinclude"
					"."
				<dt> "Older hybrid example"
				<dd>
					<code> "make dogfood-zig"
					" builds the hybrid archive, compiles "
					<code> "examples/incremental.c"
					", runs it and checks Nelibc's "
					<code> "memcpy"
					", "
					<code> "strlen"
					", "
					<code> "strchr"
					" and "
					<code> "strtol"
					" are the ones linked."
				<dt> "Matrices"
				<dd>
					<code> "make smoke-matrix"
					" (seven profiles), "
					<code> "make dogfood-matrix"
					" (four consumers), "
					<code> "make host-matrix"
					", "
					<code> "make host-bend-hello-zig"
					"."
				<dt> "7 November 2026 gate"
				<dd>
					"2026-11-07 on main "
					<code> "1c7240a"
					" (branch commit "
					<code> "d5f3456"
					"): Debian 12, glibc 2.36, GCC 12.2, Zig 0.17.0, Nelua "
					<code> "dabbd9ef"
					". 159 of 159 targets passed with no warnings: hybrid Zig/glibc, GCC/glibc and Zig/musl, standalone Zig and GCC, freestanding Zig and GCC, the host profile, and musl's libc-test against the hybrid and standalone archives. Until an earlier run that day the gate script had left libc-test out although the repository's gate list includes it; a "
					<code> "<limits.h>"
					" regression in GCC hybrid builds slipped through that gap and was fixed."
				<dt> "Conformance"
				<dd>
					"musl's "
					<a html:href="https://github.com/Spaceghost/nelibc/blob/main/docs/libc-test.md"> "libc-test"
					" runs against the gcc and zig hybrid archives with a committed expected-failure list that only shrinks: 112 and 118 after the first slice, 31 (gcc) and 35 (zig) in the recorded 2026-11-07 run, none of them math tests. Slice 2 fixed strftime, fnmatch, exact "
					<code> "%La"
					", the TZif reader's stack use and "
					<code> "malloc_usable_size"
					"; the math slice ported musl's exp, pow, log, trigonometric, gamma and Bessel code with its exception-flag discipline, which cleared 76 math tests. A follow-up fixed the last seven: the sign of "
					<code> "fma"
					" with a zero addend, "
					<code> "fmaf"
					" rounding and underflow in the subnormal range, the sign of "
					<code> "modfl"
					"'s fraction, and musl ports of "
					<code> "erfl"
					", "
					<code> "erfcl"
					" and "
					<code> "exp10l"
					". "
					<code> "printf"
					" now formats every long double exactly: "
					<code> "%Lf"
					", "
					<code> "%Le"
					" and "
					<code> "%Lg"
					" write the full decimal expansion of the 80-bit value and round half to even, checked against glibc on 28 cases including "
					<code> "LDBL_MAX"
					" in all 4,940 characters."
				<dt> "Standalone conformance"
				<dd>
					"libc-test also runs against the standalone archive, where Nelibc is the whole C library: Nelibc's headers only, its own "
					<code> "_start"
					", libc-test's own runner with the 100 KiB stack limit. The first run passed 255 of 343 tests with GCC; after the fixes it led to ("
					<code> "<limits.h>"
					", "
					<code> "<inttypes.h>"
					", "
					<code> "<langinfo.h>"
					", "
					<code> "<search.h>"
					" and "
					<code> "<regex.h>"
					" (nebox's Pike VM engine behind the POSIX interface) for standalone, static constructors and destructors, scanf "
					<code> "%n"
					" and "
					<code> "ungetc"
					" pushback, cancellation points and PI mutex relock, "
					<code> "ftello"
					" on append streams, "
					<code> "sem_open"
					" reuse, "
					<code> "pthread_create"
					"'s "
					<code> "EAGAIN"
					", exit after the last "
					<code> "pthread_exit"
					") 300 pass with GCC and 301 with Zig, with no timeouts; with "
					<code> "<pwd.h>"
					"/"
					<code> "<grp.h>"
					", "
					<code> "<setjmp.h>"
					" and a batch of small POSIX families since, 326 pass with GCC and 328 with Zig; with "
					<code> "iconv"
					" (UTF-8/16/32, UCS-2/4, the ISO-8859 and Windows code pages, KOI8, CP437/850, musl's "
					<code> "*"
					" replacement), "
					<code> "shm_open"
					", "
					<code> "dn_expand"
					" and a GCC "
					<code> "<tgmath.h>"
					" on top, 332 pass with GCC and 333 with Zig (all 11 and 10 failures expected and listed; one of GCC's is a libc-test "
					<code> "main"
					" without a "
					<code> "return"
					"). "
					<code> "mktime"
					" now honours a "
					<code> "tm_isdst"
					" that contradicts the date, as glibc and musl do, a fix found through nebox's "
					<code> "date -d '14 days ago'"
					". Every math test that builds passes. The rest is a written map of what is missing ("
					<code> "dl*"
					", "
					<code> "crypt"
					", "
					<code> "wordexp"
					", ...) and of what is still open (a "
					<code> "posix_spawnp"
					" null-"
					<code> "envp"
					" divergence, destroying a locked robust mutex), in "
					<a html:href="https://github.com/Spaceghost/nelibc/blob/main/docs/libc-test.md"> "docs/libc-test.md"
					"."
				<dt> "CPU baseline"
				<dd>
					"Zig builds default to "
					<code> "-mcpu=x86_64"
					"; override with "
					<code> "ZIGFLAGS='-mcpu=x86_64_v3'"
					" on purpose."
			<div className="actions">
				<a className="button" html:href="https://github.com/Spaceghost/nelibc"> "Repository"
				" "
				<a className="button button-ghost" html:href="https://github.com/Spaceghost/nelibc/blob/main/docs/quickstart.md"> "Quickstart"
				" "
				<a className="button button-ghost" html:href="https://github.com/Spaceghost/nelibc/blob/main/docs/core-roadmap.md"> "Roadmap"

export def footerLinks
	<div className="footer-links">
		<a html:href="https://github.com/Spaceghost/nelibc"> "Spaceghost/nelibc"
