const nodes = [...document.querySelectorAll('[data-en]')];
for (const node of nodes) node.dataset.zh = node.innerHTML;
const images = [...document.querySelectorAll('[data-alt-en]')];
for (const image of images) image.dataset.altZh = image.alt;
const button = document.querySelector('#language');
function setLanguage(language) {
 const english = language === 'en';
 document.documentElement.lang = english ? 'en' : 'zh-CN';
 document.title = english ? 'mac-state — Your Mac’s pulse. Just a glance away.' : 'mac-state — Mac 状态，一眼即知。';
 for (const node of nodes) { if (english) node.textContent = node.dataset.en; else node.innerHTML = node.dataset.zh; }
 for (const image of images) image.alt = english ? image.dataset.altEn : image.dataset.altZh;
 button.textContent = english ? '中文' : 'EN';
 button.setAttribute('aria-label', english ? '切换为中文' : 'Switch to English');
 try { localStorage.setItem('mac-state-site-language', english ? 'en' : 'zh-CN'); } catch {}
}
let language = 'zh-CN';
try { language = localStorage.getItem('mac-state-site-language') || language; } catch {}
setLanguage(language);
button.addEventListener('click', () => setLanguage(document.documentElement.lang === 'en' ? 'zh-CN' : 'en'));

const themeButton = document.querySelector('#theme');
let theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
try { theme = localStorage.getItem('mac-state-site-theme') || theme; } catch {}
function setTheme(value) { document.documentElement.dataset.theme = value; themeButton.setAttribute('aria-pressed', String(value === 'dark')); }
setTheme(theme);
themeButton.addEventListener('click', () => { theme = theme === 'dark' ? 'light' : 'dark'; setTheme(theme); try { localStorage.setItem('mac-state-site-theme', theme); } catch {} });
