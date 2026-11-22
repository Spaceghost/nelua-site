export const title = 'Nelua at spacegho.st · Compiler, libc and userland'
export const description = 'Explore the Nelua compiler, C library, userland, native build tools, projects built with Nelua, and the wider community.'

export const core = [
	{ title: 'Compiler', path: '/nelua/compiler/', kind: 'Language', description: 'A Nelua compiler fork with exhaustive matching, ownership, compile-time evaluation and file-local syntax extensions.' }
	{ title: 'nelibc', path: '/nelua/nelibc/', kind: 'C library', description: 'A C library written in Nelua, with hybrid builds over glibc, musl and Cosmopolitan and a standalone Linux runtime.' }
	{ title: 'nebox', path: '/nelua/nebox/', kind: 'Userland', description: 'Unix applets in a single static executable linked against standalone nelibc.' }
	{ title: 'neboot', path: '/nelua/neboot/', kind: 'Boot manager', description: 'A UEFI boot menu written in Nelua. Start Cascadia with Theseus Init or OpenRC recovery, or chainload another EFI application.' }
	{ title: 'nsh', path: '/nelua/nebox/nsh/', kind: 'Shell', description: 'The interactive POSIX shell included in nebox, with command completion, searchable history and job control.' }
	{ title: 'necc', path: '/nelua/necc/', kind: 'Compiler driver', description: 'Compile C and Nelua against standalone Nelibc or run Lua from the staged SDK.' }
	{ title: 'nelinker', path: '/nelua/nelinker/', kind: 'Linker', description: 'Link x86-64 ELF objects into Linux executables or PE32+ EFI applications.' }
	{ title: 'nebuild', path: '/nelua/nebuild/', kind: 'Build runner', description: 'Run incremental, parallel builds from a build.ne dependency graph.' }
]

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

const workshop = [
	{ title: 'Theseus Init', path: '/nelua/init/', description: 'Boot Linux and supervise services with native CUE definitions and an adapter for OpenRC services.' }
	{ title: 'Drift', path: 'https://github.com/Spaceghost/drift', description: 'Portable Virtio, xHCI, NVMe, Ethernet and AHCI drivers written in Nelua.' }
	{ title: 'Atlas firmware', path: 'https://github.com/Spaceghost/atlas-firmware', description: 'ESP32-S3 LoRa field controllers using Nelua alongside Lua and ESP-IDF.' }
	{ title: 'melodica.h', path: 'https://spacegho.st/melodica/', description: 'Five implementations of the Pandora protocol behind one C ABI, including Nelua.' }
	{ title: 'libc.bend', path: 'https://github.com/Spaceghost/libc.bend', description: 'A Bend 2 libc built on the Nelibc host profile.' }
	{ title: 'Writ', path: 'https://github.com/Spaceghost/writ', description: 'Information-flow control in Bend 2 and the first consumer of the Nelibc host profile.' }
]

const world = [
	{ title: 'Nelua Community', path: '/nelua/community/', description: 'Search the Nelua source index by builder or project.' }
	{ title: 'Nelua documentation', path: 'https://nelua.io/', description: 'The upstream language overview, tutorial and reference.' }
	{ title: 'Upstream compiler', path: 'https://github.com/edubart/nelua-lang', description: 'The fork tracks upstream Nelua. Its base is a584505 from 2025-06-24.' }
	{ title: 'Discord', path: 'https://discord.gg/7aaGeG7', description: 'Talk with the Nelua community.' }
]

def projectList items
	<ul className="project-list">
		for item in items
			<li>
				<a href=item.path> item.title
				<p> item.description

export def body comparison
	<div className="overview">
		<section className="overview-hero" aria-labelledby="overview-title">
			<p className="eyebrow"> 'The Nelua ecosystem'
			<h1 id="overview-title">
				<span> 'Nelua'
				<span> 'A native stack'
			<div className="hero-details">
				<p> 'A compiler, C library and Unix userland in one systems programming ecosystem. Nelua brings Lua syntax and compile-time metaprogramming to native programs that compile through C.'
				<div className="actions">
					<a className="button" href="#core"> 'Explore the stack'
					<a className="text-link" href="https://github.com/Spaceghost/nelua"> 'Compiler on GitHub'
		<section className="overview-section" aria-labelledby="core">
			<h2 id="core"> 'Core'
			<div className="core-grid">
				for item in core
					<article>
						<p className="eyebrow"> item.kind
						<h3>
							<a href=item.path> item.title
						<p> item.description
			<div className="core-guides">
				<a href="/nelua/compiler/syntax-extensions/"> 'Syntax extensions guide'
				<a href="/nelua/compiler/comptime/"> 'Compile-time record configs'
		<section className="overview-section" aria-labelledby="performance">
			<h2 id="performance"> 'Core performance'
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
		<section className="overview-section" aria-labelledby="build">
			<div className="build-panel">
				<div>
					<h2 id="build"> 'Build the stack'
					<p> 'Build the compiler fork, the standalone Nelibc archive and nebox on Linux x86-64 with Git, Make and Zig installed.'
					<a href="/nelua/compiler/#freestanding"> 'About freestanding builds'
				<pre>
					<code> 'git clone https://github.com/Spaceghost/nelua\nmake -C nelua\ngit clone https://github.com/Spaceghost/nelibc\nmake -C nelibc lib-standalone-zig\ngit clone https://github.com/Spaceghost/nebox\nmake -C nebox NELIBC=../nelibc test'
		<div className="overview-section outer-rings">
			<section aria-labelledby="workshop">
				<h2 id="workshop"> 'Workshop'
				<p className="lead"> 'Libraries and programs built on the Nelua core.'
				projectList(workshop)
				<ul className="project-list">
					<li>
						<a href="https://github.com/Spaceghost/cascadia/releases/tag/core-dev-2026.11.20"> 'Cascadia developer image'
						<p> 'Boot an x86-64 VM and rebuild Core from its Nebox login shell. These files are available to accounts with access to the Cascadia repository.'
						<p>
							<a href="https://github.com/Spaceghost/cascadia/releases/download/core-dev-2026.11.20/core-release-inputs.tar.gz"> 'Pinned sources and build inputs'
							' · '
							<a href="https://github.com/Spaceghost/cascadia/releases/download/core-dev-2026.11.20/vmlinuz"> 'Boot kernel'
							' · '
							<a href="https://github.com/Spaceghost/cascadia/releases/download/core-dev-2026.11.20/cascadia-core-x86_64.cpio.gz"> 'Developer image'
							' · '
							<a href="https://github.com/Spaceghost/cascadia/releases/download/core-dev-2026.11.20/cascadia-core-rebuilt-x86_64.cpio.gz"> 'Guest-built image'
							' · '
							<a href="https://github.com/Spaceghost/cascadia/releases/download/core-dev-2026.11.20/SHA256SUMS"> 'Checksums'
							' · '
							<a href="https://github.com/Spaceghost/cascadia/blob/core-dev-2026.11.20/docs/CORE-DEVELOPER.md"> 'Build instructions'
							' · '
							<a href="https://github.com/Spaceghost/cascadia/releases/download/core-dev-2026.11.20/boot-evidence.tar.gz"> 'Boot evidence'
			<section aria-labelledby="world">
				<h2 id="world"> 'World'
				<p className="lead"> 'Upstream Nelua and the wider community.'
				projectList(world)
				<p className="upstream-links">
					<a href="https://github.com/edubart/nelua-batteries"> 'Libraries'
					<a href="https://github.com/edubart/nelua-decl"> 'C bindings'
					<a href="https://github.com/edubart/nene"> 'nene game engine'
