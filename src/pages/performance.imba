import { readFileSync } from 'node:fs'
export const title = 'Core performance · Nelua'
export const description = 'Compare measured compiler, library and toolchain workloads with reference implementations and individual samples.'

const lifeData = '/nelua/assets/life-20261122/'
const lifeMedians = JSON.parse(readFileSync('public' + lifeData + 'medians.json', 'utf8'))
const timingsRoot = "/nelua/assets/ecosystem-20261121/"
const timings = [
	{ project: "Nelua compiler", path: "compiler/#performance", task: "Build the matrix multiplication example", time: "1.109 s", reference: "Upstream Nelua", refTime: "1.159 s", finding: "The resulting programs ran in 29.62 and 29.73 ms.", samples: "nelua.csv" }
	{ project: "necc", path: "necc/#benchmarks", task: "Compile the Lua VM translation unit", time: "138.43 ms", reference: "SDK TinyCC", refTime: "23.77 ms", finding: "Compilation took 115 ms longer with necc.", samples: "necc-final.csv" }
	{ project: "nelinker", path: "nelinker/#benchmarks", task: "Link the full Lua interpreter", time: "10.71 ms", reference: "TinyCC", refTime: "16.31 ms", finding: "Peak memory was nearly identical at 5,532 and 5,528 KiB.", samples: "link-vm.csv" }
	{ project: "nebuild", path: "nebuild/#benchmarks", task: "Check an unchanged target among 2,048 rules", time: "4.70 ms", reference: "Ninja", refTime: "3.89 ms", finding: "For 256 rules, nebuild took 1.05 ms and Ninja took 2.34 ms.", samples: "incremental.csv" }
	{ project: "Nelibc", path: "nelibc/#performance", task: "Search 64 KiB of alternating ab for aa with memmem", time: "2.88 µs", reference: "glibc", refTime: "44.05 µs", finding: "The previous Nelibc took 217.87 µs for the same miss.", samples: "substring.csv" }
	{ project: "Nebox", path: "nebox/#line-count", task: "Count 47,135 source lines with wc -l", time: "1.61 ms", reference: "GNU wc", refTime: "0.97 ms", finding: "The previous Nebox took 4.66 ms. All runs returned the same count.", samples: "wc.csv" }
	{ project: "nsh", path: "nebox/nsh/#shell-time", task: "Run the shell catalog script", time: "14.77 ms", reference: "Debian dash", refTime: "7.27 ms", finding: "Startup alone favored nsh at 0.49 ms versus 0.71 ms.", samples: "shell.csv" }
]

