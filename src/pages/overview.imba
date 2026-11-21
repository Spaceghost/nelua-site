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
			<p> 'Each project names the workloads, hardware and baselines used for its timings. Open a comparison for the measured results and individual samples.'
			<div className="core-guides">
				<a href="/nelua/compiler/#performance"> 'Nelua syntax checks and C generation'
				<a href="/nelua/nelibc/#performance"> 'C library routines'
				<a href="/nelua/necc/#benchmarks"> 'C compilation and program runtime'
				<a href="/nelua/nelinker/#benchmarks"> 'Linking and archive creation'
				<a href="/nelua/nebuild/#benchmarks"> 'Incremental builds'
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
