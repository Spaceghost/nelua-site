const filters = document.getElementById('coverage-filters');
const query = document.getElementById('coverage-query');
const statusSelect = document.getElementById('coverage-status');
const upstream = document.getElementById('coverage-upstream');
const results = document.getElementById('coverage-results');
const rows = Array.from(document.querySelectorAll('.coverage-page tbody tr'), element => ({
  element,
  name: element.querySelector('code').textContent.toLowerCase(),
}));

function update() {
  const term = query.value.trim().toLowerCase();
  let count = 0;
  for (const { element, name } of rows) {
    const matches = name.includes(term)
      && (!statusSelect.value || statusSelect.value === element.dataset.status)
      && (!upstream.value || upstream.value === element.dataset.upstream);
    element.hidden = !matches;
    if (matches) count++;
  }
  if (count === rows.length) results.textContent = count + ' commands';
  else if (count === 0) results.textContent = 'No commands match these filters.';
  else results.textContent = count + ' of ' + rows.length + ' commands';
}

query.addEventListener('input', update);
statusSelect.addEventListener('change', update);
upstream.addEventListener('change', update);
document.getElementById('coverage-clear').addEventListener('click', () => {
  query.value = '';
  statusSelect.value = '';
  upstream.value = '';
  update();
  query.focus();
});
update();
filters.hidden = false;
