import 'imba'

global css :root
	color-scheme: light
	--ink: #142b4c
	--muted: #536780
	--blue: #2457b5
	--navy: #143d83
	--paper: #f7f9fc
	--line: #d9e3ef
	--wash: #eaf3ff
	--green: #167b5b

global css body
	margin: 0
	background: var(--paper)
	color: var(--ink)
	font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif
	font-size: 16px
	line-height: 1.55

global css *
	box-sizing: border-box

global css *:before
	box-sizing: border-box

global css *:after
	box-sizing: border-box

global css a
	color: inherit
	text-decoration: none

global css button
	font: inherit

global css input
	font: inherit

global css ::selection
	background: #cce0ff
	color: var(--navy)

global css .shell
	width: min(1160px, calc(100% - 48px))
	margin-inline: auto

global css .topbar
	min-height: 74px
	display: flex
	align-items: center
	justify-content: space-between
	gap: 20px
	border-bottom: 1px solid var(--line)

global css .brand
	display: flex
	align-items: center
	gap: 11px
	font-weight: 750
	letter-spacing: -.03em

global css .brand-mark
	width: 36px
	height: 36px
	display: grid
	place-items: center
	border-radius: 50%
	background: var(--blue)
	color: white
	box-shadow: 0 0 0 5px #e8f0ff

global css .nav
	display: flex
	align-items: center
	gap: 24px
	font-size: 14px
	color: var(--muted)

global css .nav a:hover
	color: var(--blue)

global css .text-link:hover
	color: var(--blue)

global css .nav-cta
	padding: 8px 13px
	border: 1px solid #c8d6e7
	border-radius: 8px
	color: var(--navy)
	font-weight: 650

global css .eyebrow
	color: var(--blue)
	font: 700 11px ui-monospace, SFMono-Regular, Menlo, monospace
	letter-spacing: .11em
	text-transform: uppercase

global css .hero
	display: grid
	grid-template-columns: repeat(auto-fit, minmax(min(100%, 390px), 1fr))
	gap: 48px
	align-items: center
	padding-block: clamp(54px, 8vw, 92px)

global css h1
	font-size: clamp(44px, 6vw, 74px)
	line-height: 1
	letter-spacing: -.065em
	margin: 16px 0 20px

global css h1 em
	color: var(--blue)
	font-style: normal

global css .lede
	max-width: 650px
	margin: 0
	color: var(--muted)
	font-size: clamp(16px, 2vw, 19px)
	line-height: 1.65

global css .actions
	display: flex
	flex-wrap: wrap
	gap: 11px
	margin-top: 26px

global css .button
	display: inline-flex
	align-items: center
	gap: 9px
	padding: 11px 16px
	border-radius: 8px
	font-size: 14px
	font-weight: 700
	transition: transform .18s

global css .button:hover
	transform: translateY(-2px)

global css .primary
	background: var(--blue)
	color: white
	box-shadow: 0 8px 18px #2457b52c

global css .secondary
	background: white
	border: 1px solid #cbd8e8
	color: var(--navy)

global css .demo
	background: #111d34
	border-radius: 14px
	padding: 22px
	color: #eaf2ff
	box-shadow: 0 22px 55px #24446d24
	overflow: auto

global css .demo-head
	display: flex
	justify-content: space-between
	gap: 12px
	border-bottom: 1px solid #ffffff20
	padding-bottom: 14px
	margin-bottom: 14px
	color: #a8bddc
	font: 11px ui-monospace, SFMono-Regular, Menlo, monospace

global css .demo pre, .code
	font: 12px/1.85 ui-monospace, SFMono-Regular, Menlo, monospace
	white-space: pre-wrap
	color: #dce9ff

global css .code-purple
	color: #b9a5ff

global css .code-blue
	color: #86c2ff

global css .code-green
	color: #7bd8b4

global css .flow
	display: grid
	grid-template-columns: repeat(auto-fit, minmax(110px, 1fr))
	gap: 8px
	margin-top: 18px

global css .flow span
	border: 1px solid #ffffff24
	background: #ffffff0a
	border-radius: 7px
	padding: 9px
	text-align: center
	color: #dce9ff
	font-size: 11px

global css .stats
	background: var(--wash)
	border-block: 1px solid #d9e7f6

global css .stats-inner
	display: grid
	grid-template-columns: repeat(auto-fit, minmax(170px, 1fr))

global css .stat
	padding: 21px
	border-right: 1px solid #d0dfef

