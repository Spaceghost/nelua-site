'use strict';

const format = new Intl.NumberFormat('en-US');
const $ = selector => document.querySelector(selector);
const state = { people: [], publicPeople: [], type: 'all', query: '', sort: 'lines', limit: 25, expanded: new Set() };
const escape = value => String(value ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
const number = value => Number.isFinite(Number(value)) ? Number(value) : 0;
const github = value => { try { const url = new URL(value); return url.protocol === 'https:' && url.hostname === 'github.com' ? url.href : 'https://github.com'; } catch { return 'https://github.com'; } };
const avatar = value => { try { const url = new URL(value,location.href); return url.origin === location.origin && /\/avatars\/[a-z0-9-]+\.(png|jpg|webp)$/.test(url.pathname) ? url.href : ''; } catch { return ''; } };
const isTeam = person => person.ownerType?.toLowerCase() === 'organization';
const projectCount = person => person.repositories.length + number(person.privateTotals?.repositories);
const narrow = window.matchMedia('(max-width:700px)');
const columns = () => narrow.matches ? 4 : 5;

function filtered() {
  return state.people.filter(person => {
    if (state.type === 'people' && isTeam(person)) return false;
    if (state.type === 'teams' && !isTeam(person)) return false;
    const haystack = [person.login, person.name, ...person.repositories.map(repo => repo.name)].join(' ').toLowerCase();
    return haystack.includes(state.query);
  }).sort((a,b) => {
    const score = state.sort === 'repositories' ? projectCount(b) - projectCount(a) : number(b[state.sort]) - number(a[state.sort]);
    return score || number(b.lines) - number(a.lines) || a.login.localeCompare(b.login);
  });
}

function details(person) {
  const repos = [...person.repositories].sort((a,b) => number(b.lines) - number(a.lines));
  return `<tr class="repo-detail"><td colspan="${columns()}"><div class="repo-list">${repos.map(repo => {
    const commit = /^[a-f0-9]{40}$/.test(repo.sha ?? '') ? `${github(repo.url)}/tree/${repo.sha}` : github(repo.url);
    return `<div class="repo-line"><a href="${escape(commit)}" target="_blank" rel="noopener noreferrer">${escape(repo.name)} <span aria-hidden="true">↗</span></a><span class="repo-count">${format.format(number(repo.lines))} lines · ${format.format(number(repo.files))} files</span></div>`;
  }).join('')}${person.privateTotals ? `<div class="private-summary">${format.format(person.privateTotals.repositories)} private projects · ${format.format(person.privateTotals.lines)} lines · counted ${escape(new Date(person.privateTotals.generatedAt).toLocaleDateString())}. Names and source stay private.</div>` : ''}</div><p class="repo-meta"><a href="${escape(github(person.url))}" target="_blank" rel="noopener noreferrer">Visit @${escape(person.login)} on GitHub ↗</a> · Public source links point to measured commits.</p></td></tr>`;
}

function render() {
  const people = filtered();
  const maximum = Math.max(1,...people.map(person => number(person.lines)));
  const shown = people.slice(0,state.limit);
  $('#builders').innerHTML = shown.length ? shown.map((person,index) => {
    const open = state.expanded.has(person.login);
    const image = avatar(person.localAvatarUrl);
    return `<tr class="builder-row ${index === 0 ? 'is-first' : ''}"><td class="rank ${index < 3 ? 'top-rank' : ''}">${String(index + 1).padStart(2,'0')}</td><td><div class="builder"><span class="avatar" aria-hidden="true">${escape(person.login[0]?.toUpperCase())}${image ? `<img src="${escape(image)}" alt="" loading="lazy" referrerpolicy="no-referrer">` : ''}</span><button class="builder-toggle" data-login="${escape(person.login)}" aria-expanded="${open}"><span class="builder-name">${escape(person.name || person.login)}${isTeam(person) ? '<span class="team-badge">TEAM</span>' : ''}${person.privateTotals ? '<span class="private-badge">+ PRIVATE</span>' : ''}</span><span class="builder-handle">@${escape(person.login)}</span></button></div></td><td class="number"><span class="line-score">${format.format(number(person.lines))}</span><progress class="score-track" max="${maximum}" value="${number(person.lines)}" aria-hidden="true"></progress></td><td class="number secondary-col file-count">${format.format(number(person.files))}</td><td class="number"><button class="project-button" data-login="${escape(person.login)}" aria-expanded="${open}" aria-label="${open ? 'Hide' : 'Show'} ${escape(person.login)}'s ${projectCount(person)} projects">${projectCount(person)}<span aria-hidden="true">${open ? '−' : '+'}</span></button></td></tr>${open ? details(person) : ''}`;
  }).join('') : `<tr><td colspan="${columns()}" class="empty">No builders match that search. Try a different name or project.</td></tr>`;
  $('#result-count').textContent = `Showing ${shown.length} of ${people.length} builders`;
  $('#show-more').hidden = shown.length >= people.length;
  document.querySelectorAll('.avatar img').forEach(image => image.addEventListener('error',() => image.remove(),{once:true}));
}

$('#builders').addEventListener('click',event => {
  const button = event.target.closest('button[data-login]');
  if (!button) return;
  const login = button.dataset.login;
  state.expanded.has(login) ? state.expanded.delete(login) : state.expanded.add(login);
  render();
  const buttons = [...document.querySelectorAll('button[data-login]')];
  buttons.find(item => item.dataset.login === login && item.className === button.className)?.focus({preventScroll:true});
});
document.querySelectorAll('.filter').forEach(button => button.addEventListener('click',() => {
  state.type = button.dataset.type;
  state.limit = 25;
  document.querySelectorAll('.filter').forEach(item => { const active = item === button; item.classList.toggle('active',active); item.setAttribute('aria-pressed',String(active)); });
  render();
}));
$('#search').addEventListener('input',event => { state.query = event.target.value.trim().toLowerCase(); state.limit = 25; render(); });
$('#sort').addEventListener('change',event => { state.sort = event.target.value; render(); });
$('#show-more').addEventListener('click',() => { state.limit += 25; render(); });
narrow.addEventListener('change',() => { if (state.people.length) render(); });
document.addEventListener('keydown',event => {
  if (event.key === '/' && !['INPUT','TEXTAREA','SELECT'].includes(document.activeElement.tagName)) { event.preventDefault(); $('#search').focus(); }
});

async function load() {
  try {
    const response = await fetch('data.json');
    if (!response.ok) throw new Error(`Snapshot HTTP ${response.status}`);
    const data = await response.json();
    if (!Array.isArray(data.people)) throw new Error('Snapshot does not contain a builder index');
    state.publicPeople = data.people.filter(person => person.login && number(person.lines) > 0 && Array.isArray(person.repositories));
    state.people = state.publicPeople;
    $('#stat-people').textContent = format.format(state.people.length);
    $('#stat-lines').textContent = format.format(state.people.reduce((sum,person) => sum + number(person.lines),0));
    $('#stat-repos').textContent = format.format(state.people.reduce((sum,person) => sum + person.repositories.length,0));
    const date = new Date(data.generatedAt);
    const dateLabel = Number.isNaN(date.valueOf()) ? 'Dated source snapshot' : date.toLocaleDateString('en-GB',{day:'numeric',month:'short',year:'numeric',timeZone:'UTC'});
    $('#snapshot-label').textContent = `CURRENT SOURCE · ${dateLabel.toUpperCase()}`;
    const coverage = data.coverage ?? {};
    $('#coverage-note').textContent = `${format.format(number(coverage.scannedRepositories))} public repositories scanned · ${format.format(number(coverage.qualifyingRepositories))} with counted original source · ${format.format(number(coverage.failedRepositories))} unavailable. This snapshot covers the indexed candidate set; it is not an exhaustive census of GitHub.`;
    render();
    document.documentElement.dataset.loaded = 'true';
    await refreshPrivate();
  } catch (error) {
    $('#builders').innerHTML = '<tr><td colspan="5" class="empty">The source snapshot could not be loaded. Reload the page to try again.</td></tr>';
    $('#snapshot-label').textContent = 'SNAPSHOT UNAVAILABLE';
    $('#result-count').textContent = 'The index is temporarily unavailable';
    console.error('Could not load community index:',error.message);
  }
}
async function refreshPrivate() {
  if (!state.publicPeople.length) return;
  const people = state.publicPeople.map(person => ({...person}));
  let privateOwners = 0;
  try {
    const response = await fetch('api/private-totals', {cache:'no-store'});
    if (!response.ok) throw new Error('private totals unavailable');
    const data = await response.json();
    for (const totals of data.people || []) {
      if (!/^[a-z0-9-]+$/i.test(totals.login) || number(totals.lines) <= 0) continue;
      let person = people.find(item => item.login.toLowerCase() === totals.login.toLowerCase());
      if (!person) {
        person = {login:totals.login,name:totals.name || totals.login,ownerType:'User',url:'https://github.com/' + totals.login,localAvatarUrl:'',lines:0,bytes:0,files:0,repositories:[]};
        people.push(person);
      }
      person.privateTotals = totals;
      for (const field of ['lines','bytes','files']) person[field] = number(person[field]) + number(totals[field]);
      privateOwners++;
    }
    document.querySelector('#private-count-note').textContent = privateOwners ? `Includes opted-in private totals from ${privateOwners} builders. Private projects are shown as aggregate counts; the downloadable audit covers public source.` : 'Private projects appear after their owners opt in and the daily scan completes. The downloadable audit covers public source.';
  } catch {
    document.querySelector('#private-count-note').textContent = 'Private totals are temporarily unavailable. Showing the public source index.';
  }
  state.people = people;
  document.querySelector('#stat-people').textContent = format.format(people.length);
  document.querySelector('#stat-lines').textContent = format.format(people.reduce((sum,person) => sum + number(person.lines),0));
  render();
}
window.addEventListener('private-metrics-changed', refreshPrivate);
load();