export def body comparison
	<div className="overview">
		<section className="overview-section" aria-labelledby="performance">
			<h1 id="performance"> 'Core performance'
			<p className="bench-intro"> 'Median wall times from 21 November 2026. Each comparison used the same input and host, with implementations taking turns. Shorter times are better.'
			<article className="bench-feature">
				<div>
					<p className="eyebrow"> 'necc · Generated program runtime'
					<h3> 'A million Lua calls took 108 ms less'
					<p> 'Changing how the compiled Lua VM dispatches bytecode cut its median runtime across 15 rounds. The TinyCC-built interpreter still finished 329 ms sooner.'
					<a href=(timingsRoot + 'vm.csv')> 'Inspect the 15 rounds'
				<dl className="bench-chart" aria-label="Median time to run one million Lua calls">
					for item in [{label: 'Previous necc', value: 606}, {label: 'Updated necc', value: 498}, {label: 'TinyCC', value: 169}]
						<div>
							<dt> item.label
							<dd>
								<strong> "{item.value} ms"
								<meter min=0 max=606 value=item.value aria-hidden="true">
			<h3 className="bench-subtitle"> 'Time per workload'
			<div className="bench-list">
				for row in timings
					<article className="bench-row">
						<div className="bench-work">
							<a href=('/nelua/' + row.path)> row.project
							<h4> row.task
						<dl className="bench-pair">
							<div>
								<dt> row.project
								<dd> row.time
							<div>
								<dt> row.reference
								<dd> row.refTime
						<div className="bench-note">
							<p> row.finding
							<a href=(timingsRoot + row.samples)> "{row.project} samples"
			<p className="bench-boot">
				<strong> 'Boot timing · '
				<a href="/nelua/neboot/#efi-boot-time"> 'neboot reached EFI handoff'
				' 0.26 s after menu selection. The working shell followed 12.37 s later under QEMU software emulation.'
			<div className="bench-sources">
				<a href=(timingsRoot + 'reproduce.txt')> 'Hardware, revisions and reproduction steps'
				<a href=(timingsRoot + 'summary.csv')> 'Download medians, quartiles and ranges'
		<section className="overview-section" aria-labelledby="lz4-shootout">
			<h2 id="lz4-shootout"> 'LZ4 compresses the Nelua compiler source'
			<p> 'Four compilers built the LZ4 1.10.0 block codec. Each build compressed the same 62 Lua files into 430,145 bytes at the default acceleration and restored all 1,141,485 input bytes exactly.'
			<div className="table-wrap" html:role="region" aria-label="LZ4 compiler comparison" html:tabindex="0">
				<table>
					<caption> 'Median milliseconds · Intel Core i7-11700F · 11 rounds · 22 November 2026'
					<thead>
						<tr>
							for label in ['Compiler', 'Build codec object', 'Compress', 'Decompress']
								<th scope="col"> label
					<tbody>
						for row in [["TinyCC", "4.84", "9.33", "1.70"], ["necc before", "15.30", "11.47", "2.13"], ["necc updated", "15.20", "8.84", "1.80"], ["GCC -O2", "2,181.82", "1.83", "0.31"], ["Clang -O2", "1,153.06", "1.85", "0.31"]]
							<tr>
								<th scope="row"> row[0]
								for value in row.slice(1)
									<td> value
			<p> 'necc used to push scalar arguments onto the stack and immediately pop them into call registers. The updated compiler loads eligible arguments directly and expands small private helpers at the call site. The LZ4 object’s machine code shrank from 34,524 to 34,311 bytes.'
			<p> 'Raising LZ4 acceleration from 1 to 4 reduced necc compression time from 8.84 to 7.74 ms. The compressed block grew by 46,982 bytes (10.9%).'
			<details>
				<summary> 'Inputs and measurement method'
				<p> 'The input concatenates tracked .lua files under lualib/nelua at Nelua revision 0f29b8f in Git tree order. Each shuffled round builds the object once and runs nine in-memory compressions and decompressions per setting on logical CPU 5. Timings exclude linking, file I/O and verification from the codec runs. One warm-up round was discarded.'
				<p> 'In separate stage timings, updated necc spent 3.83 ms preprocessing, 5.90 ms compiling preprocessed C to assembly, and 5.80 ms assembling. Each stage timing includes its own driver launch.'
				<p> 'Toolchains were necc e1eab18 and 22180f5, TinyCC 0.9.27, GCC 16.2.1 and Clang 23.1.5. All used the same LZ4 source with portable memory access and an equivalent typedef-based static assertion for necc compatibility. The common driver was built with GCC -O2. All four compilers produced identical compressed bytes at each setting.'
		<section className="overview-section" aria-labelledby="life-shootout">
			<h2 id="life-shootout"> 'Game of Life compiler shootout'
			<p> 'The original row update counted the neighbors around each cell from scratch. The new version keeps two column totals and counts only the column entering the window. Both call the same survival rule once per cell.'
			<div className="table-wrap" html:role="region" aria-label="Game of Life timings" html:tabindex="0">
				<table>
					<caption> '16,384 generations · Intel Core i7-11700F · 22 November 2026 · median of 11 runs'
					<thead>
						<tr>
							<th scope="col"> 'Tool'
							<th scope="col"> 'Original run (ms)'
							<th scope="col"> 'Updated run (ms)'
							<th scope="col"> 'Speedup'
							<th scope="col"> 'Compile updated C to object (ms)'
					<tbody>
						for row in lifeMedians
							<tr>
								<th scope="row"> row.tool
								<td> row.before.toFixed(2)
								<td> row.after.toFixed(2)
								<td> "{row.speedup.toFixed(2)}×"
								<td> (row.compile ? row.compile.toFixed(2) : '—')
			<p> 'Native builds call a C implementation of the rule. Chromium and Node run the shipped Wasm and Bend JavaScript. Timings cover board updates with rendering and playback delays excluded. The Wasm module grew from 232 to 290 bytes.'
			<div className="bench-sources">
				<a href="/nelua/examples/life/"> 'Play Game of Life'
				<a href=(lifeData + 'samples.csv')> 'Individual samples'
				<a href=(lifeData + 'reproduce.txt')> 'Method and tool versions'
				<a href=(lifeData + 'replay.tar.gz')> 'Download the benchmark'
		<section className="overview-section" aria-labelledby="libc-comparison">
			<div innerHTML=comparison>