global css .stat strong
	display: block
	color: var(--navy)
	font: 750 27px ui-monospace, SFMono-Regular, Menlo, monospace
	letter-spacing: -.06em

global css .stat span
	color: var(--muted)
	font-size: 12px

global css .section
	padding-block: clamp(52px, 7vw, 82px)

global css .section-head
	display: flex
	justify-content: space-between
	align-items: end
	gap: 28px
	margin-bottom: 26px

global css h2
	font-size: clamp(29px, 4vw, 43px)
	line-height: 1.08
	letter-spacing: -.05em
	margin: 8px 0 0

global css .intro
	max-width: 470px
	margin: 0
	color: var(--muted)
	font-size: 14px

global css .feature-grid, .project-grid, .two-col
	display: grid
	grid-template-columns: repeat(auto-fit, minmax(min(100%, 260px), 1fr))
	gap: 16px

global css .card
	background: white
	border: 1px solid var(--line)
	border-radius: 11px
	padding: 23px

global css .card h3
	font-size: 20px
	letter-spacing: -.035em
	margin: 10px 0 7px

global css .card p
	margin: 0
	color: var(--muted)
	font-size: 13px

global css .featured
	background: var(--wash)
	border-color: #c9dcf3

global css .project
	display: flex
	flex-direction: column
	min-height: 230px
	transition: transform .18s, border-color .18s

global css .project:hover
	transform: translateY(-3px)
	border-color: #91b4e5

global css .kicker
	color: var(--blue)
	font: 700 10px ui-monospace, SFMono-Regular, Menlo, monospace
	letter-spacing: .1em
	text-transform: uppercase

global css .card-foot
	display: flex
	justify-content: space-between
	gap: 12px
	margin-top: auto
	padding-top: 20px
	color: var(--blue)
	font-size: 12px
	font-weight: 700

global css .method
	display: grid
	grid-template-columns: repeat(auto-fit, minmax(min(100%, 300px), 1fr))
	gap: 38px
	border-top: 1px solid var(--line)
	padding-top: 28px

global css .method p, .lab p
	color: var(--muted)
	font-size: 14px

global css .step
	display: grid
	grid-template-columns: 42px 1fr
	gap: 12px
	padding: 15px 0
	border-bottom: 1px solid var(--line)

global css .step b
	display: block
	font-size: 14px

global css .step span
	color: var(--muted)
	font-size: 13px

global css .lab
	background: var(--wash)
	border-block: 1px solid #d9e7f6

global css .bench
	display: grid
	grid-template-columns: 1fr 1fr 1fr
	gap: 10px
	padding: 12px 0
	border-bottom: 1px solid #cad9eb
	font: 12px ui-monospace, SFMono-Regular, Menlo, monospace
	color: var(--muted)

global css .bench strong
	color: var(--ink)

global css .bench b
	color: var(--green)

global css .link
	color: var(--blue)
	font-size: 12px
	font-weight: 700

global css .quick
	display: grid
	grid-template-columns: repeat(auto-fit, minmax(min(100%, 330px), 1fr))
	gap: 35px

global css .command
	display: flex
	justify-content: space-between
	align-items: center
	gap: 10px
	margin-top: 9px
	background: #111d34
	color: #dce9ff
	border-radius: 8px
	padding: 12px
	font: 11px ui-monospace, SFMono-Regular, Menlo, monospace

global css .command button, .filter
	background: white
	border: 1px solid #cbd8e8
	border-radius: 6px
	color: var(--navy)
	padding: 7px 9px
	cursor: pointer
	font-size: 11px

global css .command button
	background: #ffffff12
	border-color: #ffffff2a
	color: #dce9ff

global css .note
	border-left: 2px solid #82a8df
	padding-left: 14px
	margin: 14px 0
	color: var(--muted)
	font-size: 13px

global css .subhero
	padding-block: 54px 34px

global css .crumb
	color: #70819a
	font: 11px ui-monospace, SFMono-Regular, Menlo, monospace
	letter-spacing: .09em
	margin-bottom: 25px

global css .fact
	display: inline-block
	margin: 8px 7px 0 0
	padding: 5px 9px
	background: var(--wash)
	border: 1px solid #d6e4f4
	border-radius: 999px
	color: var(--muted)
	font: 10px ui-monospace, SFMono-Regular, Menlo, monospace

global css .toolbar
	display: flex
	align-items: end
	justify-content: space-between
	gap: 14px
	margin-bottom: 14px

