import { readFileSync } from 'node:fs'
export const title = 'nelinker · Static ELF linker · Nelua at spacegho.st'
export const description = 'Link x86-64 and AArch64 ELF objects and static archives into Linux executables, or link x86-64 PE32+ UEFI applications.'

const timings = [
	["Three loose objects", "1.428", "1.435", "TinyCC · 1.504", "205", "727"]
	["257 loose objects", "3.839", "3.747", "TinyCC · 6.053", "2,491", "3,015"]
	["32,768 relocations", "2.551", "2.408", "GNU-gold · 3.477", "270,336", "263,031"]
	["8,192 distinct symbols", "5.432", "4.494", "TinyCC · 4.910", "106,496", "99,191"]
	["SDK syscall, loose objects", "1.436", "1.451", "TinyCC · 1.526", "4,378", "1,088"]
	["SDK syscall, archive-suite control", "1.457", "1.459", "TinyCC · 1.537", "4,378", "1,088"]
	["One member from the SDK archive", "1.614", "1.587", "TinyCC · 1.736", "4,378", "1,088"]
	["One member from 256", "1.512", "1.493", "TinyCC · 1.504", "196", "719"]
	["256 members, reverse dependency order", "2.863", "2.678", "GNU-gold · 5.034", "2,491", "3,015"]
	["All 256 archive members", "2.389", "2.306", "GNU-gold · 3.870", "1,726", "2,247"]
	["Whole SDK with allocator", "5.077", "4.677", "TinyCC · 5.783", "995,860", "992,583"]
]

const nelinkerPassRows = [
	["SDK archive member", "ld.bfd", "0.51", "1.85", "1,696", "4,936"]
	["Whole interpreter", "TinyCC", "7.02", "7.15", "5,364", "5,420"]
]

