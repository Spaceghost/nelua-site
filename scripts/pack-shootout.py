"""Refresh the single public benchmark download from the recorded study inputs."""
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

root = Path(__file__).resolve().parents[1]
content = root / 'src/content'
study = content / 'results-20261122'
records = {path.relative_to(study).as_posix(): path for path in study.rglob('*') if path.is_file()}
for name in ('build-archive', 'build-incremental', 'compiler-release', 'frontend-vm', 'linker-current',
             'linker-vm-current', 'lz4-copy', 'necc-three', 'ownership', 'release-pair', 'substring-current', 'vm'):
    path = content / (name + '.csv')
    records[path.name] = path
with ZipFile(root / 'public/nelua/assets/core-shootout.zip', 'w') as archive:
    for name, path in sorted(records.items()):
        entry = ZipInfo(name, date_time=(2026, 11, 22, 0, 0, 0))
        entry.external_attr = 0o644 << 16
        archive.writestr(entry, path.read_bytes(), compress_type=ZIP_DEFLATED, compresslevel=9)
