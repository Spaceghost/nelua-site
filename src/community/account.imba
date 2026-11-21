const root = document.querySelector('#account-controls')
const status = document.querySelector('#account-status')
const signIn = document.querySelector('#nav-sign-in')
const escape = do(value)
	String(value ?? '').replace(/[&<>"']/g, do(char)
		({'&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;'})[char]
	)
let account

def api path, body
	const request = {cache: 'no-store'}
	if body !== undefined
		request.method = 'POST'
		request.headers = {'Content-Type': 'application/json', 'X-CSRF-Token': (account && account.csrf) || ''}
		request.body = JSON.stringify(body)
	const response = await fetch('api/' + path, request)
	const data = await response.json()
	throw new Error(data.error || 'request_failed') unless response.ok
	return data

const messages = {
	sign_in_required: 'Sign in again to manage your projects.'
	installation_owner_mismatch: 'Connect repositories owned by your signed-in GitHub account.'
	connect_private_repositories: 'Connect your GitHub repositories first.'
	github_access_unavailable: 'GitHub access changed or is temporarily unavailable. Reconnect your repositories.'
	repository_not_owned_or_not_selected: 'Select private repositories you own and have granted access to.'
	select_private_repositories: 'Select at least one private repository.'
}

def failure error
	status.textContent = messages[error.message] || 'This request could not be completed. Try again.'

def options
	if !account.privateAvailable
		const description = account.owner ? 'Create it once to enable this for everyone.' : 'The site owner is setting it up.'
		const setup = account.owner ? '<a class="account-button" href="api/app/setup">Enable private repository access</a>' : ''
		return "<p>Private repository access needs the community GitHub App. {description}</p>{setup}"
	const label = account.connected ? 'Manage GitHub access' : 'Connect selected repositories'
	return "<a class=\"account-button\" href=\"api/installation/start\">{label}</a>" +
		'<p class="account-help">Choose “Only select repositories” on GitHub. Access is read-only. Only private, non-fork repositories owned by your account can count.</p>' +
		(account.connected ? '<form id="private-form"><fieldset><legend>Choose private projects to count</legend><div id="private-repositories">Loading your selected repositories…</div></fieldset><label class="consent-choice"><input id="publish-private" type="checkbox"> Publish my authored private Nelua totals in the ranking.</label><p class="account-help">Only current code attributed to commits linked to your GitHub account counts. Names, source and per-file identifiers are never published. Saved choices are counted in the next daily refresh. Turning this off removes your private totals immediately.</p><button class="account-button" type="submit">Save private project choices</button></form>' : '')

def save event
	event.preventDefault()
	const button = event.target.querySelector('button')
	button.disabled = true
	try
		const enabled = document.querySelector('#publish-private').checked
		const repositories = Array.from(root.querySelectorAll('input[name="repository"]:checked'), do(input) Number(input.value))
		await api('settings', {enabled, repositories})
		status.textContent = 'Choices saved. Enabled totals refresh daily at 7:17 a.m. Pacific.'
		await refresh()
		window.dispatchEvent(new Event('private-metrics-changed'))
	catch error
		failure(error)
	finally
		button.disabled = false

def refresh
	account = await api('me')
	if !account.signedIn
		root.innerHTML = '<a class="account-button" href="api/auth/start">Sign in with GitHub</a>'
		signIn.textContent = 'Sign in with GitHub'
		signIn.href = 'api/auth/start'
		return
	signIn.textContent = '@' + account.profile.login
	signIn.href = '#private-projects'
	const reset = account.enabled ? '<button type="button" class="account-secondary" data-account="disable">Remove my private totals</button>' : ''
	root.innerHTML = "<p class=\"account-identity\">Signed in as <strong>@{escape(account.profile.login)}</strong></p>" +
		options() + '<div class="account-actions">' + reset +
		'<button type="button" class="account-secondary" data-account="logout">Sign out</button><button type="button" class="account-secondary" data-account="disconnect">Disconnect and delete my community account</button></div>'
	if account.enabled
		status.textContent = account.countedAt ? "Private totals last counted {new Date(account.countedAt).toLocaleString()}." : 'Your choices are saved for the next daily refresh at 7:17 a.m. Pacific.'
	if account.connected && account.privateAvailable
		const data = await api('repositories')
		const list = document.querySelector('#private-repositories')
		list.innerHTML = data.repositories.length ? data.repositories.map(do(repo)
			const checked = account.selected.includes(repo.id) ? 'checked' : ''
			"<label class=\"repository-choice\"><input type=\"checkbox\" name=\"repository\" value=\"{escape(repo.id)}\" {checked}><span>{escape(repo.name)}</span></label>"
		).join('') : '<p>No private repositories are selected in GitHub. Use “Manage GitHub access” to choose them.</p>'
		document.querySelector('#publish-private').checked = account.enabled
		document.querySelector('#private-form').addEventListener('submit', save)

root.addEventListener('click', do(event)
	const button = event.target.closest('[data-account]')
	return unless button
	button.disabled = true
	try
		const action = button.dataset.account
		if action == 'disable'
			await api('settings', {enabled: false})
		else
			await api(action, {})
		status.textContent = action == 'disconnect' ? 'Your community account and private totals have been deleted.' : action == 'disable' ? 'Your private totals have been removed.' : 'Signed out. Your saved counting preferences are unchanged.'
		await refresh()
		window.dispatchEvent(new Event('private-metrics-changed'))
	catch error
		failure(error)
		button.disabled = false
)

if location.hostname == 'nelua.tech'
	status.innerHTML = '<a href="https://spacegho.st/nelua/community/#private-projects">Manage your community account on spacegho.st</a>'
else
	refresh().catch(do
		status.textContent = 'Account access is temporarily unavailable. The public index remains available.'
	)
