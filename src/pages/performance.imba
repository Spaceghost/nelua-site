export const title = 'Core performance · Nelua'
export const description = 'Compare measured compiler, library and toolchain workloads with reference implementations and individual samples.'

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
		<section className="overview-section" aria-labelledby="libc-comparison">
			<div innerHTML=comparison>
