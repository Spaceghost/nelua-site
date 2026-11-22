const format = new Intl.NumberFormat('en-US')
const query = do(selector) document.querySelector(selector)
const state = {people: [], publicPeople: [], type: 'all', query: '', sort: 'lines', limit: 25, expanded: new Set()}
const escape = do(value)
	String(value ?? '').replace(/[&<>"']/g, do(char)
		({'&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'})[char]
	)
const number = do(value) Number.isFinite(Number(value)) ? Number(value) : 0
const isTeam = do(person) (person.ownerType || '').toLowerCase() == 'organization'
const projectCount = do(person) person.repositories.length + number(person.privateTotals && person.privateTotals.repositories)
const narrow = window.matchMedia('(max-width:700px)')
const columns = do narrow.matches ? 4 : 5

def github value
	try
		const url = new URL(value)
		return url.protocol == 'https:' && url.hostname == 'github.com' ? url.href : 'https://github.com'
	catch
		return 'https://github.com'

def avatar value
	try
		const url = new URL(value, location.href)
		return url.origin == location.origin && /\/avatars\/[a-z0-9-]+\.(png|jpg|webp)$/.test(url.pathname) ? url.href : ''
	catch
		return ''

def filtered
	state.people.filter(do(person)
		return false if state.type == 'people' && isTeam(person)
		return false if state.type == 'teams' && !isTeam(person)
		const haystack = [person.login, person.name, ...person.repositories.map(do(repo) repo.name)].join(' ').toLowerCase()
		return haystack.includes(state.query)
	).sort(do(a, b)
		const score = state.sort == 'repositories' ? projectCount(b) - projectCount(a) : number(b[state.sort]) - number(a[state.sort])
		score || number(b.lines) - number(a.lines) || a.login.localeCompare(b.login)
	)

def details person
	const repos = person.repositories.slice().sort(do(a,b) number(b.lines) - number(a.lines))
	const rows = repos.map(do(repo)
		const commit = /^[a-f0-9]{40}$/.test(repo.sha ?? '') ? "{github(repo.url)}/tree/{repo.sha}" : github(repo.url)
		"<div class=\"repo-line\"><a href=\"{escape(commit)}\" target=\"_blank\" rel=\"noopener noreferrer\">{escape(repo.name)}</a><span class=\"repo-count\">{format.format(number(repo.lines))} lines · {format.format(number(repo.files))} files</span></div>"
	).join('')
	const totals = person.privateTotals
	const summary = totals ? "<div class=\"private-summary\">{format.format(totals.repositories)} private projects · {format.format(totals.lines)} lines · counted {escape(new Date(totals.generatedAt).toLocaleDateString())}. Names and source stay private.</div>" : ''
	"<tr class=\"repo-detail\"><td colspan=\"{columns()}\"><div class=\"repo-list\">{rows}{summary}</div><p class=\"repo-meta\"><a href=\"{escape(github(person.url))}\" target=\"_blank\" rel=\"noopener noreferrer\">Visit @{escape(person.login)} on GitHub</a> · Public source links point to measured commits.</p></td></tr>"

def lineScore person, maximum
	const privateLines = number(person.privateTotals && person.privateTotals.lines)
	const publicLines = number(person.lines) - privateLines
	const publicWidth = 100 * publicLines / maximum
	const privateWidth = 100 * privateLines / maximum
	const label = "{format.format(publicLines)} public lines, {format.format(privateLines)} private lines"
	"<span class='line-count' aria-hidden='true'>{format.format(publicLines)} <span class='private-count'>(+{format.format(privateLines)})</span></span>" +
		"<svg class='score-track' role='img' aria-label='{label}'><title>{label}</title>" +
		"<rect class='score-public' width='{publicWidth}%' height='100%'></rect>" +
		"<rect class='score-private' x='{publicWidth}%' width='{privateWidth}%' height='100%'></rect></svg>"

def builderRow person, index, maximum
	const open = state.expanded.has(person.login)
	const image = avatar(person.localAvatarUrl)
	const picture = image ? "<img src=\"{escape(image)}\" alt=\"\" loading=\"lazy\" referrerpolicy=\"no-referrer\">" : ''
	const team = isTeam(person) ? '<span class="team-badge">Team</span>' : ''
	const privateBadge = person.privateTotals ? '<span class="private-badge">+ Private</span>' : ''
	const action = open ? 'Hide' : 'Show'
	const sign = open ? '−' : '+'
	const login = escape(person.login)
	const count = projectCount(person)
	"<tr class=\"builder-row\"><td class=\"rank\">{index + 1}</td>" +
		"<td><div class=\"builder\"><span class=\"avatar\" aria-hidden=\"true\">{escape(person.login.charAt(0).toUpperCase())}{picture}</span>" +
		"<button class=\"builder-toggle\" data-login=\"{login}\" aria-expanded=\"{open}\"><span class=\"builder-name\">{escape(person.name || person.login)}{team}{privateBadge}</span><span class=\"builder-handle\">@{login}</span></button></div></td>" +
		"<td class=\"number\">{lineScore(person, maximum)}</td>" +
		"<td class=\"number secondary-col\">{format.format(number(person.files))}</td>" +
		"<td class=\"number\"><button class=\"project-button\" data-login=\"{login}\" aria-expanded=\"{open}\" aria-label=\"{action} {login}'s {count} projects\">{count}<span aria-hidden=\"true\">{sign}</span></button></td></tr>" +
		(open ? details(person) : '')

def render
	const people = filtered()
	const maximum = people.reduce((do(highest, person) Math.max(highest, number(person.lines))), 1)
	const shown = people.slice(0, state.limit)
	query('#builders').innerHTML = shown.length ? shown.map(do(person, index) builderRow(person, index, maximum)).join('') : "<tr><td colspan=\"{columns()}\" class=\"empty\">No builders match that search. Try a different name or project.</td></tr>"
	query('#result-count').textContent = "Showing {shown.length} of {people.length} builders"
	query('#show-more').hidden = shown.length >= people.length
	for image in document.querySelectorAll('.avatar img')
		image.addEventListener('error', (do(event) event.currentTarget.remove()), {once: true})

query('#builders').addEventListener('click', do(event)
	const button = event.target.closest('button[data-login]')
	return unless button
	const login = button.dataset.login
	if state.expanded.has(login)
		state.expanded.delete(login)
	else
		state.expanded.add(login)
	render()
	const buttons = Array.from(document.querySelectorAll('button[data-login]'))
	const replacement = buttons.find(do(item) item.dataset.login == login && item.className == button.className)
	replacement.focus({preventScroll: true}) if replacement
)

for button in document.querySelectorAll('.filter')
	button.addEventListener('click', do
		state.type = button.dataset.type
		state.limit = 25
		for item in document.querySelectorAll('.filter')
			const active = item == button
			item.classList.toggle('active', active)
			item.setAttribute('aria-pressed', String(active))
		render()
	)

query('#search').addEventListener('input', do(event)
	state.query = event.target.value.trim().toLowerCase()
	state.limit = 25
	render()
)
query('#sort').addEventListener('change', do(event)
	state.sort = event.target.value
	render()
)
query('#show-more').addEventListener('click', do
	state.limit += 25
	render()
)
narrow.addEventListener('change', do
	render() if state.people.length
)
document.addEventListener('keydown', do(event)
	if event.key == '/' && !['INPUT','TEXTAREA','SELECT'].includes(document.activeElement.tagName)
		event.preventDefault()
		query('#search').focus()
)

def setTotals people
	query('#stat-people').textContent = format.format(people.length)
	query('#stat-lines').textContent = format.format(people.reduce((do(sum, person) sum + number(person.lines)), 0))

def refreshPrivate
	return unless state.publicPeople.length
	const people = state.publicPeople.map(do(person) Object.assign({}, person))
	let privateOwners = 0
	try
		const response = await fetch('api/private-totals', {cache: 'no-store'})
		throw new Error('private totals unavailable') unless response.ok
		const data = await response.json()
		for totals in (data.people || [])
			continue if !/^[a-z0-9-]+$/i.test(totals.login) || number(totals.lines) <= 0
			let person = people.find(do(item) item.login.toLowerCase() == totals.login.toLowerCase())
			if !person
				person = {login: totals.login, name: totals.name || totals.login, ownerType: 'User', url: 'https://github.com/' + totals.login, localAvatarUrl: '', lines: 0, bytes: 0, files: 0, repositories: []}
				people.push(person)
			person.privateTotals = totals
			for field in ['lines', 'bytes', 'files']
				person[field] = number(person[field]) + number(totals[field])
			privateOwners += 1
		query('#private-count-note').textContent = privateOwners ? "Includes authored private code from {privateOwners} builders. Private projects are shown as aggregate counts; the downloadable audit covers public source." : 'Private projects appear after their owners opt in and the daily scan completes. Only code attributed to their commits counts. The downloadable audit covers public source.'
	catch
		query('#private-count-note').textContent = 'Private totals are temporarily unavailable. Showing the public source index.'
	state.people = people
	setTotals(people)
	render()

def load
	try
		const response = await fetch('data.json')
		throw new Error("Snapshot HTTP {response.status}") unless response.ok
		const data = await response.json()
		throw new Error('Snapshot does not contain a builder index') unless Array.isArray(data.people)
		state.publicPeople = data.people.filter(do(person) person.login && number(person.lines) > 0 && Array.isArray(person.repositories))
		state.people = state.publicPeople
		setTotals(state.people)
		query('#stat-repos').textContent = format.format(state.people.reduce((do(sum, person) sum + person.repositories.length), 0))
		const date = new Date(data.generatedAt)
		const dateLabel = Number.isNaN(date.valueOf()) ? 'Dated source snapshot' : date.toLocaleDateString('en-GB', {day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC'})
		query('#snapshot-label').textContent = "Current source · {dateLabel}"
		const coverage = data.coverage ?? {}
		query('#coverage-note').textContent = "{format.format(number(coverage.scannedRepositories))} public repositories scanned · {format.format(number(coverage.qualifyingRepositories))} with counted original source · {format.format(number(coverage.failedRepositories))} unavailable. This snapshot covers the indexed candidate set; it is not an exhaustive census of GitHub."
		render()
		document.documentElement.dataset.loaded = 'true'
		await refreshPrivate()
	catch error
		query('#builders').innerHTML = '<tr><td colspan="5" class="empty">The source snapshot could not be loaded. Reload the page to try again.</td></tr>'
		query('#snapshot-label').textContent = 'Snapshot unavailable'
		query('#result-count').textContent = 'The index is temporarily unavailable'
		console.error('Could not load community index:', error.message)

window.addEventListener('private-metrics-changed', refreshPrivate)
load()
