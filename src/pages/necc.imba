export const title = 'necc · Native compiler driver · Nelua at spacegho.st'
export const description = 'Build C and Nelua programs for x86-64 Linux against standalone Nelibc, or run Lua with the necc compiler driver.'

const timings = [
	['Compile 128 functions', '16.038', '8.727', '1.506', 'TinyCC']
	['Run six million arithmetic iterations', '20.277', '9.371', '2.099', 'Zig cc -O2']
]

export def body
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"> 'Core · the compiler driver'
			<h1> 'necc'
			<p className="lead"> 'A compiler driver for x86-64 Linux. Use it to build C and Nelua programs against standalone Nelibc or run Lua from the same toolchain.'
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
		<p> 'The C frontend is written in Nelua and emits assembly for the x86-64 System V ABI.'
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
