import { readFileSync } from 'node:fs'
export const title = 'Core performance · Nelua'
export const description = 'Compare measured compiler, library and toolchain workloads with reference implementations and individual samples.'

const lifeData = '/nelua/assets/life-20261122/'
const lifeMedians = JSON.parse(readFileSync('public' + lifeData + 'medians.json', 'utf8'))
const timingsRoot = "/nelua/assets/ecosystem-20261121/"
const timings = [
	{ project: "Nelua compiler", path: "compiler/#release-timing", task: "Build the matrix multiplication example", time: "516.77 ms", reference: "Upstream Nelua", refTime: "489.60 ms", finding: "Both matrix programs ran in 15.65 ms at the median.", samplePath: "/nelua/compiler/#release-samples" }
	{ project: "necc", path: "necc/#benchmarks", task: "Compile the Lua VM translation unit", time: "38.32 ms", reference: "SDK TinyCC", refTime: "12.47 ms", finding: "Compilation took 25.85 ms longer with necc.", samplePath: "/nelua/necc/#vm-samples" }
	{ project: "nelinker", path: "nelinker/#benchmarks", task: "Link the full Lua interpreter", time: "7.02 ms", reference: "TinyCC", refTime: "7.15 ms", finding: "Peak memory was nearly identical at 5,364 and 5,420 KiB.", samplePath: "/nelua/nelinker/#link-samples" }
	{ project: "nebuild", path: "nebuild/#benchmarks", task: "Check an unchanged target among 2,048 rules", time: "3.735 ms", reference: "Ninja", refTime: "3.884 ms", finding: "For 256 rules, nebuild took 0.788 ms and Ninja took 2.464 ms.", samplePath: "/nelua/nebuild/#build-samples" }
	{ project: "Nelibc", path: "nelibc/#performance", task: "Search 64 KiB of alternating ab for aa with memmem", time: "2.88 µs", reference: "glibc", refTime: "44.05 µs", finding: "The previous Nelibc took 217.87 µs for the same miss.", samples: "substring.csv" }
	{ project: "Nebox", path: "nebox/#line-count", task: "Count 47,135 source lines with wc -l", time: "1.61 ms", reference: "GNU wc", refTime: "0.97 ms", finding: "The previous Nebox took 4.66 ms. All runs returned the same count.", samples: "wc.csv" }
	{ project: "nsh", path: "nebox/nsh/#shell-time", task: "Run the shell catalog script", time: "14.77 ms", reference: "Debian dash", refTime: "7.27 ms", finding: "Startup alone favored nsh at 0.49 ms versus 0.71 ms.", samples: "shell.csv" }
]

export def body comparison
	<div className="overview">
		<section className="overview-section" aria-labelledby="performance">
			<h1 id="performance"> 'Core performance'
			<p className="bench-intro"> 'Median wall times from 21–22 November 2026. Each comparison used the same input and host, with implementations taking turns. Shorter times are better.'
			<article className="bench-feature">
				<div>
					<p className="eyebrow"> 'necc · Generated program runtime'
					<h3> 'A million Lua calls took 50 ms less'
					<p> 'With only the VM object rebuilt, one million Lua calls took 227.21 ms at e1eab18 and 176.88 ms at 22180f5. SDK TinyCC finished in 68.89 ms.'
					<a href="/nelua/necc/#vm-samples"> 'Inspect the 15 rounds'
				<dl className="bench-chart" aria-label="Median time to run one million Lua calls">
					for item in [{label: 'Previous necc', value: 227.21}, {label: 'Updated necc', value: 176.88}, {label: 'TinyCC', value: 68.89}]
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
				' 0.26 s after menu selection. The working shell followed 12.37 s later under QEMU software emulation.'
			<div className="bench-sources">
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
						for row in [["SDK TinyCC", "3.85", "12.34", "2.18"], ["necc · library copy", "15.03", "8.92", "1.84"], ["necc · builtin copy", "14.93", "7.66", "1.33"], ["GCC -O2", "2,147.30", "1.84", "0.31"], ["Clang -O2", "1,139.70", "1.85", "0.30"]]
							<tr>
								<th scope="row"> row[0]
								for value in row.slice(1)
									<td> value
			<p> 'LZ4 reads short, unaligned values with memcpy. Building the codec with necc 7ed048c and -DLZ4_memcpy=__builtin_memcpy eliminated all 59 direct calls to memcpy in its assembly. Fixed-size reads and writes use exact-width instructions. Both necc rows use the same compiler binary.'
			<p> 'At acceleration 1, the builtin cut compression time by 14% and decompression time by 28%. At acceleration 4, compression took 6.71 ms and the output grew from 430,145 to 477,127 bytes. GCC and Clang still compressed the default case in under 1.9 ms.'
			<details>
				<summary> 'Inputs, method and individual samples'
				<p> 'The corpus concatenates tracked Lua files under lualib/nelua at 0f29b8f in Git tree order. Eleven shuffled rounds followed one warm-up on logical CPU 5. Each round rebuilt the object and timed nine in-memory compressions and decompressions per setting. File I/O, linking and verification fall outside the codec intervals.'
				<p> 'Toolchains were native necc 7ed048c, its SDK TinyCC, GCC 16.2.1 and Clang 23.1.5. All compiled LZ4 1.10.0 with portable memory access and an equivalent typedef-based static assertion. The common GCC-built driver checked the round trip. Each compressed block matched the reference SHA-256 for its setting.'
				<pre> readFileSync('src/content/lz4-copy.csv', 'utf8').trimEnd()
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
