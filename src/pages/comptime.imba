export const title = "Compile-time evaluation · Nelua · spacegho.st"
export const description = "Use Nelua compile-time evaluation to turn reusable record and array configurations into static C data, with value semantics, caching, practical protocol examples, and clear sandbox limits."

export def body
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"> "Compiler · language feature"
			<h1> "Compute configuration once"
			<p className="tagline"> "Use ordinary Nelua functions to transform typed configuration into data that is already present in the generated program."
			<p className="blurb"> "Compile-time evaluation (CTFE) is useful when a table, descriptor, protocol constant, or lookup structure follows from values known before the target runs. Keep the inputs as typed records, reuse them by name, and let the compiler emit the result as ordinary static C data."
			<p className="meta">
				<a html:href="/nelua/compiler/"> "Compiler additions"
				<a html:href="https://github.com/Spaceghost/nelua-lang/blob/master/docs/pages/comptime.md"> "Compiler guide "
				<a html:href="https://github.com/Spaceghost/nelua-lang/blob/master/docs/pages/overview.md#compile-time-function-evaluation"> "Language overview "
		<div className="page-details">
			<h2 className="section" html:id="two-ways"> "Two ways to ask for evaluation"
			<p className="lead">
				<code> "comptime(call)"
				" marks one call for evaluation. Marking a function "
				<code> "<comptime>"
				" makes its calls compile-time calls, so all arguments must be known at those call sites. The annotation guarantees that the function is never emitted to C. An ordinary function evaluated through "
				<code> "comptime"
				" may still be emitted to C even when the program has no runtime calls to it."
			<pre>
				<code> "local function add_bias(value: integer, bias: integer): integer\n  return value + bias\nend\n\nlocal OFFSET = comptime(add_bias(10, 2)) -- folded value: 12\n\nlocal function scale(value: integer, factor: integer): integer <comptime>\n  return value * factor\nend\nlocal GAIN = scale(6, 7)                 -- folded value: 42\nassert(OFFSET == 12 and GAIN == 42)"
			<p className="small muted">
				"The function annotation guarantees "
				<code> "scale"
				" is absent from generated C. "
				<code> "add_bias"
				" can still be emitted even though this example has no runtime call to it."
			<p>
				"Use explicit "
				<code> "comptime(...)"
				" when only selected calls should be evaluated. Use the function annotation when compile-time execution is the function's contract and runtime arguments should be rejected."
			<h2 className="section" html:id="named-config"> "Named record configs"
			<p className="lead"> "A record constant gives a configuration a type and a stable name. It can be passed to multiple compile-time functions, and nested records and fixed arrays keep their types as data moves through the evaluator."
			<pre>
				<code> "local Link = @record\{baud: uint32, parity: uint8}\nlocal RadioConfig = @record\{\n  reference_hz: uint32,\n  link: Link,\n  divisors: [3]uint32,\n}\n\nlocal RADIO <comptime> = RadioConfig\{\n  reference_hz = 32000000,\n  link = Link\{baud = 9600}, -- omitted parity is zero\n  divisors = \{9600, 19200, 38400},\n}\n\nlocal function make_rate_table(cfg: RadioConfig): [3]uint32 <comptime>\n  local rates: [3]uint32\n  for i: uint8 = 0, 2 do\n    rates[i] = cfg.reference_hz // cfg.divisors[i]\n  end\n  return rates\nend\n\nlocal RATES = comptime(make_rate_table(RADIO))\nprint(RATES[0], RATES[1], RATES[2]) -- 3333 1666 833\n\nlocal DEFAULT_RADIO <comptime> = RadioConfig\{}\n-- Every field and array element omitted above is zero-initialized."
			<p>
				"The compiler evaluates "
				<code> "make_rate_table"
				" using the fields of "
				<code> "RADIO"
				". The generated program contains the resulting three integers as static data; it does not call the table builder or calculate the entries on the target. The numbers are a teaching example of integer division, not a hardware clock prescription."
			<h2 className="section" html:id="nested-values"> "Nested values and mutation"
			<p> "Compile-time records and arrays behave as values. Assigning one copies it, including nested arrays and records. A function may update its local parameter copy while deriving an output, without changing the named input config or another caller's copy."
			<pre>
				<code> "local Point = @record\{x: integer, y: integer}\nlocal Board = @record\{origin: Point, cells: [2]Point}\nlocal BOARD <comptime> = Board\{\n  origin = \{2, 3},\n  cells = \{\{4, 5}, \{6}}, -- second point's y defaults to zero\n}\n\nlocal function summarize(board: Board): integer <comptime>\n  board.origin.x = board.origin.x + 1 -- edits this value copy\n  return board.origin.x * 100 + board.cells[0].y\nend\nlocal SUMMARY = comptime(summarize(BOARD)) -- 305\nlocal AGAIN = comptime(summarize(BOARD))   -- also 305; BOARD is unchanged\nassert(SUMMARY == 305 and AGAIN == 305)"
			<p>
				"Omitted record fields and fixed-array elements receive the type's zero value. "
				<code> "Config\{...}"
				" supplies selected fields, while "
				<code> "Config()"
				" creates a zero-initialized record. Positional and named fields follow normal record literal rules."
			<h2 className="section" html:id="generated-c"> "What reaches C"
			<p> "A folded scalar is a constant expression. An array or record result is emitted as a C initializer, so it has no runtime table-building loop, allocator, or evaluator support code. The current backend represents this fixed array with a generated C wrapper; its initializer contains the folded values:"
			<pre>
				<code> "static nluint32_arr3 RATES = \{ .v = \{ 3333U, 1666U, 833U } };"
			<p> "The compiler's generated C is still compiled by your selected C compiler. CTFE removes the computation from the target program; it does not bypass the C compiler or turn a runtime input into a compile-time value."
			<h2 className="section" html:id="embedded"> "A protocol-table pattern"
			<p> "Embedded code often repeats small transforms: deriving a packet mask from a field width, expanding a CRC polynomial into a lookup table, or calculating a set of candidate divisors from a declared clock and rate list. The same pattern applies to firmware, drivers, and protocol libraries: put the inputs in a typed config, write a deterministic Nelua function, then fold its result."
			<pre>
				<code> "local PacketLayout = @record\{\n  sequence_bits: uint8,\n  type_bits: uint8,\n  payload_bytes: uint16,\n}\nlocal LAYOUT <comptime> = PacketLayout\{\n  sequence_bits = 12, type_bits = 4, payload_bytes = 256,\n}\n\nlocal function make_packet_mask(layout: PacketLayout): uint16 <comptime>\n  return (1 << layout.sequence_bits) - 1\nend\nlocal SEQUENCE_MASK = make_packet_mask(LAYOUT) -- folded at compile time: 4095\nassert(SEQUENCE_MASK == 4095)\n\n-- Runtime code can now pack/unpack using SEQUENCE_MASK and LAYOUT.payload_bytes.\n-- The field widths and protocol interpretation remain your responsibility."
			<p> "This demonstrates calculation from protocol metadata only. It does not prescribe an on-wire layout, synchronization policy, peripheral register value, timing tolerance, or device-qualified formula; those must come from the relevant protocol or hardware documentation."
			<h2 className="section" html:id="cache"> "Caching and repeatability"
			<p> "Within one compilation, evaluator results are cached by function and canonicalized argument values. Repeating a pure call with the same config can reuse the result. This makes compile-time work predictable and avoids repeating expensive table construction. Inputs and outputs retain value semantics: cache reuse does not make a callee's mutations visible in the caller's config."
			<p>
				"Keep CTFE functions deterministic. Compiler-side "
				<code> "print"
				" output and errors belong to compilation, not the target program. The final folded values become part of generated C and therefore of the normal build artifacts."
			<h2 className="section" html:id="limits"> "Limits and diagnostics"
			<p>
				"CTFE is a bounded evaluator for Nelua values, not a second machine that runs the target program. It mirrors important C-facing numeric behavior: fixed-width integer wrapping, unsigned division, Nelua shift behavior, and "
				<code> "float32"
				" rounding. Floating-point transcendental functions may differ in the last digits from the target C library."
			<ul>
				<li>
					"Each evaluation is limited by "
					<code> "pragmas.comptime_steps"
					" (default 10 million Lua instructions) and "
					<code> "pragmas.comptime_stack"
					" (default 10,000 nested calls)."
				<li> "Supported values include scalars, booleans, strings, enums, fixed arrays, and records composed of supported values. Nested records and arrays are supported."
				<li> "Pointers can be used as references while evaluating supported record/array values; CTFE does not dereference target addresses or execute against target memory. Records containing pointer fields are rejected."
				<li>
					"Optionals, variants, closures, "
					<code> "defer"
					", "
					<code> "for in"
					" iterators, spans, dynamic containers, allocators, garbage collection, C imports, operating-system calls, and I/O are outside the current evaluator subset. Diagnostics identify unsupported operations when the function is evaluated."
				<li> "Values read from outside the function must themselves be compile-time values. Arguments and results must use the supported value shapes; runtime data cannot be smuggled into a compile-time call."
			<p className="note"> "A compile-time failure is a build failure. Keep generated tables small enough for the configured step and stack budgets, and test important numeric boundaries on the intended target toolchain as well."
			<h2 className="section" html:id="try-it"> "Try it in a project"
			<p>
				"Put the code in a "
				<code> ".nelua"
				" file, then compile and run it with the fork:"
			<pre>
				<code> "nelua radio_config.nelua"
			<p>
				"To inspect the generated C, run "
				<code> "nelua --print-code radio_config.nelua > radio_config.c"
				" and search the output for the folded array. Check the fork's current "
				<a html:href="https://github.com/Spaceghost/nelua-lang/blob/master/docs/pages/comptime.md"> "CTFE reference"
				" for supported syntax and diagnostics."
			<h2 className="section" html:id="related"> "Related pages"
			<ul>
				<li>
					<a html:href="/nelua/compiler/"> "Compiler fork feature list and install notes"
				<li>
					<a html:href="https://github.com/Spaceghost/nelua-lang/blob/master/docs/pages/comptime.md"> "Compiler CTFE reference"
				<li>
					<a html:href="https://github.com/Spaceghost/nelua-lang/blob/master/docs/pages/overview.md#compile-time-function-evaluation"> "Nelua overview: compile-time function evaluation"
				<li>
					<a html:href="https://github.com/Spaceghost/nelua-lang/blob/master/docs/pages/fork.md#compile-time-evaluation"> "Fork additions guide"

export def footerLinks
	<div className="footer-links">
		<a html:href="https://github.com/Spaceghost/nelua-lang"> "Spaceghost/nelua-lang"
		<a html:href="/nelua/"> "ecosystem overview"
