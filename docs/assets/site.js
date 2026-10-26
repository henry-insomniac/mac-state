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

const scene = document.querySelector('#notch-demo');
const target = document.querySelector('.notch-target');
const replay = document.querySelector('.replay');
const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)');
let demoTimer;
function showDemo(open) {
 clearTimeout(demoTimer);
 scene.dataset.state = open ? 'open' : 'idle';
 target.setAttribute('aria-expanded', String(open));
 document.querySelector('#demo-panel').setAttribute('aria-hidden', String(!open));
}
function playDemo() {
 if (reducedMotion.matches) { showDemo(true); return; }
 showDemo(false);
 requestAnimationFrame(() => requestAnimationFrame(() => {
  scene.dataset.state = 'playing';
  target.setAttribute('aria-expanded', 'true');
  document.querySelector('#demo-panel').setAttribute('aria-hidden', 'false');
  demoTimer = setTimeout(() => showDemo(true), 4000);
 }));
}
target.addEventListener('click', () => showDemo(target.getAttribute('aria-expanded') !== 'true'));
replay.addEventListener('click', playDemo);
reducedMotion.addEventListener('change', () => showDemo(true));
showDemo(reducedMotion.matches);
const demoObserver = new IntersectionObserver(entries => {
 if (entries.some(entry => entry.isIntersecting)) { playDemo(); demoObserver.disconnect(); }
}, {threshold:.45});
demoObserver.observe(scene);
