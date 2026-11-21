export const title = "Nelua compiler fork · spacegho.st/nelua"
export const description = "Spaceghost/nelua: upstream Nelua plus variants, optionals, an exhaustive match statement, owned records with move, closures, structured compile-time evaluation, const pointers, a compiler-enforced freestanding pragma, cross-compilation with --target and nelua-bindgen."

const frontendTimings = [
	["Check syntax · extension tour", "38.16", "23.90", "1.60×"]
	["Emit C · hello world", "29.47", "29.30", "1.01×"]
	["Emit C · matrix multiplication", "131.19", "130.63", "1.00×"]
	["Emit C · standard library test suite", "1,383.74", "1,379.74", "1.00×"]
	["Emit C · 2,048 runtime assertions (synthetic)", "282.06", "146.39", "1.93×"]
]

export def body
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"> "Core"
			<h1> "The compiler"
			<p className="tagline"> "Upstream Nelua, tracked closely, plus the pieces a self-hosted libc and freestanding targets asked for."
			<p className="blurb">
				<a html:href="https://github.com/Spaceghost/nelua"> "Spaceghost/nelua"
				" is a fork of "
				<a html:href="https://github.com/edubart/nelua-lang"> "edubart/nelua-lang"
				" at commit "
				<code> "a584505"
				" (2025-06-24). Each addition lands with specs in "
				<code> "spec/"
				" and a section in the docs, and compiles to ordinary C. Under "
				<code> "pragmas.nogc"
				", generated string and container operations use normal allocator rules; "
				<code> "pragmas.freestanding"
				" continues to reject heap-dependent operations. The guide "
				<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/fork.md"> "What this fork adds"
				" walks through each one with examples."
			<p className="stats">
				<span>
					<strong> "Upstream base"
					" a584505 · 2025-06-24"
				<span>
					<strong> "609 specs passed"
					" · 2026-11-21"
				<span>
					<strong> "Fork revision "
					<code> "874acdd"
			<p>
				<a href="/nelua/necc/"> 'necc'
				' packages this frontend with a standalone Linux toolchain.'
		<div className="page-details">
			<h2 className="section" id="performance"> 'Frontend compile times'
			<p>
				'On '
				<time html:datetime="2026-11-21"> '21 November 2026'
				', the two biggest differences came from syntax checking and source-location lookups. A syntax-only invocation can skip the built-in code generator and analyzer. During C generation, the compiler now indexes source line breaks once per file so repeated runtime diagnostics can find their source locations cheaply.'
			<div className="table-wrap" role="region" aria-label="Median frontend wall time in milliseconds" html:tabindex="0">
				<table>
					<thead>
						<tr>
							<th scope="col"> 'Workload'
							<th className="num" scope="col"> '5995eba (ms)'
								<th className="num" scope="col"> '874acdd (ms)'
								<th className="num" scope="col"> 'Old / new'
					<tbody>
						for row in frontendTimings
							<tr>
								<th scope="row"> row[0]
								<td className="num"> row[1]
								<td className="num"> row[2]
								<td className="num"> row[3]
			<p> 'Each median covers 30 alternating pairs in two batches on one Intel Core i7-11700F logical CPU under Debian 12. A fresh process parsed the input and either exited after the syntax check or wrote C. All four C workloads produced byte-identical output across the two revisions. The 2,048-assertion fixture compiled 1.93× as fast. Hello world, matrix multiplication and the standard library suite moved by less than 1% in the pooled medians.'
			<p className="upstream-links">
				<a href="/nelua/assets/frontend-20261121/samples.csv"> 'All 300 samples (CSV)'
				<a href="/nelua/assets/frontend-20261121/method.txt"> 'Method and reproduction'
			<h2 className="section"> "What the fork adds"
			<p className="lead">
				"Everything below is opt-in syntax or tooling. Code written for upstream Nelua compiles unchanged. The first five are language features that fit together: variants and optionals carry \"one of these\" data, "
				<code> "match"
				" takes it apart safely, ownership keeps resources from being released twice, and closures let the standard algorithms take a function."
			<div className="grid">
				<article className="card card-core" html:id="variants">
					<h3> "Variants"
					<p>
						"One value out of a fixed list of types, with a tag that remembers which. Written "
						<code> "variant(A, B)"
						" or "
						<code> "A|B"
						" through "
						<code> "require 'variant'"
						". A variant is a plain record (a "
						<code> "uint8"
						" tag and a C union), so it lives in arrays and other records and costs no allocation."
					<pre>
						<code> "require 'variant'\nlocal Token = @variant(integer, string, boolean)\nlocal t: Token = 42\nprint(t == 42, t:is(integer))   -- true  true\nt = 'end'\nprint(t:get(string))            -- end"
					<p className="meta">
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/fork.md#variants"> "guide "
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/overview.md#variant"> "overview "
				<article className="card card-core" html:id="optionals">
					<h3> "Optionals"
					<p>
						"A value or nothing: "
						<code> "T?"
						" or "
						<code> "optional(T)"
						" through "
						<code> "require 'optional'"
						". "
						<code> "orelse"
						" unwraps with a lazily evaluated default, "
						<code> "if local x = e then"
						" tests and binds in one step, and the postfix "
						<code> "?"
						" turns an empty optional, a null pointer or a stdlib "
						<code> "(value, errmsg)"
						" failure into an early return. "
						<code> "*T?"
						" stays the size of a pointer."
					<pre>
						<code> "require 'optional'\nrequire 'io'\nlocal function find(k: integer): integer?\n  if k == 1 then return 10 end\n  return nil\nend\nlocal a = find(1) orelse 0          -- 10\nif local x = find(2) then print(x) end\nlocal function open_all(p: string): integer?\n  local f = io.open(p)?             -- returns empty on failure\n  return 1\nend"
					<p className="meta">
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/fork.md#optionals"> "guide "
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/overview.md#optional"> "overview "
				<article className="card card-core" html:id="match">
					<h3>
						<code> "match"
					<p>
						"Dispatch on the held type of a variant or an optional. Without "
						<code> "else"
						" every member and "
						<code> "nil"
						" must be covered, so adding a member to a variant turns every unfinished "
						<code> "match"
						" into a compile error that lists what is missing. "
						<code> "case local x: T"
						" binds a copy, "
						<code> "case local x: *T"
						" a reference into the subject, which is matched in place. The whole statement is lowered at compile time to one C "
						<code> "switch"
						" on the tag: no runtime code, no call, no allocation."
					<pre>
						<code> "local Shape = @variant(integer, string)\nlocal shapes: [2]Shape = \{7, 'square'}\nmatch shapes[0] do\ncase local r: *integer then $r = $r * 2   -- writes into shapes[0]\ncase local name: string then print(name)\ncase nil then print('empty')\nend"
					<p className="meta">
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/fork.md#match"> "guide "
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/overview.md#variant"> "overview "
				<article className="card card-core" html:id="ownership">
					<h3>
						"Owned records and "
						<code> "move"
					<p>
						"A record that releases something in "
						<code> "__close"
						" can be marked "
						<code> "<owned>"
						". Its values are then affine: copying an lvalue needs the "
						<code> "move"
						" builtin (which zeroes the source), a moved variable cannot be read until it is assigned again, and the check follows the control flow through branches, loops and early exits. Records with owned fields and arrays of owned values are owned implicitly; pointers never move. "
						<code> "vector"
						", "
						<code> "sequence"
						" and "
						<code> "hashmap"
						" of owned values own their elements: values move in and out, and whatever the container drops ("
						<code> "clear"
						", "
						<code> "remove"
						"/"
						<code> "erase"
						", a shrinking "
						<code> "resize"
						", "
						<code> "destroy"
						") is closed. Everything is checked at compile time and costs nothing at run time."
					<pre>
						<code> "local Buf <owned> = @record\{data: pointer, size: usize}\nlocal a = Buf.create(16)\nlocal c = move(a)   -- `a` is zeroed; reading it now is an error\na = Buf.create(8)   -- live again\ninspect(&amp;a)         -- lending a pointer is not a move"
					<p className="meta">
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/fork.md#ownership-and-move"> "guide "
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/overview.md#ownership"> "overview "
				<article className="card card-core" html:id="closures">
					<h3> "Closures"
					<p>
						"Anonymous and nested functions can capture the enclosing locals. The compiler turns the function into a "
						<em> "closure record"
						" holding a copy of each captured variable and a "
						<code> "__call"
						" metamethod, so the value is a plain record that works without the GC and can be returned or stored. Annotate it "
						<code> "<byref>"
						" to capture pointers instead and mutate the enclosing variables; such a closure must not outlive its frame."
					<pre>
						<code> "local function make_adder(n: integer)\n  return function(x: integer): integer return x + n end\nend\nprint(make_adder(2)(1))   -- 3\n\nlocal total = 0\nlocal function add(v: integer) <byref> total = total + v end\nadd(4) add(6)             -- total == 10"
					<p className="meta">
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/fork.md#closures"> "guide "
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/overview.md#closures"> "overview "
				<article className="card card-core" html:id="comptime">
					<h3> "Compile-time evaluation"
					<p>
						<code> "comptime(f(args))"
						" runs an ordinary Nelua function inside the compiler and folds its result into the program: scalars, strings, and arrays or records as C static initializers. Named "
						<code> "<comptime>"
						" record configs can be reused across calls, including nested records and arrays. A function marked "
						<code> "<comptime>"
						" is evaluated at every call and never emitted to C. The sandbox keeps C semantics (integer widths, unsigned division, "
						<code> "float32"
						" rounding) and is bounded in steps and depth; it does not execute target memory or perform I/O."
					<pre>
						<code> "local function crc32_table(): [256]uint32\n  local t: [256]uint32\n  for i: uint32 = 0, 255 do\n    local c: uint32 = i\n    for _ = 1, 8 do\n      if c &amp; 1 == 1 then c = 0xEDB88320 ~ (c >> 1) else c = c >> 1 end\n    end\n    t[i] = c\n  end\n  return t\nend\nlocal CRC = comptime(crc32_table())   -- a static table in the C output\nprint(CRC[1])                         -- 1996959894"
					<p className="meta">
						<a html:href="/nelua/compiler/comptime/"> "full guide "
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/comptime.md"> "compiler docs "
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/overview.md#compile-time-function-evaluation"> "overview "
				<article className="card card-core" html:id="syntax">
					<h3> "Syntax extensions"
					<p>
						"A top-level "
						<code> "#syntax"
						" directive extends the grammar for the rest of its file. Builders turn each form into ordinary Nelua before type checking. The opt-in library now includes control flow, lazy conditional expressions, concise functions and closures, destructuring, scoped resources, typed vector comprehensions, grouped numbers, byte strings and alternative operators, alongside compound assignment, pipes and interpolation. Load individual modules or the complete "
						<code> "syntax.all"
						" pack; use "
						<code> "syntax.use"
						" to compose your own reusable packs."
					<pre>
						<code> "#syntax 'syntax.all'\nrequire 'string'\nrequire 'vector'\n\nlocal double = fn(x: integer) => x * 2\nlet [first, _, third] = (@[3]integer)\{10, 20, 30}\nlocal total = 0\ntimes 3 as i do total += i end\nlocal label = choose total == 6 then 'ready' else 'waiting' end\nprint($\"\{label}: \{total |> double}, \{first + third}\") -- ready: 12, 40\n\nusing squares = collect(integer; i = 1, 8 when i % 2 == 0 => i * i) do\n  print(squares[0], squares[3])                      -- 4, 64\nend"
					<p> "Each extension remains file-scoped and keeps normal type, ownership and lifetime checks. The full guide covers every module, evaluation rules, precedence, templates, diagnostics and the builder API, with a runnable tour."
					<p className="meta">
						<a html:href="/nelua/compiler/syntax-extensions/"> "full guide "
						<a html:href="/nelua/compiler/syntax-extensions/#embed-bend2"> "embed Bend2 "
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/syntax-extensions.md"> "compiler docs "
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/examples/syntax_tour.nelua"> "runnable tour "
				<article className="card card-core" html:id="const">
					<h3> "Const pointers"
					<p>
						<code> "*const T"
						" maps to C "
						<code> "const T*"
						". Reads through it are read-only, "
						<code> "*T"
						" converts to it implicitly, and dropping "
						<code> "const"
						" needs an explicit cast. It is what most C APIs take, so nelibc and generated bindings can state their intent and have the compiler check it."
					<p className="meta">
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/fork.md#const-pointers"> "guide "
				<article className="card card-core" html:id="freestanding">
					<h3>
						<code> "pragmas.freestanding"
					<p>
						"A compiler-enforced runtime-free profile. It implies "
						<code> "nogc"
						" and "
						<code> "noentrypoint"
						", traps on abort, and rejects heap, process, stdio and "
						<code> "main"
						" symbols at compile time. nelibc's host profile and Drift's kernel drivers build on it; the guarantee is in the emitted C and the linked symbols, not in a convention."
					<p>
						"The neboot loader uses this profile to export "
						<code> "efi_main"
						" and describe firmware tables as Nelua records. It marks the entry point and the protocol function pointer types with "
						<code> "ms_abi"
						" so the generated C preserves the x86-64 UEFI calling convention."
					<p className="meta">
						<a html:href="/nelua/neboot/"> "neboot walkthrough "
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/runtime-free.md"> "runtime-free guide "
				<article className="card card-core" html:id="target">
					<h3>
						<code> "--target <triple>"
					<p>
						"Cross compile with clang or "
						<code> "zig cc"
						". The triple reaches the type-size probe, the cache hash and the compile, so a build for another architecture never reuses the host's cached sizes."
				<article className="card card-core" html:id="bindgen">
					<h3>
						<code> "tools/nelua-bindgen"
					<p>
						"Generates "
						<code> "<cimport>"
						" bindings from C headers with libclang: integer, pointer, array, struct, union, enum and function types, "
						<code> "const"
						" kept as "
						<code> "*const T"
						", string and numeric macros as constants, opaque and forward-declared structs. "
						<code> "--match"
						"/"
						<code> "--exclude"
						" select symbols, "
						<code> "--opaque"
						" and "
						<code> "--enum-using"
						" shape types, "
						<code> "--nullable-returns REGEX"
						" wraps pointer-returning functions in "
						<code> "*T?"
						", and a JSON "
						<code> "--config"
						" prepends or appends hand-written text."
					<p className="meta">
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/tools/nelua-bindgen/README.md"> "tool README "
				<article className="card card-core" html:id="libraries">
					<h3> "Libraries from nelua-batteries"
					<p>
						<code> "algorithm"
						" (introsort, heapsort, "
						<code> "removeif"
						", "
						<code> "packn"
						"/"
						<code> "unpackn"
						"), "
						<code> "heapqueue"
						" (an owned binary-heap priority queue) and "
						<code> "tuple"
						" were brought over from "
						<a html:href="https://github.com/edubart/nelua-batteries"> "edubart/nelua-batteries"
						" and adapted to the fork's rules: no hidden copies of owned values, "
						<code> "*const"
						" where nothing is written."
					<p className="meta">
						<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/libraries.md#algorithm"> "library reference "
				<article className="card">
					<h3> "Toolchain and editor support"
					<p>
						"Tree-sitter and TextMate grammars under "
						<code> "tools/"
						" (the Tree-sitter scanner is itself written in Nelua) know every addition above: "
						<code> "*const T"
						", "
						<code> "A|B"
						", "
						<code> "T?"
						", "
						<code> "expr?"
						", "
						<code> "orelse"
						", "
						<code> "if local"
						", anonymous "
						<code> "function"
						" expressions and "
						<code> "match"
						". A compact C codegen profile for distributable output, and a binary cache that also hashes imported C sources so a changed header rebuilds."
			<h2 className="section"> "Install"
			<p className="lead"> "Nelua needs Git, a C compiler and make. The fork builds the same way upstream does."
			<pre>
				<code> "git clone https://github.com/Spaceghost/nelua\ncd nelua\nmake\nsudo make install   # or: make install PREFIX=$HOME/.local\nnelua --version"
			<p className="note">
				"Pinning: the nelibc gate and nebox's container builds run the fork at "
				<code> "dabbd9ef"
				". nelibc and nebox compile with upstream-compatible syntax plus const pointers; the newer additions are available to them but not yet required."
			<h2 className="section"> "How changes are gated"
			<dl className="kv">
				<dt> "Specs"
				<dd>
					<code> "make test"
					" runs upstream's spec suite plus the fork's specs (const pointers, freestanding, target, bindgen, variant, optional, match, ownership, closures, the batteries libraries, comptime). All 609 specs passed on 21 November 2026 at fork revision "
					<code> "874acdd"
					" using Clang 23 and Bend 2.0.40."
				<dt> "Examples"
				<dd> "Every example in the fork guide was compiled and run with the checkout it documents and prints what its comments say."
				<dt> "Consumers"
				<dd> "nelibc's smoke matrix and nebox's conformance suite are rebuilt against the fresh compiler in a pinned container before the pin moves."
				<dt> "Runtime-free audits"
				<dd> "A standalone GCC and Clang workflow links the freestanding examples and checks the emitted symbols: no allocator, no GC, no entry point."
				<dt> "Upstream"
				<dd> "The fork rebases rather than diverges; language additions are kept small enough to offer upstream."

export def footerLinks
	<div className="footer-links">
		<a html:href="https://github.com/Spaceghost/nelua"> "Spaceghost/nelua"
		<a html:href="https://github.com/Spaceghost/nelua/blob/master/docs/pages/fork.md"> "fork guide "
		<a html:href="https://nelua.io/overview/"> "language overview "
