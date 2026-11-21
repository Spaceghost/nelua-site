export const title = 'nelinker · Static x86-64 linker · Nelua at spacegho.st'
export const description = 'Link x86-64 ELF objects and static archives with nelinker. Try a freestanding Linux executable and compare measured link times.'

const timings = [
	['One member from a 256-member archive', '0.348', '0.392', '0.410', 'TinyCC']
	['256 archive members in reverse dependency order', '0.941', '1.881', '4.718', 'GNU gold']
	['257 explicit object files', '2.242', '2.911', '5.948', 'TinyCC']
]

export def body
	<div className="page-content">
		<section className="hero">
			<p className="eyebrow"> 'Core · the linker'
			<h1> 'nelinker'
			<p className="tagline"> 'A static ELF linker written in Nelua for x86-64 Linux.'
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
		<p> 'nelinker produces fixed-address static executables from x86-64 ELF objects. It reads regular GNU/SysV and BSD archives, resolves strong and weak symbols, and supports static GOT entries and local-exec TLS. PIE, shared libraries, thin archives, LTO and custom linker scripts are outside the current scope.'
		<p>
			'For C or Nelua programs using '
			<a href="/nelua/nelibc/"> 'nelibc'
			', let '
			<a href="/nelua/necc/#linker"> 'necc invoke nelinker'
			'. The driver supplies the SDK libraries and their relocation conventions.'
		<h2 className="section" id="benchmarks"> 'Link times'
		<p>
			'In the '
			<time html:datetime="2026-11-19"> '19 November 2026'
			' x86-64 Linux shootout, both builds had the lowest median link time in all 11 timed cases. nelinker produced the smallest executable in five. Each output had to pass its execution check.'
		<p> 'The two columns show how the linker itself was built. One used GCC 12.2 at -O3. The distro build used necc and the staged TinyCC. Times are median milliseconds across 31 warm rounds for archives and 23 for explicit objects.'
		<div className="table-wrap" role="region" aria-label="Median link time in milliseconds" html:tabindex="0">
			<table>
				<thead>
					<tr>
						<th scope="col"> 'Workload'
						<th className="num" scope="col"> 'GCC-built (ms)'
						<th className="num" scope="col"> 'Distro-built (ms)'
						<th scope="col"> 'Fastest external (ms)'
				<tbody>
					for row in timings
						<tr>
							<th scope="row"> row[0]
							<td className="num"> row[1]
							<td className="num"> row[2]
							<td> "{row[3]} · {row[4]}"
		<p className="upstream-links">
			<a href="/nelua/assets/toolchain-20261119/archives.csv"> 'Archive results (CSV)'
			<a href="/nelua/assets/toolchain-20261119/toolchain.csv"> 'Object and compiler results (CSV)'
