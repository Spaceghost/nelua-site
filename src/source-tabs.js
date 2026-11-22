const tabList = document.querySelector('.source-tabs');
const tabs = Array.from(tabList.querySelectorAll('[role="tab"]'));

function selectFile(selected) {
  for (const tab of tabs) {
    const active = tab === selected;
    tab.tabIndex = active ? 0 : -1;
    tab.setAttribute('aria-selected', String(active));
    document.getElementById(tab.getAttribute('aria-controls')).hidden = !active;
  }
}

for (const [index, tab] of tabs.entries()) {
  const panel = document.getElementById(tab.getAttribute('aria-controls'));
  panel.setAttribute('role', 'tabpanel');
  panel.setAttribute('aria-labelledby', tab.id);
  panel.tabIndex = 0;
  tab.addEventListener('click', () => selectFile(tab));
  tab.addEventListener('keydown', event => {
    const next = {
      ArrowLeft: (index + tabs.length - 1) % tabs.length,
      ArrowRight: (index + 1) % tabs.length,
      Home: 0,
      End: tabs.length - 1,
    }[event.key];
    if (next === undefined) return;
    event.preventDefault();
    selectFile(tabs[next]);
    tabs[next].focus();
    tabs[next].scrollIntoView({ block: "nearest", inline: "nearest" });
  });
}
selectFile(tabs[0]);
tabList.hidden = false;
