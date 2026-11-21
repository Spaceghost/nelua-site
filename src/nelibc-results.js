(() => {
  const root = document.getElementById('benchmark-results');
  if (!root) return;
  const query = root.querySelector('#benchmark-query');
  const profile = root.querySelector('#benchmark-profile');
  const outcome = root.querySelector('#benchmark-outcome');
  const count = root.querySelector('#benchmark-count');
  const groups = Array.from(root.querySelectorAll('details'), element => ({
    element, rows: Array.from(element.querySelectorAll('tbody tr')),
  }));
  const total = groups.reduce((n, group) => n + group.rows.length, 0);
  let previousOpen;

  function filter() {
    const term = query.value.trim().toLowerCase();
    const active = Boolean(term || profile.value || outcome.value);
    if (active && !previousOpen) previousOpen = groups.map(group => group.element.open);
    let visible = 0;
    groups.forEach(({element, rows}, index) => {
      const inProfile = !profile.value || profile.value === element.dataset.benchmarkProfile;
      let matches = 0;
      for (const row of rows) {
        row.hidden = !inProfile || !row.dataset.case.includes(term)
          || Boolean(outcome.value && row.dataset.outcome !== outcome.value);
        if (!row.hidden) matches++;
      }
      element.querySelector('[data-count]').textContent = matches;
      element.hidden = matches === 0;
      if (active) element.open = matches > 0;
      else if (previousOpen) element.open = previousOpen[index];
      visible += matches;
    });
    if (!active) previousOpen = undefined;
    count.textContent = visible ? visible + ' of ' + total + ' results' : 'No matching results.';
    count.hidden = !active;
  }

  query.addEventListener('input', filter);
  profile.addEventListener('change', filter);
  outcome.addEventListener('change', filter);
  root.querySelector('#benchmark-clear').addEventListener('click', () => {
    query.value = profile.value = outcome.value = '';
    filter();
    query.focus();
  });
  root.querySelector('#benchmark-filters').hidden = false;
  filter();
})();
