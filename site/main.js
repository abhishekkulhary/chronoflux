// Landing page behaviour: points each download tile at the matching file in the
// latest GitHub release (falling back to the releases page, which the tiles link
// to by default), and retires the service worker the web app registered back
// when it lived at this address instead of under app/.
(async () => {
  document.getElementById('year').textContent = new Date().getFullYear();

  if ('serviceWorker' in navigator) {
    const here = new URL('./', location.href).pathname;
    try {
      for (const reg of await navigator.serviceWorker.getRegistrations()) {
        if (new URL(reg.scope).pathname === here) reg.unregister();
      }
    } catch (_) { /* not critical */ }
  }

  const repo = window.APP_REPO;
  if (!repo || repo.startsWith('__')) return; // local preview without substitution
  try {
    const res = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {
      headers: { Accept: 'application/vnd.github+json' },
    });
    if (!res.ok) return;
    const release = await res.json();
    const assets = release.assets || [];
    const pick = (test) => assets.find((a) => test(a.name.toLowerCase()));
    const targets = {
      'dl-android': pick((n) => n.endsWith('.apk')),
      'dl-windows': pick((n) => n.includes('windows') && n.endsWith('.zip')),
      'dl-macos': pick((n) => n.endsWith('.dmg')),
      'dl-linux': pick((n) => n.includes('linux') && n.endsWith('.tar.gz')),
    };
    for (const [id, asset] of Object.entries(targets)) {
      if (!asset) continue;
      const tile = document.getElementById(id);
      tile.href = asset.browser_download_url;
      const mb = (asset.size / (1024 * 1024)).toFixed(1);
      tile.querySelector('span').textContent += ` · ${mb} MB`;
    }
    const date = new Date(release.published_at).toLocaleDateString(undefined, { dateStyle: 'medium' });
    document.getElementById('release-meta').textContent =
      `Latest release ${release.tag_name} · ${date} · free and open source`;
  } catch (_) {
    // Keep the releases-page fallback.
  }
})();
