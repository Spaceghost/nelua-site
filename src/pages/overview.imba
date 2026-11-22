import { files, opcodeNames } from '../showcase-files.mjs'
import { readFileSync } from 'node:fs'
import { highlight } from '../example-code.mjs'

export const title = 'Nelua · Lua syntax for native programs'
export const description = 'Boot Linux with a Nelua init and shell, then explore C interop and compile-time functions. Explore the Spaceghost compiler fork and projects built with it.'

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

def example filename, output
	const source = readFileSync('public/nelua/examples/' + filename, 'utf8').trimEnd()
	<figure className="language-example">
		<figcaption>
			<a href=('/nelua/examples/' + filename) download=filename> filename
		<pre>
			<code innerHTML=highlight(source)>
		<div className="example-output">
			<span> 'Output'
			<samp> output

export def body
	<div className="overview">
		<section className="language-hero" aria-labelledby="overview-title">
			<div>
				<h1 id="overview-title"> 'Nelua'
				<p className="language-lead"> 'Write the first program Linux runs.'
				<p> 'When this Linux guest boots, the kernel hands control to Nelua code. Theseus Init mounts the filesystems and starts a Nebox shell. You can type commands at its console, right here in your browser.'
				<div className="actions">
					<a className="button" href="/nelua/init/?boot=1#browser-demo"> 'Boot Linux in your browser'
					<a href="https://nelua.io/tutorial/"> 'Learn Nelua'
				<p className="run-example"> 'About 30 MB to start the local VM.'
			<div className="source-browser" id="examples">
				<div className="source-tabs" html:role="tablist" aria-label="Nelua source files" html:hidden="">
					for file in files
						<button type="button" html:role="tab" id=("tab-" + file.key) aria-controls=("file-" + file.key)> file.file
				for file in files
					<article className="language-example source-file" id=("file-" + file.key)>
						<header>
							<span> file.project
							<h2> file.title
						<pre>
							<code innerHTML=highlight(file.code)>
						<p> file.note
						if file.key == 'assembler'
							<div className="opcode-inspector">
								<label for="opcode-name" html:hidden=""> 'Inspect opcode'
								<select id="opcode-name" html:hidden="">
									for name in opcodeNames
										<option value=name> name
								<output id="opcode-result" for="opcode-name"> 'local asm.HALT: uint8 <comptime> = 0'
						if file.key == 'life'
							<a className="file-origin" href="/nelua/examples/life/"> 'Step a glider with Imba, Bend and WebAssembly'
							<details className="generated-c">
								<summary> 'Show generated C'
								<p> 'GameState:step as emitted by the Nelua fork at 874acdd.'
								<pre>
									<code innerHTML=highlight(readFileSync('src/content/gameoflife-step.c', 'utf8').trimEnd())>
						if file.key == 'boot'
							<div className="example-output">
								<span> 'Console'
								<samp> 'theseus: starting console shell'
						<a className="file-origin" href=file.source> "View {file.file} on GitHub"
		<section className="overview-section" aria-labelledby="language">
			<h2 id="language"> 'From source to executable'
			<div className="language-tour">
				<article>
					<h3> 'Call a C library'
					<p> 'Declare a C function with its argument and return types. This program calls puts from the C standard library.'
					example('c-call.nelua', 'Hello from Nelua')
				<article>
					<h3> 'Compute a value while compiling'
					<p> 'In the Spaceghost fork, a function marked <comptime> runs during compilation. Here the executable prints the precomputed tile count.'
					example('comptime.nelua', '256')
			<div className="core-guides">
				<a href="https://nelua.io/installing/"> 'Install Nelua'
				<a href="https://nelua.io/overview/"> 'Explore the language'
				<a href="/nelua/compiler/comptime/"> 'Compile-time programming in the fork'
				<a href="/nelua/compiler/syntax-extensions/"> 'Fork syntax guide'
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
			<a id="performance" href="/nelua/performance/"> 'Core performance measurements'
			<a id="libc-comparison" href="/nelua/performance/#libc-comparison"> 'Nelibc benchmark comparison'
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
