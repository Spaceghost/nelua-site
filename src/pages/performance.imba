import { readFileSync } from 'node:fs'
export const title = 'Core performance · Nelua'
export const description = 'Compare measured compiler, library and toolchain workloads with reference implementations and individual samples.'

const lifeData = '/nelua/assets/life-20261122/'
const lifeMedians = JSON.parse(readFileSync('src/content/results-20261122/life-medians.json', 'utf8'))
const timingsRoot = "/nelua/assets/ecosystem-20261121/"
const timings = [
	{ project: "Nelua compiler", path: "compiler/#release-timing", task: "Build the matrix multiplication example", time: "757.87 ms", reference: "Upstream Nelua", refTime: "742.55 ms", finding: "The previous fork took 766.23 ms. The updated program ran in 29.57 ms, upstream in 29.50 ms.", samplePath: "/nelua/compiler/#release-samples" }
	{ project: "necc", path: "necc/#benchmarks", task: "Compile the Lua VM translation unit", time: "38.32 ms", reference: "SDK TinyCC", refTime: "12.47 ms", finding: "Compilation took 25.85 ms longer with necc.", samplePath: "/nelua/necc/#vm-samples" }
	{ project: "nelinker", path: "nelinker/#benchmarks", task: "Link the full Lua interpreter", time: "7.02 ms", reference: "TinyCC", refTime: "7.15 ms", finding: "Peak memory was nearly identical at 5,364 and 5,420 KiB.", samplePath: "/nelua/nelinker/#link-samples" }
	{ project: "nebuild", path: "nebuild/#benchmarks", task: "Check an unchanged target among 2,048 rules", time: "3.735 ms", reference: "Ninja", refTime: "3.884 ms", finding: "For 256 rules, nebuild took 0.788 ms and Ninja took 2.464 ms.", samplePath: "/nelua/nebuild/#build-samples" }
	{ project: "Nelibc", path: "nelibc/#performance", task: "Search 64 KiB of alternating ab for aa with memmem", time: "2.86 µs", reference: "glibc", refTime: "43.11 µs", finding: "The previous Nelibc took 217.42 µs for the same miss.", samplePath: "/nelua/nelibc/#substring-samples" }
	{ project: "Nebox", path: "nebox/#line-count", task: "Count 47,135 source lines with wc -l", time: "1.64 ms", reference: "GNU wc", refTime: "1.04 ms", finding: "The previous Nebox took 5.03 ms. All runs returned the same count.", samplePath: "/nelua/nebox/#line-count" }
	{ project: "nsh", path: "nebox/nsh/#shell-time", task: "Run the shell catalog script", time: "8.83 ms", reference: "Debian dash", refTime: "4.46 ms", finding: "Startup alone favored nsh at 0.36 ms versus 0.52 ms.", samplePath: "/nelua/nebox/nsh/#shell-time" }
]

export def body comparison
	<div className="overview">
		<section className="overview-section" aria-labelledby="performance">
			<h1 id="performance"> 'Core performance'
			<p className="bench-intro"> 'Median times from the 22 November 2026 shootout. Each comparison used the same input and host, with implementations taking turns. Shorter times are better.'
			<article className="bench-feature">
				<div>
					<p className="eyebrow"> 'necc · Generated program runtime'
					<h3> 'A million Lua calls took 50 ms less'
					<p> 'With only the VM object rebuilt, one million Lua calls took 227.21 ms at e1eab18 and 176.88 ms at 22180f5. SDK TinyCC finished in 68.89 ms.'
					<a href="/nelua/necc/#vm-samples"> 'Inspect the 15 rounds'
				<dl className="bench-chart" aria-label="Median time to run one million Lua calls">
					for item in [{label: 'necc e1eab18', value: 227.21}, {label: 'necc 22180f5', value: 176.88}, {label: 'TinyCC', value: 68.89}]
						<div>
							<dt> item.label
							<dd>
								<strong> "{item.value} ms"
								<meter min=0 max=227.21 value=item.value aria-hidden="true">
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
							<a href=(row.samplePath || timingsRoot + row.samples)> "{row.project} samples"
			<p className="bench-boot">
				<strong> 'Boot timing · '
				<a href="/nelua/neboot/#efi-boot-time"> 'neboot reached EFI handoff'
				' 4.00 s after menu selection. The working shell followed 28.30 s later under QEMU software emulation.'
			<div className="bench-sources">
				<a href="/nelua/assets/core-shootout.zip"> '22 November results, individual samples and LZ4 replay (ZIP)'
				<a href=(timingsRoot + 'reproduce.txt')> '21 November hardware and reproduction steps'
				<a href=(timingsRoot + 'summary.csv')> '21 November medians, quartiles and ranges'
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
						for row in [["SDK TinyCC", "3.83", "12.20", "2.14"], ["necc 7ed048c · previous", "14.66", "8.75", "1.81"], ["necc 55612d9 · default", "14.08", "8.53", "1.73"], ["necc 55612d9 · -fbuiltin-memcpy", "14.21", "7.08", "1.12"], ["GCC -O2", "2,103.09", "1.81", "0.31"], ["Clang -O2", "1,104.12", "1.85", "0.30"]]
							<tr>
								<th scope="row"> row[0]
								for value in row.slice(1)
									<td> value
			<p> 'LZ4 checks the machine word size when selecting a hash function. Native necc now evaluates that guard during compilation and branches directly on the remaining comparison.'
			<p> 'With -fbuiltin-memcpy, necc also translates ordinary short copies into exact-width loads and stores. Against the previous default, compression time fell 19% and decompression time fell 38%. At acceleration 4 the new build compressed in 6.20 ms and produced 477,127 bytes.'
			<p> 'TinyCC still built the object fastest. GCC and Clang produced the fastest codec. The necc assembly retains calls to hash and match-counting helpers that GCC inlines.'
			<details>
				<summary> 'Inputs, method and individual samples'
				<p> 'The corpus concatenates tracked Lua files under lualib/nelua at 0f29b8f in Git tree order. Eleven shuffled rounds followed one warm-up on logical CPU 5. Each round rebuilt the object and timed nine in-memory compressions and decompressions per setting. File I/O, linking and verification fall outside the codec intervals.'
				<p> 'Toolchains were native necc 7ed048c and 55612d9, its SDK TinyCC, GCC 16.2.1 and Clang 23.1.5. All compiled LZ4 1.10.0 with portable memory access and an equivalent typedef-based static assertion. The common GCC-built driver checked the round trip. Each compressed block matched the reference SHA-256 for its setting.'
				<pre> readFileSync('src/content/results-20261122/lz4/native.csv', 'utf8').trimEnd()
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
			<p> 'The new shootout uses necc 7ed048c. Native builds call a C implementation of the rule. Chromium and Node run the shipped Wasm and Bend JavaScript. Timings cover board updates with rendering and playback delays excluded. The Wasm module grew from 232 to 290 bytes.'
			<div className="bench-sources">
				<a href="/nelua/examples/life/"> 'Play Game of Life'
				<a href="/nelua/assets/core-shootout.zip"> 'Individual Life samples (ZIP)'
				<a href=(lifeData + 'reproduce.txt')> 'Fixture, original tool versions and replay commands'
				<a href=(lifeData + 'replay.tar.gz')> 'Download the benchmark'
		<section className="overview-section" aria-labelledby="libc-comparison">
			<div innerHTML=comparison>