global css .filters
	display: flex
	flex-wrap: wrap
	gap: 6px
	margin-top: 12px

global css .filter[aria-pressed="true"]
	background: var(--wash)
	border-color: #91b4e5

global css .search
	width: min(300px, 100%)
	background: white
	border: 1px solid #cbd8e8
	border-radius: 8px
	padding: 10px 12px
	outline: none
	color: var(--ink)

global css .search:focus
	border-color: var(--blue)
	box-shadow: 0 0 0 3px #2457b51c

global css .table-wrap
	max-height: 480px
	overflow: auto
	border: 1px solid var(--line)
	border-radius: 9px
	background: white

global css table
	width: 100%
	border-collapse: collapse
	text-align: left
	font: 11px ui-monospace, SFMono-Regular, Menlo, monospace

global css th
	position: sticky
	top: 0
	background: #edf3fa
	color: var(--muted)
	padding: 11px
	font-size: 10px
	text-transform: uppercase

global css td
	padding: 9px 11px
	border-top: 1px solid #e7edf4
	color: var(--muted)

global css td:first-child
	color: var(--ink)

global css .status
	color: var(--green)

global css .status.host-delegated
	color: var(--blue)

global css .status.not-declared
	color: #8997aa

global css .muted
	color: #8997aa

global css .priority-list
	border-top: 1px solid var(--line)

global css .priority
	display: grid
	grid-template-columns: 42px 1fr auto
	gap: 12px
	align-items: center
	padding: 13px 0
	border-bottom: 1px solid var(--line)

global css .priority p
	margin: 3px 0 0
	color: var(--muted)
	font-size: 12px

global css .toast
	position: fixed
	bottom: 20px
	left: 50%
	transform: translateX(-50%)
	background: var(--navy)
	color: white
	border-radius: 7px
	padding: 8px 12px
	font-size: 12px

global css .cta
	display: flex
	align-items: center
	justify-content: space-between
	gap: 20px
	padding-block: 30px 65px
	border-top: 1px solid var(--line)

global css .cta h2
	margin-top: 0
	font-size: 27px

global css .footer
	display: flex
	justify-content: space-between
	gap: 15px
	padding-block: 20px 28px
	border-top: 1px solid var(--line)
	color: #70819a
	font-size: 11px

global css .footer a
	color: var(--blue)

global css @media (max-width: 680px)
	.topbar
		min-height: 64px
	.nav
		gap: 12px
		font-size: 12px
	.section-head
		align-items: flex-start
		flex-direction: column

	.toolbar
		align-items: flex-start
		flex-direction: column

	.cta
		align-items: flex-start
		flex-direction: column
	.stats-inner
		grid-template-columns: 1fr 1fr
	.stat
		padding: 14px 9px
	.nav .optional
		display: none

const statusLabels = {'implemented': 'Nelibc export', 'host-delegated': 'Host delegated', 'not-declared': 'Not declared'}

