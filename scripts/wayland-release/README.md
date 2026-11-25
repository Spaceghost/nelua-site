# Theseus Wayland assets
The Wasm, guest image and matching source packages are released alongside the
static demo. We do not store roughly 200 MB of release binaries and upstream
source archives in Git. The site build copies supplied assets from
`public/nelua/init/wayland`, or restores exact content from the existing
same-origin release. The lock checks SHA-256 and byte length. The browser never
uses an external disk or CDN. The daily community workflow is unchanged.

For a rebuild without the live site, restore the locked artifacts into the
public directory from the release backup or pre-seed
`NELUA_WAYLAND_ASSET_CACHE` with files named by SHA-256. Set
`NELUA_WAYLAND_OFFLINE=1` to enforce this. Missing or wrong bytes fail the
build rather than silently dropping the demo.
