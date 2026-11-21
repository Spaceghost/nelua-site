// The plain-text inventory is published verbatim from the Nebox runtime check.
export function parseCatalog(source) {
  const versions = source.match(/BusyBox ([\d.]+) or Toybox ([\d.]+),/);
  const union = source.match(/^\| Union \| (\d+) \| (\d+) \| (\d+) \|$/m);
  const [body, extraSection] = source.split('\n## Additional Nebox names\n');
  if (!versions || !union || extraSection === undefined) {
    throw new Error('Missing upstream versions, union totals or additional names in the Nebox inventory');
  }

  const rows = body.split('\n').filter(line => line.startsWith('| `')).map(line => {
    const fields = /^\| `([^`]+)` \| (yes|) \| (yes|shell|) \| (Registered|Missing|—) \| (Builtin|Missing|—) \|$/.exec(line);
    if (!fields) throw new Error('Invalid Nebox inventory row: ' + line);
    const [, name, busybox, toybox, executable, shell] = fields;
    const upstream = busybox && toybox ? 'both' : busybox ? 'busybox' : 'toybox';
    const status = executable === 'Missing' || shell === 'Missing' ? 'missing' : 'covered';
    return { name, busybox, toybox, executable, shell, upstream, status };
  });
  const covered = rows.filter(row => row.status === 'covered').length;
  const missing = rows.length - covered;
  if (covered !== Number(union[1]) || missing !== Number(union[2]) || rows.length !== Number(union[3])) {
    throw new Error('Nebox inventory totals disagree with its command rows');
  }
  const extras = [...extraSection.matchAll(/`([^`]+)`/g)].map(match => match[1]);
  const totals = [
    { label: 'Upstream names', count: rows.length },
    { label: 'Covered', count: covered },
    { label: 'Missing', count: missing },
  ];
  return { busyboxVersion: versions[1], toyboxVersion: versions[2], rows, extras, totals };
}
