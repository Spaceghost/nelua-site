# Coverage explorer for spacegho.st/nelua/nelibc/. Loads the generated JSON
# once and filters it in the page. Built to public/nelua/assets/explorer.js.

const STATUSES = ['implemented', 'host-delegated', 'not-declared']
const LABELS = {'implemented': 'Implemented', 'host-delegated': 'Host-delegated', 'not-declared': 'Not declared'}
const PAGE = 120

tag coverage-explorer
	prop rows = []
	prop query = ''
	prop header = ''
	prop status = ''
	prop limit = PAGE
	prop headers = []
	prop loaded = no
	prop failed = no

	def mount
		try
			const res = await window.fetch('/nelua/assets/nelibc-coverage.json')
			const data = await res.json!
			rows = data.rows
			const seen = {}
			for row in rows
				for h in row[1].split(';')
					seen[h] = (seen[h] or 0) + 1 if h
			headers = Object.keys(seen).sort!
			loaded = yes
		catch e
			failed = yes
		render!

	get filtered
		const q = query.trim!.toLowerCase!
		rows.filter do(r)
			return no if status and r[2] != status
			return no if header and !r[1].split(';').includes(header)
			return no if q and !r[0].toLowerCase!.includes(q)
			yes

	def toggle s
		status = status == s ? '' : s
		limit = PAGE

	def exportsOf r
		return '' unless r[3]
		r[3].split(';').join(' ')

	<self>
		if failed
			<p.muted> "The coverage data could not be loaded. The same table is "
				<a href="https://github.com/Spaceghost/nelibc/blob/main/docs/musl-1.2.5-api-coverage.csv"> "on GitHub"
				"."
		elif !loaded
			<p.muted.count> "Loading 1,471 symbols…"
		else
			const list = filtered
			<div.controls>
				<input type="search" placeholder="Filter by symbol, e.g. strtol" aria-label="Filter by symbol" bind=query @input=(limit = PAGE)>
				<select aria-label="Header" bind=header @change=(limit = PAGE)>
					<option value=""> "Every header"
					for h in headers
						<option value=h> h
				<div.chips role="group" aria-label="Status">
					for s in STATUSES
						<button.chip type="button" aria-pressed=(status == s) @click=toggle(s)> LABELS[s]
			<p.count> "{list.length} of {rows.length} symbols"
			<div.table-wrap>
				<table>
					<thead>
						<tr>
							<th> "Symbol"
							<th> "musl header"
							<th> "Status"
							<th> "Exported by profiles"
					<tbody>
						for r in list.slice(0, limit)
							<tr>
								<td> <code> r[0]
								<td> r[1].split(';').join(' ')
								<td> <span class=("st-" + r[2])> LABELS[r[2]]
								<td.small.muted> exportsOf(r)
			if list.length > limit
				<p.more>
					<button.chip type="button" @click=(limit += 400)> "Show {Math.min(400, list.length - limit)} more"

const host = document.getElementById('explorer')
imba.mount(<coverage-explorer>, host) if host