export def body
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"> 'Core · the linker'
			<h1> 'nelinker'
			<p className="tagline"> 'A static linker written in Nelua for x86-64 and AArch64 Linux executables and x86-64 UEFI applications.'
			<p className="blurb"> 'Give it object files and Unix archives. It resolves symbols, applies relocations and writes an executable. The same linker performs the final link of both itself and the necc compiler driver.'
			<p><a href="https://github.com/Spaceghost/nelinker"> 'nelinker source on GitHub'
			<div className="actions">
				<a className="button" href="#archive"> 'Link an archive'
				<a className="text-link" href="#benchmarks"> 'Compare link times'
		<h2 className="section" id="aarch64"> 'AArch64 Linux'
		<p> 'The AArch64 mode links fixed-address static ELF executables. In Fedora Incus under QEMU, it linked and ran a program that used separate object files, archive extraction, branches, a global offset table and relocated data.'
		<pre><code> 'nelinker --aarch64 -o program start.o libprogram.a'
		<p> 'AArch64 TLS and PE/EFI linking remain open.'
		<p><a href="https://github.com/Spaceghost/nelinker/tree/7071dc7#aarch64-static-elf"> 'Build and test AArch64 Nelinker'
		<h2 className="section" id="archive"> 'Link an archive'
		<p>
			'Save '
			<a href="/nelua/nelinker/examples/start.s" download="start.s"> 'start.s'
			' and '
			<a href="/nelua/nelinker/examples/answer.s" download="answer.s"> 'answer.s'
			' in the same directory. The entry point calls '
			<code> 'answer'
			' and passes its return value to the Linux exit syscall. With GNU binutils and nelinker on your PATH, build the two objects and put the provider in an archive.'
		<pre>
			<code> 'as --64 -o start.o start.s\nas --64 -o answer.o answer.s\nar rcs libanswer.a answer.o\nnelinker -t -o demo start.o libanswer.a\n./demo\necho "$?"'
		<p>
			'The link trace includes '
			<code> 'libanswer.a(answer.o)'
			'. The program exits with status 42. Place an archive after the objects that reference its symbols. Use '
			<code> '--start-group'
			' and '
			<code> '--end-group'
			' around archives that depend on one another.'
		<h2 className="section" id="inputs"> 'Supported inputs'
		<p> 'The default Linux mode produces fixed-address static executables from x86-64 ELF objects. It reads regular GNU/SysV and BSD archives, resolves strong and weak symbols, and supports static GOT entries and local-exec TLS. PIE, shared libraries, thin archives, LTO and custom linker scripts are outside the current scope.'
		<p>
			'For C or Nelua programs using '
			<a href="/nelua/nelibc/"> 'nelibc'
			', let '
			<a href="/nelua/necc/#linker"> 'necc invoke nelinker'
			'. The driver supplies the SDK libraries and their relocation conventions.'
		<h2 className="section" id="uefi"> 'Link a PE32+ EFI application'
		<p>
			'With '
			<code> '--efi-app'
			', nelinker reads freestanding x86-64 ELF objects and static archives and writes a PE32+ EFI application. The entry symbol defaults to '
			<code> 'efi_main'
			'. This command links the neboot menu with a preferred load address of 4 GiB.'
		<pre>
			<code> 'nelinker --efi-app --image-base 0x100000000 -e efi_main -o BOOTX64.EFI menu.o'
		<p>
			'The linker records 64-bit absolute image pointers as '
			<code> 'DIR64'
			' entries in '
			<code> '.reloc'
			' so firmware can adjust them if it loads the image at another address. The '
			<a href="/nelua/neboot/#ovmf"> 'neboot OVMF run'
			' shows the address firmware used.'
		<h2 className="section" id="benchmarks"> 'Link times and executable sizes'
		<p>
			'On '
			<time html:datetime="2026-11-22"> '22 November 2026'
			', the faster of two nelinker builds beat the fastest qualifying external linker in 11 of 11 workloads. Both builds used nelinker a349c2a. The native necc backend built one binary and the SDK TinyCC backend built the other.'
		<p> 'Every median covers 23 shuffled warm rounds on logical CPU 5 of an i7-11700F. Each executable had to return 42 within one second. Across both nelinker builds and seven external linkers, 93 of 99 combinations qualified. Only SDK TinyCC and the two nelinker builds qualified on the whole-SDK allocator.'
		<div className="table-wrap" role="region" aria-label="Median elapsed link time and executable size" html:tabindex="0">
			<table>
				<thead>
					<tr>
						<th scope="col"> 'Workload'
						<th className="num" scope="col"> 'Native necc build (ms)'
						<th className="num" scope="col"> 'Distro-built (ms)'
						<th scope="col"> 'Fastest external (ms)'
						<th className="num" scope="col"> 'nelinker bytes'
						<th className="num" scope="col"> 'Smallest external bytes'
				<tbody>
					for row in timings
						<tr>
							<th scope="row"> row[0]
							<td className="num"> row[1]
							<td className="num"> row[2]
							<td> row[3]
							<td className="num"> row[4]
							<td className="num"> row[5]

		<p className="upstream-links">
			<a href="/nelua/assets/core-shootout.zip"> 'All linker medians, quartiles and individual samples (ZIP)'
			<a href="/nelua/assets/linker-20261121/method.txt"> 'Original input set and checks'
			<a href="/nelua/assets/linker-20261121/replay.tar.gz"> 'Replay the link inputs'
		<h3 id="link-memory"> "Link time and peak resident memory"
		<p> "On 22 November 2026 a native necc build of nelinker a349c2a linked a real SDK member and a complete Lua interpreter. Time and maximum resident set size came from separate invocations with identical inputs."
		<div className="table-wrap">
			<table>
				<thead>
					<tr>
						<th scope="col"> "Input"
						<th scope="col"> "Reference"
						<th scope="col"> "nelinker (ms)"
						<th scope="col"> "Reference (ms)"
						<th scope="col"> "nelinker (KiB)"
						<th scope="col"> "Reference (KiB)"
				<tbody>
					for row in nelinkerPassRows
						<tr>
							<th scope="row"> row[0]
							<td className="num"> row[1]
							<td className="num"> row[2]
							<td className="num"> row[3]
							<td className="num"> row[4]
							<td className="num"> row[5]
		<p> "The syscall executable returned 42 after calling getpid. The linked Lua interpreter evaluated a command and printed 42. The table reports warm medians on logical CPU 5 of an Intel Core i7-11700F across 19 SDK pairs and 15 interpreter pairs."
		<details id="link-samples">
			<summary> 'Individual link times, peak memory and file sizes'
			<p> 'SDK archive member'
			<pre> readFileSync('src/content/linker-current.csv', 'utf8').trimEnd()
			<p> 'Whole interpreter'
			<pre> readFileSync('src/content/linker-vm-current.csv', 'utf8').trimEnd()
		<p className="upstream-links">
			<a href="/nelua/assets/ecosystem-20261121/replay.tar.gz"> 'Replay scripts'
		<h3> 'Creating an archive'
		<p>
			'On '
			<time html:datetime="2026-11-22"> '22 November 2026'
			', creating a deterministic archive from 256 x86-64 objects with short filenames took 3.251 ms with native build a349c2a. The earlier TinyCC-built 0c27372 took 3.908 ms. GNU ar took 18.991 ms. The current writer stores ordinary filenames directly in the member header and preserves short filenames containing spaces. The output size fell from 215,484 to 213,376 bytes, matching the GNU archive size.'
		<p> 'Archive creation used 31 interleaved warm runs on one Intel Core i5-10400 core. GNU ar listed the members, nm read their index, and both nelinker and GNU ld linked a program that returned 42.'
		<details>
			<summary> '22 November archive creation and lookup samples'
			<pre> readFileSync('src/content/build-archive.csv', 'utf8').trimEnd()
		<p className="upstream-links">
			<a href="/nelua/assets/build-tools-20261121/archive.csv"> '21 November archive samples (CSV)'
			<a href="/nelua/assets/build-tools-20261121/method.txt"> 'Archive writer method'
		<p className="upstream-links">
			<a href="/nelua/assets/toolchain-20261119/archives.csv"> '19 November archive link results (CSV)'
			<a href="/nelua/assets/toolchain-20261119/toolchain.csv"> '19 November object and compiler results (CSV)'
