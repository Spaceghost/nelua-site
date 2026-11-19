'use strict';
(() => {
  const root = document.querySelector('#account-controls');
  const status = document.querySelector('#account-status');
  const e = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  let account;
  async function api(path, body) {
    const response = await fetch('api/' + path, body === undefined ? {cache:'no-store'} : {
      method: 'POST', headers: {'Content-Type':'application/json','X-CSRF-Token':account?.csrf || ''}, body: JSON.stringify(body),
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || 'request_failed');
    return data;
  }
  const messages = {
    sign_in_required: 'Sign in again to manage your projects.',
    installation_owner_mismatch: 'Connect repositories owned by your signed-in GitHub account.',
    connect_private_repositories: 'Connect your GitHub repositories first.',
    github_access_unavailable: 'GitHub access changed or is temporarily unavailable. Reconnect your repositories.',
    repository_not_owned_or_not_selected: 'Select private repositories you own and have granted access to.',
    select_private_repositories: 'Select at least one private repository.',
  };
  function failure(error) { status.textContent = messages[error.message] || 'This request could not be completed. Try again.'; }
  async function refresh() {
    account = await api('me');
    if (!account.signedIn) {
      root.innerHTML = '<a class="account-button" href="api/auth/start">Sign in with GitHub</a>';
      document.querySelector('#nav-sign-in').textContent = 'Sign in with GitHub';
      return;
    }
    const nav = document.querySelector('#nav-sign-in');
    nav.textContent = '@' + account.profile.login; nav.href = '#private-projects';
    root.innerHTML = `<p class="account-identity">Signed in as <strong>@${e(account.profile.login)}</strong></p>
      ${!account.privateAvailable ? `<p>Private repository access needs the community GitHub App.${account.owner ? ' Create it once to enable this for everyone.' : ' The site owner is setting it up.'}</p>${account.owner ? '<a class="account-button" href="api/app/setup">Enable private repository access</a>' : ''}` :
        `<a class="account-button" href="api/installation/start">${account.connected ? 'Manage GitHub access' : 'Connect selected repositories'}</a>
        <p class="account-help">Choose “Only select repositories” on GitHub. Access is read-only. Only private, non-fork repositories owned by your account can count.</p>
        ${account.connected ? '<form id="private-form"><fieldset><legend>Choose private projects to count</legend><div id="private-repositories">Loading your selected repositories…</div></fieldset><label class="consent-choice"><input id="publish-private" type="checkbox"> Publish my authored private Nelua totals in the ranking.</label><p class="account-help">Only current code attributed to commits linked to your GitHub account counts. Names, source and per-file identifiers are never published. Saved choices are counted in the next daily refresh. Turning this off removes your private totals immediately.</p><button class="account-button" type="submit">Save private project choices</button></form>' : ''}`}
      <div class="account-actions">${account.enabled ? '<button type="button" class="account-secondary" data-account="disable">Remove my private totals</button>' : ''}<button type="button" class="account-secondary" data-account="logout">Sign out</button><button type="button" class="account-secondary" data-account="disconnect">Disconnect and delete my community account</button></div>`;
    if (account.enabled) status.textContent = account.countedAt ? `Private totals last counted ${new Date(account.countedAt).toLocaleString()}.` : 'Your choices are saved for the next daily refresh at 7:17 a.m. Pacific.';
    if (account.connected && account.privateAvailable) {
      const data = await api('repositories');
      document.querySelector('#private-repositories').innerHTML = data.repositories.length ? data.repositories.map(repo => `<label class="repository-choice"><input type="checkbox" name="repository" value="${repo.id}" ${account.selected.includes(repo.id) ? 'checked' : ''}><span>${e(repo.name)}</span></label>`).join('') : '<p>No private repositories are selected in GitHub. Use “Manage GitHub access” to choose them.</p>';
      document.querySelector('#publish-private').checked = account.enabled;
      document.querySelector('#private-form').addEventListener('submit', async event => {
        event.preventDefault(); const button = event.target.querySelector('button'); button.disabled = true;
        try {
          await api('settings', {enabled:document.querySelector('#publish-private').checked, repositories:[...root.querySelectorAll('input[name="repository"]:checked')].map(input => Number(input.value))});
          status.textContent = 'Choices saved. Enabled totals refresh daily at 7:17 a.m. Pacific.';
          await refresh(); window.dispatchEvent(new Event('private-metrics-changed'));
        } catch (error) { failure(error); } finally { button.disabled = false; }
      });
    }
  }
  root.addEventListener('click', async event => {
    const button = event.target.closest('[data-account]'); if (!button) return;
    button.disabled = true;
    try {
      const action = button.dataset.account;
      if (action === 'disable') await api('settings', {enabled:false});
      else await api(action, {});
      status.textContent = action === 'disconnect' ? 'Your community account and private totals have been deleted.' : action === 'disable' ? 'Your private totals have been removed.' : 'Signed out. Your saved counting preferences are unchanged.';
      await refresh(); window.dispatchEvent(new Event('private-metrics-changed'));
    } catch (error) { failure(error); button.disabled = false; }
  });
  refresh().catch(() => { status.textContent = 'Account access is temporarily unavailable. The public index remains available.'; });
})();
