# Coverage explorer for spacegho.st/nelua/nelibc/. Loads the generated JSON
# once and filters its shared symbol rows in the page.

const PAGE = 120
const STATUS_LABELS = {
	'nelibc': 'Nelibc',
	'runtime-only': 'Runtime only',
	'missing': 'Missing'
}

tag coverage-explorer
	prop rows = []
	prop inventories = []
	prop profiles = []
	prop query = ''
	prop header = ''
	prop status = ''
	prop inventoryId = ''
	prop profileId = ''
	prop members = {}
	prop generated = ''
	prop sourceCommit = ''
	prop comparisonHref = ''
	prop limit = PAGE
	prop headers = []
	prop loaded = no
	prop failed = no

	def mount
		try
			const res = await window.fetch('/nelua/assets/nelibc-coverage-profiles.json')
			if !res.ok
				throw new Error('coverage data unavailable')
			const data = await res.json!
			rows = data.rows
			inventories = data.inventories
			profiles = data.profiles
			for item in profiles
				members[item.id] = {owned: new Set(item.owned), runtime: new Set(item.runtime)}
			generated = data.generated
			sourceCommit = data.source_commit
			comparisonHref = data.comparison

			const headerInventory = inventories.find do(item)
				item.id == 'musl-1.2.5'
			const defaultInventory = headerInventory or inventories[0]
			inventoryId = defaultInventory.id if defaultInventory

			const muslProfile = profiles.find do(item)
				item.id == 'musl'
			const defaultProfile = muslProfile or profiles[0]
			profileId = defaultProfile.id if defaultProfile
			refreshHeaders!
			loaded = yes
		catch e
			failed = yes
		render!

	get selectedInventory
		inventories.find do(item)
			item.id == inventoryId

	get selectedProfile
		profiles.find do(item)
			item.id == profileId

	get hasHeaderFilter
		const item = selectedInventory
		return no unless item
		item.id == 'musl-1.2.5'

	def refreshHeaders
		const found = {}
		const inventory = selectedInventory
		if inventory
			for i in inventory.indices
				for h in (rows[i][1] or '').split(';')
					found[h] = yes if h
		headers = Object.keys(found).sort!

	get owned
		members[profileId].owned

	get runtime
		members[profileId].runtime

	def resetInventoryFilters
		header = ''
		limit = PAGE

	def resetLimit
		limit = PAGE

	def category index
		return 'nelibc' if owned.has(index)
		return 'runtime-only' if runtime.has(index)
		'missing'

	get counts
		const result = {'nelibc': 0, 'runtime-only': 0, 'missing': 0}
		const inventory = selectedInventory
		if inventory
			for i in inventory.indices
				result[category(i)] += 1
		result

	get filtered
		const q = query.trim!.toLowerCase!
		const inventory = selectedInventory
		return [] unless inventory
		inventory.indices.filter do(i)
			const row = rows[i]
			const rowStatus = category(i)
			return no if status and rowStatus != status
			return no if header and !(row[1] or '').split(';').includes(header)
			return no if q and !row[0].toLowerCase!.includes(q)
			yes

	<self role="region" aria-label="Nelibc coverage explorer" aria-busy=(!loaded and !failed)>
		if failed
			<p className="muted" role="alert">
				"The coverage data could not be loaded. You can still download the "
				<a html:href="/nelua/assets/nelibc-coverage-profiles.json"> "profile coverage data"
				" or view the "
				<a html:href="/nelua/assets/nelibc-coverage.json"> "historical coverage snapshot"
				"."
		elif !loaded
			<p className="muted count" role="status" aria-live="polite"> "Loading coverage inventories and profiles…"
		else
			const inventory = selectedInventory
			const profile = selectedProfile
			const totals = counts
			const list = filtered
			<div className="explorer-meta">
				<p className="muted">
					"Generated "
					<time html:datetime=generated> generated
					" · revision "
					<code title=sourceCommit> sourceCommit.slice(0, 8)
					" · "
					<a html:href=(comparisonHref)> "matched comparison data"
			<div className="controls">
				<label className="field">
					<span> "Symbol inventory"
					<select aria-label="Symbol inventory" bind=inventoryId @change=resetInventoryFilters>
						for item in inventories
							<option value=item.id> item.label
				<label className="field">
					<span> "Runtime profile"
					<select aria-label="Runtime profile" bind=profileId @change=resetLimit>
						for item in profiles
							<option value=item.id> item.label
				<label className="field search-field">
					<span> "Filter by symbol"
					<input type="search" placeholder="e.g. strtol" aria-label="Filter by symbol" bind=query @input=resetLimit>
				<label className="field">
					<span> "Filter by musl header"
					<select aria-label="Filter by musl header" bind=header disabled=(!hasHeaderFilter) @change=resetLimit>
						<option value=""> (hasHeaderFilter ? 'Every header' : 'Musl headers only')
						for h in headers
							<option value=h> h
				<label className="field">
					<span> "Filter by coverage"
					<select aria-label="Filter by coverage" bind=status @change=resetLimit>
						<option value=""> "Every status"
						<option value="nelibc"> "Nelibc"
						<option value="runtime-only"> "Runtime only"
						<option value="missing"> "Missing"
			<p className="inventory-description"> inventory.description
			<dl className="explorer-summary" aria-label="Coverage counts for selected inventory and runtime">
				<div>
					<dt> "Nelibc"
					<dd> totals['nelibc']
				<div>
					<dt> "Runtime only"
					<dd> totals['runtime-only']
				<div>
					<dt> "Missing"
					<dd> totals['missing']
			<p className="count" role="status" aria-live="polite">
				"Showing {Math.min(list.length, limit)} of {list.length} matching symbols."
			<div className="table-wrap">
				<table>
					<caption> "Symbol ownership in the selected inventory and runtime profile"
					<thead>
						<tr>
							<th scope="col"> "Symbol"
							<th scope="col"> "musl header"
							<th scope="col"> "Coverage"
					<tbody>
						for i in list.slice(0, limit)
							const row = rows[i]
							const rowStatus = category(i)
							<tr>
								<td> <code> row[0]
								<td> (row[1] or '').split(';').join(' ') or '—'
								<td>
									<span className=('st-' + rowStatus)> STATUS_LABELS[rowStatus]
									if owned.has(i) and runtime.has(i)
										<span className="also-runtime"> "Also in runtime"
			if list.length > limit
				<p className="more">
					<button className="chip" type="button" @click=(limit += PAGE)>
						"Show {Math.min(PAGE, list.length - limit)} more"
const host = document.getElementById('explorer')
imba.mount(<coverage-explorer>, host) if host
