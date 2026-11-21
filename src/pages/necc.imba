import { comparisons, field } from '../necc-timings.mjs'

export const title = 'necc · Native compiler driver · Nelua at spacegho.st'
export const description = 'Build C and Nelua programs for x86-64 Linux, run Lua, and compile freestanding code that calls UEFI firmware.'

const timings = [
	['Compile 128 functions', '16.038', '8.727', '1.506', 'TinyCC']
	['Run six million arithmetic iterations', '20.277', '9.371', '2.099', 'Zig cc -O2']
]

export def body
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"> 'Core · the compiler driver'
			<h1> 'necc'
			<p className="lead"> 'Build C and Nelua programs for x86-64 Linux against standalone Nelibc, run Lua, or compile an object for UEFI firmware.'
			<p><a href="https://github.com/Spaceghost/necc"> 'necc source on GitHub'
			<div className="actions">
				<a className="button" href="#compile"> 'Compile a program'
				<a className="text-link" href="#benchmarks"> 'Compare compiler timings'
		<h2 className="section" id="compile"> 'Compile a program'
		<p>
			'These commands assume the staged SDK is installed at the distro default or selected with '
			<code> 'NECC_SYSROOT'
			'.'
		<pre>
			<code> "export NECC_SYSROOT=/path/to/sdk\nprintf '%s\\n' 'int main(void) \{ return 0; }' > hello.c\nnecc hello.c -o hello\n./hello\n\nprintf '%s\\n' \"print 'hello from Nelua'\" > hello.nelua\nnecc hello.nelua -o hello-nelua\n./hello-nelua\n\nnecc --lua -e 'print(_VERSION)'"
		<p> 'For a multi-file link, pass source files, object files and static archives together. Put archives after the objects that use them. Use -c to keep the object file from a single input.'
		<h2 className="section"> 'Choose a Nelua compilation path'
		<ul>
			<li>
				<code> 'necc program.nelua'
				' uses the full Nelua frontend and TinyCC as its C backend.'
			<li>
				<code> 'necc --native program.nelua'
				' sends the full frontend’s generated C through necc’s native C frontend. This path requires the program’s generated C to fit the supported subset.'
			<li>
				<code> 'necc --direct program.nelua'
				' selects the self-hosted Nelua subset frontend and the native C backend.'
		<p> 'The C frontend is written in Nelua. Its native backend uses the x86-64 System V calling convention by default.'
		<h2 className="section" id="uefi"> 'Call x86-64 UEFI firmware'
		<p>
			'When the '
			<a href="/nelua/compiler/#freestanding"> 'Nelua frontend'
			' emits C for an EFI entry point or protocol function pointer, necc honors its '
			<code> 'ms_abi'
			' attribute. Firmware can call the entry point, and the application can call firmware through a pointer stored in a protocol table.'
		<p>
			'The '
			<a href="/nelua/neboot/#ovmf"> 'neboot verification'
			' exercises both directions. The compiler emits an ELF object for '
			<a href="/nelua/nelinker/#uefi"> 'nelinker’s EFI output mode'
			'.'
		<h2 className="section" id="linker"> 'Link with nelinker'
		<p>
			'The 19 November 2026 toolchain build accepts an absolute linker path in '
			<code> 'NECC_NELINKER'
			'. With both tools on your PATH and the same SDK selected, rebuild the C example above using '
			<a href="/nelua/nelinker/"> 'nelinker'
			' for its final static link.'
		<pre>
			<code> 'export NECC_NELINKER="$(command -v nelinker)"\nnecc hello.c -o hello\n./hello'
		<p>
			'The SDK’s TinyCC still handles C preprocessing and assembly. When '
			<code> 'NECC_NELINKER'
			' is unset, TinyCC also handles the final link. To see which archive member supplies a symbol, try the '
			<a href="/nelua/nelinker/#archive"> 'direct archive example'
			'.'
		<h2 className="section" id="benchmarks"> 'Compiler timings'
		<p>
			'On 21 November 2026, rebuilding the SDK’s single-threaded TinyCC preprocessor with Nelibc’s unlocked string output reduced median compile time for 128 functions from 9.370 to 5.425 ms. Compiling the Lua opcode table took 53% less time. Both builds used the same necc executable, and produced byte-identical objects for all six compile workloads and the Lua VM probe.'
		<p>
			'Each time below is a median in milliseconds over 23 warm, interleaved rounds on one Intel Core i7-11700F core. The external field contains 13 compiler configurations. Text size is the number of bytes of machine code in necc’s object. The two Lua tables contain data.'
		<div className="table-wrap" html:role="region" aria-label="Updated compiler medians and object sizes" html:tabindex="0">
			<table>
				<caption> 'Static x86-64 Linux · 21 November 2026'
				<thead>
					<tr>
						<th scope="col"> 'Workload'
						<th className="num" scope="col"> 'necc before (ms)'
						<th className="num" scope="col"> 'Updated SDK (ms)'
						<th scope="col"> 'Fastest external (ms)'
						<th className="num" scope="col"> 'necc text (B)'
				<tbody>
					for row in comparisons
						<tr>
							<th scope="row"> row.label
							<td className="num"> row.before
							<td className="num"> row.after
							<td> "{row.best} · {row.external}"
							<td className="num"> row.bytes
		<p>
			'The arithmetic executable took 9.729 ms with the updated SDK and 3.071 ms with Zig cc -O2. The SDK change reduces preprocessing time. Both necc builds emit the same 69 bytes of arithmetic code.'
		<details>
			<summary> 'Compare every compiler configuration'
			<div className="table-wrap" html:role="region" aria-label="Complete compiler field in milliseconds" html:tabindex="0">
				<table>
					<caption> 'Median milliseconds by workload'
					<thead>
						<tr>
							<th scope="col"> 'Compiler'
							for work in comparisons
								<th className="num" scope="col"> work.short
					<tbody>
						for tool in field
							<tr>
								<th scope="row"> tool.label
								for median in tool.medians
									<td className="num"> median
		<p className="upstream-links">
			<a href="/nelua/assets/necc-20261121/summary.csv"> 'Timings, quartiles and object sizes (CSV)'
			<a href="/nelua/assets/necc-20261121/samples.csv"> 'All 2,760 samples (CSV)'
			<a href="/nelua/assets/necc-20261121/method.txt"> 'Method and correctness checks'
		<h3> '19 November 2026 toolchain comparison'
		<p>
			'In the '
			<time html:datetime="2026-11-19"> '19 November 2026'
			' static x86-64 Linux shootout, necc improved on its previous release. Other compilers led all six compile-time cases and both generated-program runtime cases. The table shows median milliseconds over 23 warm, interleaved rounds. Each tool had to produce the expected result.'
		<div className="table-wrap" role="region" aria-label="Median compiler and program times in milliseconds" html:tabindex="0">
			<table>
				<thead>
					<tr>
						<th scope="col"> 'Workload'
						<th className="num" scope="col"> 'Previous necc (ms)'
						<th className="num" scope="col"> 'GCC-built necc (ms)'
						<th scope="col"> 'Fastest external (ms)'
				<tbody>
					for row in timings
						<tr>
							<th scope="row"> row[0]
							<td className="num"> row[1]
							<td className="num"> row[2]
							<td> "{row[3]} · {row[4]}"
		<p> 'A separate 25-round measurement of the 128-function input put standalone preprocessing at 4.892 ms. TinyCC finished the entire compile in 1.526 ms in that run. For a larger correctness check, necc compiled all 42 C translation units of the Lua runtime and extensions. The resulting interpreter passed the portable Lua 5.4.6 test suite.'
		<p className="upstream-links">
			<a href="/nelua/assets/toolchain-20261119/toolchain.csv"> 'Compiler and object results (CSV)'
			<a href="/nelua/assets/toolchain-20261119/compiler-stages.csv"> 'Compiler phase timings (CSV)'
		<h2 className="section"> 'Build the distro'
		<p>
			<a href="/nelua/nebuild/"> 'nebuild'
			' runs the build graph that uses necc to compile Nebox and package the Theseus boot image.'
		<div className="actions">
			<a className="button" href="https://github.com/Spaceghost/nebuild"> 'nebuild repository'
			' '
			<a className="button button-ghost" href="/nelua/compiler/"> 'Full Nelua compiler'
