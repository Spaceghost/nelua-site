export const title = 'nelinker · Static x86-64 linker · Nelua at spacegho.st'
export const description = 'Link x86-64 ELF objects and static archives into a Linux executable or a relocatable PE32+ UEFI application.'

const timings = [
	['Three loose objects', '1.449', '1.454', 'TinyCC · 1.526', '205', '727']
	['257 loose objects', '3.123', '3.682', 'TinyCC · 5.900', '2,491', '3,015']
	['32,768 relocations', '1.850', '2.422', 'GNU gold · 3.454', '270,336', '263,031']
	['8,192 distinct symbols', '2.254', '4.530', 'TinyCC · 4.866', '106,496', '99,191']
	['SDK syscall, loose objects', '1.445', '1.468', 'TinyCC · 1.553', '4,378', '1,088']
	['SDK syscall, archive-suite control', '1.494', '1.479', 'TinyCC · 1.611', '4,378', '1,088']
	['One member from the SDK archive', '1.564', '1.626', 'TinyCC · 1.812', '4,378', '1,088']
	['One member from 256', '1.501', '1.544', 'TinyCC · 1.557', '196', '719']
	['256 members, reverse dependency order', '1.986', '2.738', 'Wild · 3.909', '2,491', '3,015']
	['All 256 archive members', '1.898', '2.371', 'Wild · 3.823', '1,726', '2,247']
	['Whole SDK with allocator', '3.009', '4.527', 'TinyCC · 5.795', '995,860', '992,583']
]

const nelinkerPassRows = [
	["SDK getpid member", "ld.bfd", "0.74", "3.39", "1,804", "4,944"]
	["Bundled Lua and whole SDK", "TinyCC", "10.71", "16.31", "5,532", "5,528"]
]

export def body
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"> 'Core · the linker'
			<h1> 'nelinker'
			<p className="tagline"> 'A static linker written in Nelua for x86-64 Linux executables and UEFI applications.'
			<p className="blurb"> 'Give it object files and Unix archives. It resolves symbols, applies relocations and writes an executable. The same linker performs the final link of both itself and the necc compiler driver.'
			<p><a href="https://github.com/Spaceghost/nelinker"> 'nelinker source on GitHub'
			<div className="actions">
				<a className="button" href="#archive"> 'Link an archive'
				<a className="text-link" href="#benchmarks"> 'Compare link times'
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
		<p> 'In Linux mode, nelinker produces fixed-address static executables from x86-64 ELF objects. It reads regular GNU/SysV and BSD archives, resolves strong and weak symbols, and supports static GOT entries and local-exec TLS. PIE, shared libraries, thin archives, LTO and custom linker scripts are outside the current scope.'
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
			<time html:datetime="2026-11-21"> '21 November 2026'
			', both nelinker builds had a lower median than the fastest qualifying external linker in all 11 workloads on one Intel Core i7-11700F core. Both produced the smallest executable in five. For the single member from a 256-member archive, the distro build and TinyCC were within 0.013 ms of each other.'
		<p> 'The first five rows use loose objects and 23 warm rounds. The remaining six use the archive harness and 31 rounds. Its explicit-syscall control also uses loose objects. Every timed link had to produce a program that returned 42. The external field consisted of GNU BFD, GNU gold, TinyCC, LLD 14, LLD 22 through Zig, mold and Wild.'
		<div className="table-wrap" role="region" aria-label="Median elapsed link time and executable size" html:tabindex="0">
			<table>
				<thead>
					<tr>
						<th scope="col"> 'Workload'
						<th className="num" scope="col"> 'GCC-built (ms)'
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
		<p> 'The GCC build used GCC 12.2 at -O3. The distro build used necc and its staged TinyCC. The inputs and seven external binaries matched the earlier run by SHA-256. For the whole-SDK allocator, TinyCC was the only external linker whose program passed the execution check.'
		<p className="upstream-links">
			<a href="/nelua/assets/linker-20261121/summary.csv"> 'Full field and quartiles (CSV)'
			<a href="/nelua/assets/linker-20261121/samples.csv"> 'Individual link times (CSV)'
			<a href="/nelua/assets/linker-20261121/method.txt"> 'Method, builds and checks'
			<a href="/nelua/assets/linker-20261121/replay.tar.gz"> 'Replay the link inputs'
		<h3 id="link-memory"> "Link time and peak resident memory"
		<p> "On 21 November 2026 nelinker a349c2a linked a real SDK member and a complete Lua interpreter. Time and maximum resident set size came from separate invocations with identical inputs."
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
		<p> "The syscall executable returned 42 after calling getpid. The linked Lua interpreter evaluated a command and printed 42. The table reports warm medians on one i7-9700K logical CPU."
		<p className="upstream-links">
			<a href="/nelua/assets/ecosystem-20261121/link.csv"> "SDK link samples"
			<a href="/nelua/assets/ecosystem-20261121/link-vm.csv"> "Interpreter link samples"
			<a href="/nelua/assets/ecosystem-20261121/summary.csv"> "Quartiles and observed ranges"
			<a href="/nelua/assets/ecosystem-20261121/replay.tar.gz"> "Replay scripts"
			<a href="/nelua/assets/ecosystem-20261121/reproduce.txt"> "Versions and reproduction"
		<h3> 'Creating an archive'
		<p>
			'On '
			<time html:datetime="2026-11-21"> '21 November 2026'
			', creating a deterministic archive from 256 x86-64 objects with short filenames took 3.343 ms, down from 4.231 ms. GNU ar took 22.216 ms. The new writer stores ordinary filenames directly in the member header and preserves short filenames containing spaces. The archive shrank from 215,484 to 213,376 bytes, matching the GNU archive size.'
		<p> 'Archive creation used 31 interleaved warm runs on one Intel Core i5-10400 core. GNU ar listed the members, nm read their index, and both nelinker and GNU ld linked a program that returned 42.'
		<p className="upstream-links">
			<a href="/nelua/assets/build-tools-20261121/archive.csv"> 'Archive creation samples (CSV)'
			<a href="/nelua/assets/build-tools-20261121/method.txt"> 'Archive writer method'
		<p className="upstream-links">
			<a href="/nelua/assets/toolchain-20261119/archives.csv"> '19 November archive link results (CSV)'
			<a href="/nelua/assets/toolchain-20261119/toolchain.csv"> '19 November object and compiler results (CSV)'
