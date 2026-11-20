export const title = 'Nelua at spacegho.st · Compiler, libc and userland'
export const description = 'Explore the Spaceghost Nelua compiler fork, nelibc and nebox, plus projects and the wider Nelua community.'

const core = [
	{ title: 'Compiler', path: '/nelua/compiler/', kind: 'Language', description: 'A Nelua compiler fork with exhaustive matching, ownership, compile-time evaluation and file-local syntax extensions.' }
	{ title: 'nelibc', path: '/nelua/nelibc/', kind: 'C library', description: 'A C library written in Nelua, with hybrid builds over glibc, musl and Cosmopolitan and a standalone Linux runtime.' }
	{ title: 'nebox', path: '/nelua/nebox/', kind: 'Userland', description: 'Unix applets and an interactive POSIX shell in a single static executable linked against standalone nelibc.' }
]

const workshop = [
	{ title: 'necc', path: '/nelua/necc/', description: 'Compile C and Nelua against standalone Nelibc or run Lua from the staged SDK.' }
	{ title: 'nelinker', path: '/nelua/nelinker/', description: 'Link x86-64 Linux executables directly from ELF objects and static archives.' }
	{ title: 'nebuild', path: '/nelua/nebuild/', description: 'Run incremental, parallel builds from a build.ne dependency graph.' }
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
					<a className="text-link" href="https://github.com/Spaceghost/nelua-lang"> 'Compiler on GitHub'
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
				<a href="/nelua/nebox/nsh/"> 'The nsh shell'
		<section className="overview-section" aria-labelledby="libc-comparison">
			<div innerHTML=comparison>
		<section className="overview-section" aria-labelledby="build">
			<div className="build-panel">
				<div>
					<h2 id="build"> 'Build the stack'
					<p> 'Build the compiler fork, the standalone Nelibc archive and nebox on Linux x86-64 with Git, Make and Zig installed.'
					<a href="/nelua/compiler/#freestanding"> 'About freestanding builds'
				<pre>
					<code> 'git clone https://github.com/Spaceghost/nelua-lang\nmake -C nelua-lang\ngit clone https://github.com/Spaceghost/nelibc\nmake -C nelibc lib-standalone-zig\ngit clone https://github.com/Spaceghost/nebox\nmake -C nebox NELIBC=../nelibc test'
		<div className="overview-section outer-rings">
			<section aria-labelledby="workshop">
				<h2 id="workshop"> 'Workshop'
				<p className="lead"> 'Libraries and programs built on the Nelua core.'
				projectList(workshop)
			<section aria-labelledby="world">
				<h2 id="world"> 'World'
				<p className="lead"> 'Upstream Nelua and the wider community.'
				projectList(world)
				<p className="upstream-links">
					<a href="https://github.com/edubart/nelua-batteries"> 'Libraries'
					<a href="https://github.com/edubart/nelua-decl"> 'C bindings'
					<a href="https://github.com/edubart/nene"> 'nene game engine'
