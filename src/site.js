(() => {
  if (document.body.hasAttribute('data-language-redirect')) {
    const language = (navigator.language || '').toLowerCase().split('-')[0];
    const directory = language === 'en' ? 'en/' : 'ru/';
    location.replace(location.protocol === 'file:' ? directory + 'index.html' : directory);
    return;
  }

  const select = document.querySelector('[data-theme-select]');
  if (!select) return;

  const toggle = document.querySelector('[data-theme-toggle]');
  const root = document.documentElement;
  const systemTheme = matchMedia('(prefers-color-scheme: dark)');
  const isDark = () => root.dataset.theme === 'dark' || (!root.dataset.theme && systemTheme.matches);
  const updateToggle = () => toggle.setAttribute('aria-pressed', String(isDark()));

  const applyTheme = (theme) => {
    select.value = theme;
    if (theme === 'auto') delete root.dataset.theme;
    else root.dataset.theme = theme;
    updateToggle();
  };

  select.value = root.dataset.theme || 'auto';
  try {
    const saved = localStorage.getItem('kovetz-theme');
    if (saved === 'dark' || saved === 'light') select.value = saved;
  } catch {
    // Theme changes still work when the browser blocks storage.
  }

  applyTheme(select.value);
  select.closest('label').hidden = false;
  toggle.hidden = false;
  const saveTheme = (theme) => {
    applyTheme(theme);
    try {
      localStorage.setItem('kovetz-theme', theme);
    } catch {
      // The currently selected theme remains active.
    }
  };
  select.addEventListener('change', () => saveTheme(select.value));
  toggle.addEventListener('click', () => saveTheme(isDark() ? 'light' : 'dark'));
  systemTheme.addEventListener('change', updateToggle);
})();