tag site
	page = location.pathname.includes('/nelibc') ? 'nelibc' : 'home'
	root = location.pathname.startsWith('/langs/nelua') ? '/langs/nelua/' : '/'
	query = ''
	status = 'all'
	rows = []
	toast = ''
	def visibleRows
		const needle = query.trim().toLowerCase()
		const matches = []
		for row in rows
			if (status == 'all' or row.status == status) and (not needle or row.api.toLowerCase().includes(needle) or row.exports.toLowerCase().includes(needle))
				matches.push(row)
		return matches.slice(0,120)
	def mount
		if page == 'nelibc'
			loadCoverage()
	def loadCoverage
		const result = fetch(root + 'assets/api-coverage.json').then do(response)
			response.json!
		result.then do(data)
			rows = data
	def copy(text)
		const result = navigator.clipboard.writeText(text)
		result.then do
			toast = 'Copied to clipboard'
	<self>
		<header.shell.topbar>
			<a.brand href={root}>
				<span.brand-mark> N
				<span>Nelua <span.muted>/ projects</span>
			<nav.nav aria-label="Main navigation">
				<a.optional href={root + '#projects'}> Projects
				<a href={root + 'nelibc/'}> Nelibc
				<a.nav-cta href="https://github.com/Spaceghost/nelibc"> GitHub ↗
		if page == 'home'
			<main>
				<section.shell.hero>
					<div>
						<div.eyebrow> Nelua in working systems
						<h1>
							"One language."
							<br>
							<em> Closer to the machine.
						<p.lede> Typed, expressive systems code that stays close to its C ABI. From a libc you can replace one symbol at a time to firmware and native browser bridges.
						<div.actions>
							<a.button.primary href={root + 'nelibc/'}> Explore Nelibc ↗
							<a.button.secondary href="#projects"> See projects ↓
					<div.demo>
						<div.demo-head>
							<span>● ship of theseus / build profile</span>
							<span>linux · x86-64</span>
						<pre>
							<span.code-purple> local function
								" memcmp(a, b, n)"
							<br>
							<span.code-blue> for
								" i = 0, n - 1 do"
							<br>
								"    if a[i] ~= b[i] then"
							<br>
								<span.code-green> return
									" a[i] - b[i]"
							<br>
								"    end"
							<br>
							"  end"
							<br>
							<span.code-green> return
								" 0"
						<br>
							<span.code-blue> end
						<div.flow>
							<span>Nelibc · selected symbols
							<span>glibc / musl · rest
							<span>C program · same caller
			<section.stats>
				<div.shell.stats-inner>
					<div.stat><strong>813</strong><span>Tracked musl symbols exported</span>
					<div.stat><strong>2</strong><span>Hybrid libc families</span>
					<div.stat><strong>3</strong><span>Nelua projects featured</span>
					<div.stat><strong>1 → N</strong><span>Replace one symbol at a time</span>
			<section.shell.section>
				<div.section-head>
					<div><div.eyebrow>Why Nelua here</div><h2>Stay close to the work.</h2>
					<p.intro>Readable source, explicit data shapes, and visible native boundaries. Each project puts Nelua where its low-level strengths are useful.
				<div.feature-grid>
					<article.card><div.eyebrow>01 / Replace</div><h3>Replace without a rewrite.</h3><p>Link a hybrid archive into an ordinary C program. Nelibc takes over selected symbols while glibc or musl supplies the rest.
					<article.card><div.eyebrow>02 / Inspect</div><h3>See every boundary.</h3><p>Nelua compiles through C. Keep the ABI, generated code, compiler choice, and target machine in view.
			<section#projects.shell.section>
				<div.section-head>
					<div><div.eyebrow>Built with Nelua</div><h2>Projects with real source.</h2>
					<p.intro>A libc, typed embedded protocol logic, and a native bridge between device data and a browser.
				<div.project-grid>
					<a.card.project.featured href={root + 'nelibc/'}>
						<div.kicker>01 / libc · featured</div><h3>Nelibc</h3><p>Replace libc functions in stages. Hybrid profiles target glibc and musl; a Linux x86-64 standalone runtime grows alongside them.
						<div.card-foot><span>API map · quickstart · benchmarks</span><span>↗</span>
					<a.card.project href="https://github.com/Spaceghost/atlas-firmware">
						<div.kicker>02 / Firmware</div><h3>Atlas Firmware</h3><p>Typed Service V1 codecs and schedule-record logic live in Nelua, generate C, and enter the release path with ABI checks.
						<div.card-foot><span>Protocol · embedded</span><span>↗</span>
					<a.card.project href="https://github.com/Spaceghost/atlas-webware/tree/master/bridge">
						<div.kicker>03 / Browser bridge</div><h3>Atlas Webware</h3><p>A bounded ATB1 frame validator connects strict native input to browser-facing field control.
						<div.card-foot><span>Codec · native seam</span><span>↗</span>
			<section.shell.section>
				<div.section-head><div><div.eyebrow>Ship of Theseus</div><h2>Replace pieces. Keep the program.</h2>
					<p.intro>Hybrid builds are useful before the library is complete. Standalone is the longer climb to owning the entire runtime.
				<div.method>
					<div><h3>How the replacement grows</h3><p>Nelibc exports take precedence at link time. Uncovered names continue to resolve from the selected host libc.</p><a.link href={root + 'nelibc/'}>Explore the API inventory →
					<div>
						<div.step><b>01</b><div><b>Choose a function</b><span>Check that the archive exports it and the consumer calls it.</span></div>
						<div.step><b>02</b><div><b>Link beside glibc or musl</b><span>Keep the rest of the host ABI intact.</span></div>
						<div.step><b>03</b><div><b>Dogfood and measure</b><span>Use differential checks, real consumers, and paired shootouts.</span></div>
			<section.lab>
				<div.shell.section>
					<div.section-head><div><div.eyebrow>Performance lab · early evidence</div><h2>Measure the function.<br>Then the workload.</h2>
						<p.intro>The <a href="https://bell-sw.com/blog/alpaquita-linux-performance-the-race-is-on/">Alpaquita study</a> is a useful model. Nelibc's current data isolates `memcmp`; it is not a distribution-level benchmark.</p>
					<div.two-col>
						<div><div.bench><strong>equal · 36 B</strong><span>glibc <b>1.10×</b></span><span>musl <b>0.15×</b></span>
							<div.bench><strong>equal · 132 B</strong><span>glibc <b>1.95×</b></span><span>musl <b>0.12×</b></span>
							<div.bench><strong>equal · 4,100 B</strong><span>glibc <b>0.92×</b></span><span>musl <b>0.03×</b></span>
							<p.intro>Below 1.00× means faster. Seven alternating process pairs; CPU pinned. One-machine microbenchmark, not an application claim.</p>
						<div.card><h3>Read the results in context</h3><p>Near glibc at 36 bytes, still slower at 132 bytes, faster than this musl build in these cases. The next target is closing the medium-size gap without losing the short-input win.</p><a.link href="https://github.com/Spaceghost/nelibc/blob/main/benchmarks/results/2026-10-26-memcmp-size-shootout-paired.csv">Inspect paired measurements ↗</a>
			<section.shell.cta><div><h2>Start with one function.</h2><p class="intro">Build Nelibc, link the C dogfood consumer, and choose the next symbol.</p></div><a.button.primary href={root + 'nelibc/'}>Read the quickstart ↗
		else
			<main>
				<section.shell.subhero>
					<div.crumb><a href={root}>NELUA</a> / NELIBC</div>
					<div.eyebrow>A C library, rebuilt piece by piece</div>
					<h1>Replace libc,<br><em>one symbol at a time.</em></h1>
					<p.lede>Link Nelibc into an existing C program. Nelua implementations take over selected functions; glibc or musl supplies the rest. Grow the replacement without rewriting the application.</p>
					<div.actions><a.button.primary href="https://github.com/Spaceghost/nelibc">View source on GitHub ↗</a><a.button.secondary href="#quickstart">Build it locally ↓
					<div><span.fact>Linux x86-64</span><span.fact>Zig cc default</span><span.fact>glibc + musl hybrid builds</span><span.fact>Standalone in progress</span>
				<section.shell.section><div.two-col>
					<article.card><div.eyebrow>Hybrid · use it now</div><h3>Replace selected symbols.</h3><p>Exported Nelibc functions take precedence; uncovered names stay with the selected host libc.</p>
					<article.card><div.eyebrow>Standalone · build toward it</div><h3>Grow a separate runtime.</h3><p>Own startup, syscalls, allocation, threads, process, locale, and I/O in stages. This Linux x86-64 profile has working slices and known gaps.</p>
			<section.stats><div.shell.stats-inner>
					<div.stat><strong>813</strong><span>Exported in at least one hybrid profile</span>
					<div.stat><strong>223</strong><span>Delegated to host libc</span>
					<div.stat><strong>435</strong><span>Not declared in the tracker</span>
					<div.stat><strong>1,471</strong><span>Musl 1.2.5 symbols tracked</span>
				<section#inventory.shell.section>
					<div.section-head><div><div.eyebrow>Explore the inventory</div><h2>Search the symbol surface.</h2>
						<p.intro>Filter the pinned musl 1.2.5 list by name, implementation status, or exported profile. Symbol presence is not a behavioral conformance claim.</p>
					<div.toolbar><div><div.eyebrow>1,471 tracked function symbols</div><div.filters>
						<button.filter aria-pressed={status == 'all'} @click={status = 'all'}> All
						<button.filter aria-pressed={status == 'implemented'} @click={status = 'implemented'}> Nelibc exports
						<button.filter aria-pressed={status == 'host-delegated'} @click={status = 'host-delegated'}> Host delegated
						<button.filter aria-pressed={status == 'not-declared'} @click={status = 'not-declared'}> Not declared
						</div></div><input.search type="search" placeholder="Search e.g. memcmp" aria-label="Search symbols" bind=query>
					<div.table-wrap><table><thead><tr><th>Function</th><th>Status</th><th>Export profiles</th></tr></thead><tbody>
						if rows.length == 0
							<tr><td colspan="3">Loading symbol inventory…</td>
						else if visibleRows().length == 0
							<tr><td colspan="3">No matching symbols.</td>
						else
							for row in visibleRows()
								<tr><td>{row.api}</td><td><span class="status {row.status}">{statusLabels[row.status] or row.status}</span></td><td>{row.exports ? row.exports.split(';').join(' · ') : '—'}</td>
					<p class="intro">Showing {visibleRows().length} matches, up to 120 at a time. <a class="link" href="https://github.com/Spaceghost/nelibc/blob/main/docs/api-coverage.md">Coverage methodology ↗</a></p>
				<section#performance.shell.section><div.section-head><div><div.eyebrow>Performance lab · early evidence</div><h2>Measure function paths.</h2>
					<p.intro><a href="https://bell-sw.com/blog/alpaquita-linux-performance-the-race-is-on/">Alpaquita's comparison</a> shows why libc performance needs varied inputs and complete workloads. This Nelibc shootout isolates `memcmp`.</p>
					<div.two-col><div><div.bench><strong>Equal · 36 B</strong><span>glibc <b>1.10×</b></span><span>musl <b>0.15×</b></span>
						<div.bench><strong>Equal · 132 B</strong><span>glibc <b>1.95×</b></span><span>musl <b>0.12×</b></span>
						<div.bench><strong>Equal · 4,100 B</strong><span>glibc <b>0.92×</b></span><span>musl <b>0.03×</b></span>
						<p class="intro">Below 1.00× means faster. Paired local microbenchmark, pinned CPU; not an end-to-end claim.</p>
						<a.link href="https://github.com/Spaceghost/nelibc/blob/main/benchmarks/results/2026-10-26-memcmp-size-shootout-paired.csv">Open paired measurements ↗</a>
						<div.card><h3>Next target</h3><p>Close the 132-byte glibc gap while preserving the short-input improvement. Then move from isolated functions to workload-level tests.</p>
				<section#quickstart.shell.section><div.section-head><div><div.eyebrow>Try the hybrid build</div><h2>Start in two commands.</h2><p.intro>Install Nelua and Zig first. The dogfood target builds Nelibc, links a C consumer, runs it, and checks that Nelibc symbols reached the executable.</p>
					<div.quick><div><div.command><code>git clone https://github.com/Spaceghost/nelibc.git</code><button @click={copy('git clone https://github.com/Spaceghost/nelibc.git')}>Copy
						<div.command><code>cd nelibc &amp;&amp; make dogfood-zig</code><button @click={copy('cd nelibc && make dogfood-zig')}>Copy
						<p><a class="link" href="https://github.com/Spaceghost/nelibc/blob/main/docs/quickstart.md">Full quickstart ↗</a></p>
						</div><div><div.note><b>The C caller stays ordinary.</b><br>Use `-fno-builtin` when checking a call so the compiler leaves it visible.</div><div.note><b>The host libc stays useful.</b><br>Uncovered APIs resolve from glibc or musl in hybrid builds.</div><div.note><b>Standalone stays honest.</b><br>It is a separate Linux profile with open compatibility gaps.</div></div>
				<section.shell.section><div.section-head><div><div.eyebrow>What remains · ranked</div><h2>Core work, in order.</h2><p.intro>Reliable behavior and real consumers matter more than a raw exported-name count.</p>
					<div.priority-list>
						<div.priority><b class="link">P0</b><div><b>Consumer reliability</b><p>Keep ABI, differential, and build gates green across profiles.</p></div><span class="muted">every release</span>
						<div.priority><b class="link">P1</b><div><b>Threads and process behavior</b><p>Broaden standalone POSIX behavior and audit signal/fork interactions.</p></div><span class="muted">core runtime</span>
						<div.priority><b class="link">P1</b><div><b>Math quality and fenv</b><p>Expand long-double edge coverage and improve performance where measured.</p></div><span class="muted">numerics</span>
						<div.priority><b class="link">P2</b><div><b>API and locale audit</b><p>Classify undeclared APIs by impact; expand Unicode and locale data.</p></div><span class="muted">breadth</span>
				<section.shell.cta><div><h2>Read the code. Pick a symbol.</h2><p class="intro">Source, quickstart, API inventory, benchmark data, and standalone roadmap live in the repository.</p></div><a.button.primary href="https://github.com/Spaceghost/nelibc">Open Spaceghost/nelibc ↗
		<footer.shell.footer><span><a href={root}>← All Nelua projects</a></span><span>musl 1.2.5 · <a href="https://nelua.io/">Nelua language ↗</a> · <a href="https://github.com/pbakaus/impeccable">Impeccable design ↗</a>
		if toast
			<div.toast role="status" aria-live="polite">{toast}


imba.mount <site>
