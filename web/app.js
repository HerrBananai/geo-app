'use strict';
/* ============================================================
   Geo-Begriffe · Web-App (Safari / PWA, kein Build nötig)
   Platzhalter: werden später durch echte Buchbegriffe ersetzt.
   ============================================================ */

const FALLBACK_TERMS = [
  { id: 'erosion', begriff: 'Erosion (PLATZHALTER)', definition: 'Abtragung von Gestein und Boden durch Wasser, Wind oder Eis.', beispiel: 'Ein Fluss trägt Erde an der Böschung ab.', kategorie: 'Geomorphologie' },
  { id: 'delta', begriff: 'Delta (PLATZHALTER)', definition: 'Mündungsform eines Flusses mit fächerförmiger Aufschüttung von Sedimenten.', beispiel: 'Das Nildelta in Ägypten.', kategorie: 'Gewässer' },
  { id: 'klima', begriff: 'Klima (PLATZHALTER)', definition: 'Langjähriger Mittelwert von Wettererscheinungen einer Region.', beispiel: 'Maritimes vs. kontinentales Klima.', kategorie: 'Klima' },
  { id: 'platte', begriff: 'Plattentektonik (PLATZHALTER)', definition: 'Bewegung der Lithosphärenplatten auf dem Erdmantel.', beispiel: 'Erdbeben am Plattenrand.', kategorie: 'Geologie' },
  { id: 'urbanisierung', begriff: 'Urbanisierung (PLATZHALTER)', definition: 'Wachstum der Städte und des Anteils der Stadtbevölkerung.', beispiel: 'Zuzug vom Land in die Stadt.', kategorie: 'Humangeographie' },
  { id: 'wetter', begriff: 'Wetter (PLATZHALTER)', definition: 'Aktueller Zustand der Atmosphäre an einem Ort.', beispiel: 'Regen, Sonne, Wind heute.', kategorie: 'Klima' },
  { id: 'gletscher', begriff: 'Gletscher (PLATZHALTER)', definition: 'Sich bewegende Eismasse aus verdichtetem Schnee.', beispiel: 'Aletschgletscher in der Schweiz.', kategorie: 'Geomorphologie' },
  { id: 'bewaesserung', begriff: 'Bewässerung (PLATZHALTER)', definition: 'Künstliche Zufuhr von Wasser für die Landwirtschaft.', beispiel: 'Tröpfchenbewässerung im Trockenfeldanbau.', kategorie: 'Agrargeographie' },
  { id: 'metropole', begriff: 'Metropole (PLATZHALTER)', definition: 'Großstadt mit überregionaler politischer und wirtschaftlicher Bedeutung.', beispiel: 'Berlin als Beispiel.', kategorie: 'Humangeographie' },
  { id: 'sediment', begriff: 'Sediment (PLATZHALTER)', definition: 'Ablagerung von Gesteinsmaterial durch Wind, Wasser oder Eis.', beispiel: 'Sandbank im Fluss.', kategorie: 'Geologie' },
  { id: 'treibhaus', begriff: 'Treibhauseffekt (PLATZHALTER)', definition: 'Erwärmung der Erde durch Spurengase, die Wärmestrahlung zurückhalten.', beispiel: 'CO2 als Treibhausgas.', kategorie: 'Klima' },
  { id: 'migration', begriff: 'Migration (PLATZHALTER)', definition: 'Wanderung von Menschen über Grenzen oder innerhalb eines Landes.', beispiel: 'Arbeitsmigration in Ballungsräume.', kategorie: 'Humangeographie' }
];

/* ---------- Helpers ---------- */
const $ = (sel, el) => (el || document).querySelector(sel);
const $$ = (sel, el) => Array.from((el || document).querySelectorAll(sel));
const esc = (s) => String(s == null ? '' : s)
  .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
  .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
const shuffle = (arr) => {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    const t = a[i]; a[i] = a[j]; a[j] = t;
  }
  return a;
};

/* ---------- Speicher (lokal, offline) ---------- */
const LS_KNOWN = 'geo_known_v1';
const LS_BEST = 'geo_best_v1';
const LS_INSTALL = 'geo_install_dismissed';
const LS_THEME = 'geo_theme_v1';
const LS_XP = 'geo_xp_v1';
const LS_STREAK = 'geo_streak_v1';
const LS_DESIGN = 'geo_design_v1';
function loadKnown() {
  try { return new Set(JSON.parse(localStorage.getItem(LS_KNOWN) || '[]')); }
  catch (e) { return new Set(); }
}
function loadBest() {
  try { return parseInt(localStorage.getItem(LS_BEST) || '0', 10) || 0; }
  catch (e) { return 0; }
}

/* ---------- Gamification: XP + Tages-Streak ---------- */
function loadXP() {
  try { return parseInt(localStorage.getItem(LS_XP) || '0', 10) || 0; }
  catch (e) { return 0; }
}
function loadStreak() {
  try {
    const s = JSON.parse(localStorage.getItem(LS_STREAK) || 'null');
    if (s && typeof s.count === 'number' && typeof s.last === 'string') return s;
  } catch (e) {}
  return { count: 0, last: '' };
}
function dayStr(d) { return d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate(); }
function addXP(n) {
  state.xp += n;
  try { localStorage.setItem(LS_XP, String(state.xp)); } catch (e) {}
  const today = dayStr(new Date());
  if (state.streak.last !== today) {
    const y = new Date();
    y.setDate(y.getDate() - 1);
    state.streak = {
      count: state.streak.last === dayStr(y) ? state.streak.count + 1 : 1,
      last: today
    };
    try { localStorage.setItem(LS_STREAK, JSON.stringify(state.streak)); } catch (e) {}
  }
  updateHeader();
}
const LEVELS = ['Entdecker', 'Pfadfinder', 'Forscher', 'Kartograf', 'Globetrotter', 'Geo-Profi', 'Legende'];
function levelFor(xp) {
  const level = Math.floor(xp / 100) + 1;
  return {
    level: level,
    title: LEVELS[Math.min(level - 1, LEVELS.length - 1)],
    progress: (xp % 100) / 100
  };
}

/* ---------- Herzen (Quiz) ---------- */
const HEART_SVG = '<svg class="heart" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 21s-7.6-5-10.1-9.6C.4 8 2.4 4.4 6 4.4c2 0 3.6 1.1 4.6 2.6h2.8C14.4 5.5 16 4.4 18 4.4c3.6 0 5.6 3.6 4.1 7-2.5 4.6-10.1 9.6-10.1 9.6z" fill="currentColor"/></svg>';
function heartsHtml(n) {
  let out = '';
  for (let i = 0; i < 3; i++) {
    out += n > i ? HEART_SVG : HEART_SVG.replace('class="heart"', 'class="heart lost"');
  }
  return out;
}

/* ---------- Design (Apple / Duolingo) ---------- */
function loadDesign() {
  try { return localStorage.getItem(LS_DESIGN) === 'duo' ? 'duo' : 'apple'; }
  catch (e) { return 'apple'; }
}
function applyDesign(d) {
  state.design = d;
  try { localStorage.setItem(LS_DESIGN, d); } catch (e) {}
  document.documentElement.dataset.design = d;
  $$('.seg [data-design-set]').forEach((b) => b.classList.toggle('on', b.dataset.designSet === d));
  if (state.view === 'home') go('home');
}

/* ---------- Darstellung (Hell / Dunkel / System) ---------- */
const THEME_ICONS = {
  system: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="8"/><path d="M12 4a8 8 0 0 1 0 16z" fill="currentColor" stroke="none"/></svg>',
  light: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="4.5"/><path d="M12 2.5V5M12 19v2.5M2.5 12H5M19 12h2.5M5 5l1.8 1.8M17.2 17.2 19 19M19 5l-1.8 1.8M6.8 17.2 5 19"/></svg>',
  dark: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/></svg>'
};
const THEME_LABEL = { system: 'System', light: 'Hell', dark: 'Dunkel' };
function loadTheme() {
  try {
    const t = localStorage.getItem(LS_THEME);
    return t === 'light' || t === 'dark' ? t : 'system';
  } catch (e) { return 'system'; }
}
function effectiveDark() {
  if (state.theme === 'dark') return true;
  if (state.theme === 'light') return false;
  return !!(window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches);
}
function applyTheme(mode) {
  state.theme = mode;
  try { localStorage.setItem(LS_THEME, mode); } catch (e) {}
  document.documentElement.dataset.theme = mode;
  const meta = $('#metaTheme');
  if (meta) meta.setAttribute('content', effectiveDark() ? '#000000' : '#f5f5f7');
  const icon = $('#themeIcon');
  if (icon) icon.innerHTML = THEME_ICONS[mode];
  const btn = $('#themeBtn');
  if (btn) {
    btn.setAttribute('aria-label', 'Darstellung: ' + THEME_LABEL[mode] + ' – tippen zum Wechseln');
    btn.title = 'Darstellung: ' + THEME_LABEL[mode];
  }
  $$('.seg [data-theme-set]').forEach((b) => b.classList.toggle('on', b.dataset.themeSet === mode));
}
function cycleTheme() {
  const order = ['system', 'light', 'dark'];
  applyTheme(order[(order.indexOf(state.theme) + 1) % order.length]);
  toast('Darstellung: ' + THEME_LABEL[state.theme]);
}

/* ---------- State ---------- */
const state = {
  terms: [],
  known: loadKnown(),
  best: loadBest(),
  xp: loadXP(),
  streak: loadStreak(),
  theme: 'system',
  design: 'apple',
  view: 'home',
  cards: { queue: [], i: 0, flipped: false, onlyUnknown: false },
  quiz: null,
  match: null,
  list: { query: '', cat: 'Alle', openId: null }
};

const TITLES = {
  home: ['Heute lernen', 'Geographie · Fachbegriffe'],
  cards: ['Karteikarten', 'Tippen zum Umdrehen'],
  quiz: ['Quiz', '10 Fragen pro Runde'],
  match: ['Paare', 'Begriff + Definition verbinden'],
  list: ['Alle Begriffe', 'Suchen & abhaken']
};

function saveKnown() {
  try { localStorage.setItem(LS_KNOWN, JSON.stringify(Array.from(state.known))); } catch (e) {}
  updateHeader();
}
function setKnown(id, known) {
  if (known) state.known.add(id); else state.known.delete(id);
  saveKnown();
}
function saveBest(score) {
  if (score > state.best) {
    state.best = score;
    try { localStorage.setItem(LS_BEST, String(score)); } catch (e) {}
  }
}

/* ---------- Toast ---------- */
let toastTimer = null;
function toast(msg) {
  const el = $('#toast');
  el.textContent = msg;
  el.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove('show'), 2200);
}

/* ---------- Header ---------- */
function updateHeader() {
  const total = state.terms.length;
  const done = state.known.size;
  $('#progressText').textContent = done + '/' + total;
  const ring = $('#ringFg');
  const C = 97.4;
  const frac = total ? done / total : 0;
  ring.style.strokeDashoffset = String(C * (1 - frac));
  const st = $('#streakText');
  if (st) st.textContent = state.streak.count;
  const xp = $('#xpText');
  if (xp) xp.textContent = state.xp;
}

/* ---------- Navigation ---------- */
function go(view) {
  state.view = view;
  $('#viewTitle').textContent = TITLES[view][0];
  $('#viewSubtitle').textContent = TITLES[view][1];
  $$('.tab').forEach((b) => b.classList.toggle('active', b.dataset.view === view));
  const v = $('#view');
  if (view === 'home') v.innerHTML = viewHome();
  else if (view === 'cards') { resetCardsIfNeeded(); v.innerHTML = viewCards(); }
  else if (view === 'quiz') { if (!state.quiz) newQuizRound(); v.innerHTML = viewQuiz(); }
  else if (view === 'match') { if (!state.match) newMatchRound(); v.innerHTML = viewMatch(); }
  else if (view === 'list') v.innerHTML = viewList();
  bindView(view, v);
  window.scrollTo(0, 0);
  v.style.animation = 'none';
  void v.offsetWidth;
  v.style.animation = '';
}

/* ============================================================
   HOME
   ============================================================ */
function categories() {
  const set = {};
  state.terms.forEach((t) => { set[t.kategorie] = (set[t.kategorie] || 0) + 1; });
  return set;
}

function viewHome() {
  const total = state.terms.length;
  const done = state.known.size;
  const pct = total ? Math.round((done / total) * 100) : 0;
  const cats = categories();
  const catChips = Object.keys(cats).sort().map(
    (c) => '<span class="chip">' + esc(c) + ' · <b>' + cats[c] + '</b></span>'
  ).join('');
  const lv = levelFor(state.xp);
  const levelCard = state.design === 'duo'
    ? '<section class="card level-card"><div class="row"><div class="level-badge">' + lv.level + '</div>' +
      '<div style="flex:1;min-width:0"><b>Level ' + lv.level + ' · ' + esc(lv.title) + '</b>' +
      '<div class="progress-track" style="margin-top:8px"><div class="progress-fill" style="width:' + Math.round(lv.progress * 100) + '%"></div></div></div>' +
      '<span class="counter">' + (state.xp % 100) + '/100 XP</span></div></section>'
    : '';
  return (
    '<section class="card hero">' +
      '<p class="eyebrow">Geographie · Lernstand ' + pct + ' %</p>' +
      '<h2>' + (done === total && total ? 'Alles gelernt. Stark!' : 'Weiter geht’s.') + '</h2>' +
      '<p>' + done + ' von ' + total + ' Fachbegriffen sicher drauf.</p>' +
      '<div class="hero-stats">' +
        '<div><b>' + done + '</b><span>gelernt</span></div>' +
        '<div><b>' + state.streak.count + '</b><span>Tage-Streak</span></div>' +
        '<div><b>' + state.xp + '</b><span>XP</span></div>' +
      '</div>' +
      '<button class="btn-white" id="continueBtn">Weiter lernen</button>' +
    '</section>' +
    levelCard +
    '<h3 class="section-title">Lernmodus wählen</h3>' +
    '<div class="mode-grid">' +
      '<button class="mode-tile" data-go="cards"><span class="tile-icon t-blue"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><rect x="7" y="7" width="13" height="13" rx="3"/><path d="M4 15V6a2 2 0 0 1 2-2h9"/></svg></span><b>Karteikarten</b><span>Umdrehen &amp; bewerten</span></button>' +
      '<button class="mode-tile" data-go="quiz"><span class="tile-icon t-green"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M9.5 9.3a2.6 2.6 0 0 1 5 .9c0 1.7-2.3 2-2.3 3.3"/></svg></span><b>Quiz</b><span>10 Fragen, 4 Antworten</span></button>' +
      '<button class="mode-tile" data-go="match"><span class="tile-icon t-orange"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M4 7h13l-3-3M20 17H7l3 3"/></svg></span><b>Paare</b><span>Zuordnen auf Zeitgefühl</span></button>' +
      '<button class="mode-tile" data-go="list"><span class="tile-icon t-purple"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><path d="M8 6h13M8 12h13M8 18h13"/></svg></span><b>Alle Begriffe</b><span>Suchen &amp; abhaken</span></button>' +
    '</div>' +
    '<h3 class="section-title">Kategorien</h3>' +
    '<div class="chip-row">' + catChips + '</div>' +
    '<h3 class="section-title">Einstellungen</h3>' +
    '<section class="card">' +
      '<div class="settings-row"><div class="settings-label"><b>Design</b><span>Apple oder Duolingo</span></div>' +
      '<div class="seg" role="group" aria-label="Design wählen">' +
      '<button data-design-set="apple">Apple</button>' +
      '<button data-design-set="duo">Duolingo</button>' +
      '</div></div>' +
      '<div class="settings-row"><div class="settings-label"><b>Darstellung</b><span>Hell, Dunkel oder System</span></div>' +
      '<div class="seg" role="group" aria-label="Darstellung wählen">' +
      '<button data-theme-set="system">System</button>' +
      '<button data-theme-set="light">Hell</button>' +
      '<button data-theme-set="dark">Dunkel</button>' +
      '</div></div>' +
      '<div class="settings-row"><div class="settings-label"><b>Fortschritt</b><span>Gelernte Begriffe &amp; Bestwerte</span></div>' +
      '<button class="link-danger" id="resetBtn">Zurücksetzen</button></div>' +
    '</section>'
  );
}

/* ============================================================
   KARTEIKARTEN
   ============================================================ */
function buildCardQueue() {
  let q = shuffle(state.terms);
  if (state.cards.onlyUnknown) q = q.filter((t) => !state.known.has(t.id));
  state.cards.queue = q;
  state.cards.i = 0;
  state.cards.flipped = false;
}
function resetCardsIfNeeded() {
  if (!state.cards.queue.length) buildCardQueue();
  if (state.cards.i >= state.cards.queue.length) state.cards.i = 0;
}

function viewCards() {
  const c = state.cards;
  if (!state.terms.length) return '<div class="empty">Keine Begriffe vorhanden.</div>';
  if (!c.queue.length) {
    return '<div class="card"><div class="empty">Alle Begriffe gelernt. Stark!<br><br>' +
      '<button class="btn btn-primary" id="cardsAll">Alle wiederholen</button></div></div>';
  }
  const t = c.queue[c.i];
  const known = state.known.has(t.id);
  return (
    '<div class="flash-meta">' +
      '<div class="progress-track"><div class="progress-fill" style="width:' + Math.round(((c.i + 1) / c.queue.length) * 100) + '%"></div></div>' +
      '<span class="counter">' + (c.i + 1) + '/' + c.queue.length + '</span>' +
    '</div>' +
    '<div class="flash-meta">' +
      '<button class="filter-chip' + (c.onlyUnknown ? ' on' : '') + '" id="cardsFilter">Nur ungelernte</button>' +
      '<span class="spacer"></span>' +
      (known ? '<span class="learned-badge">✓ gelernt</span>' : '') +
      '<button class="icon-btn" id="cardsShuffle" title="Mischen" aria-label="Mischen">⤨</button>' +
    '</div>' +
    '<div class="flip-scene"><div class="flip-card' + (c.flipped ? ' flipped' : '') + '" id="flipCard" role="button" tabindex="0" aria-label="Karte umdrehen">' +
      '<div class="flip-face front"><span class="pill-cat">' + esc(t.kategorie) + '</span><h3>' + esc(t.begriff) + '</h3><span class="hint">Tippen zum Umdrehen</span></div>' +
      '<div class="flip-face back"><span class="pill-cat">' + esc(t.kategorie) + '</span><p class="def">' + esc(t.definition) + '</p><div class="example-box">Beispiel: ' + esc(t.beispiel) + '</div></div>' +
    '</div></div>' +
    '<div class="btn-row"><button class="btn btn-plain" id="cardsNo">Nochmal</button>' +
    '<button class="btn btn-primary" id="cardsYes">Gewusst</button></div>' +
    '<div class="stepper"><button id="cardsPrev"' + (c.i === 0 ? ' disabled' : '') + '>‹ Zurück</button>' +
    '<button id="cardsNext"' + (c.i >= c.queue.length - 1 ? ' disabled' : '') + '>Weiter ›</button></div>'
  );
}

function markCard(known) {
  const c = state.cards;
  if (!c.queue.length) return;
  const t = c.queue[c.i];
  const wasKnown = state.known.has(t.id);
  setKnown(t.id, known);
  if (known && !wasKnown) addXP(5);
  if (c.onlyUnknown && known) {
    c.queue = c.queue.filter((x) => x.id !== t.id);
    if (c.i >= c.queue.length) c.i = 0;
    c.flipped = false;
    if (!c.queue.length) { go('cards'); toast('Alle ungelernten geschafft!'); return; }
  } else if (c.i < c.queue.length - 1) {
    c.i++; c.flipped = false;
  } else {
    c.flipped = false;
    toast('Stapel durch – wird neu gemischt.');
    buildCardQueue();
  }
  go('cards');
}

/* ============================================================
   QUIZ
   ============================================================ */
function newQuizRound() {
  const pool = shuffle(state.terms);
  const round = pool.slice(0, 10);
  state.quiz = {
    questions: round.map((t) => {
      const others = shuffle(state.terms.filter((x) => x.id !== t.id));
      const opts = [t.begriff];
      for (const o of others) { if (opts.length >= 4) break; opts.push(o.begriff); }
      return { correct: t, options: shuffle(opts) };
    }),
    i: 0, score: 0, picked: null, finished: false, hearts: 3, gained: 0, outOfHearts: false
  };
}

function viewQuiz() {
  const qz = state.quiz;
  if (state.terms.length < 4) return '<div class="empty">Mindestens 4 Begriffe fürs Quiz nötig.</div>';
  if (qz.finished) {
    const answered = qz.i + 1;
    return '<section class="card result-wrap">' +
      '<p class="eyebrow">' + (qz.outOfHearts ? 'Herzen aufgebraucht!' : 'Runde beendet') + '</p>' +
      '<div class="score-big">' + qz.score + '/' + answered + '</div>' +
      '<p class="xp-gained">+' + qz.gained + ' XP</p>' +
      '<p class="muted">Bestleistung: ' + state.best + ' · ' +
      (qz.score === qz.questions.length ? 'Fehlerfrei. Sehr stark!' : qz.score >= 7 ? 'Solides Wissen!' : 'Bleib dran – Wiederholung hilft.') + '</p>' +
      '<button class="btn btn-primary" id="quizAgain">Neue Runde</button></section>';
  }
  const q = qz.questions[qz.i];
  const opts = q.options.map((opt) => {
    let cls = 'opt';
    if (qz.picked) {
      if (opt === q.correct.begriff) cls += ' correct';
      else if (opt === qz.picked) cls += ' wrong';
    }
    return '<button class="' + cls + '"' + (qz.picked ? ' disabled' : '') +
      ' data-opt="' + esc(opt) + '">' + esc(opt) + '</button>';
  }).join('');
  return (
    '<div class="flash-meta"><span class="hearts" aria-label="Herzen">' + heartsHtml(qz.hearts) + '</span><div class="progress-track"><div class="progress-fill" style="width:' +
      Math.round(((qz.i + 1) / qz.questions.length) * 100) + '%"></div></div>' +
      '<span class="counter">Frage ' + (qz.i + 1) + '/' + qz.questions.length + ' · ' + qz.score + ' P.</span></div>' +
    '<section class="card"><p class="eyebrow" style="text-align:center">' + esc(q.correct.kategorie) + '</p>' +
      '<p class="quiz-q">' + esc(q.correct.definition) + '</p>' +
      '<p class="muted" style="text-align:center;font-size:13px">Welcher Begriff passt?</p></section>' +
    opts +
    (qz.picked ? '<div class="btn-row"><button class="btn btn-primary" id="quizNext">' +
      (qz.i < qz.questions.length - 1 ? 'Weiter' : 'Ergebnis') + '</button></div>' : '')
  );
}

function pickQuiz(opt) {
  const qz = state.quiz;
  if (!qz || qz.picked || qz.finished) return;
  qz.picked = opt;
  if (opt === qz.questions[qz.i].correct.begriff) {
    qz.score++;
    qz.gained += 10;
    addXP(10);
  } else {
    qz.hearts--;
    if (qz.hearts <= 0) {
      qz.finished = true;
      qz.outOfHearts = true;
      saveBest(qz.score);
      toast('Herzen aufgebraucht! +' + qz.gained + ' XP');
      go('quiz');
      return;
    }
  }
  go('quiz');
}
function nextQuiz() {
  const qz = state.quiz;
  if (qz.i < qz.questions.length - 1) { qz.i++; qz.picked = null; }
  else { qz.finished = true; saveBest(qz.score); toast('Runde fertig! +' + qz.gained + ' XP'); }
  go('quiz');
}

/* ============================================================
   PAARE (Zuordnen)
   ============================================================ */
function newMatchRound() {
  const pick = shuffle(state.terms).slice(0, 4);
  state.match = {
    left: shuffle(pick), right: shuffle(pick),
    sel: null, solved: [], err: null, tries: 0, gained: 0
  };
}

function viewMatch() {
  const m = state.match;
  if (state.terms.length < 4) return '<div class="empty">Mindestens 4 Begriffe nötig.</div>';
  const left = m.left.map((t) => {
    const done = m.solved.indexOf(t.id) !== -1;
    const cls = 'm-left' + (done ? ' done' : m.sel === t.id ? ' sel' : '');
    return '<button class="' + cls + '"' + (done ? ' disabled' : '') + ' data-left="' + esc(t.id) + '">' +
      (done ? '✓ ' : '') + esc(t.begriff) + '</button>';
  }).join('');
  const right = m.right.map((t) => {
    const done = m.solved.indexOf(t.id) !== -1;
    const cls = 'm-right' + (done ? ' done' : m.err === t.id ? ' err' : '');
    return '<button class="' + cls + '"' + (done ? ' disabled' : '') + ' data-right="' + esc(t.id) + '">' +
      esc(t.definition) + '</button>';
  }).join('');
  const finished = m.solved.length === m.left.length;
  return (
    '<div class="row"><span class="counter">Paare ' + m.solved.length + '/4 · Versuche ' + m.tries + '</span>' +
    '<span class="spacer"></span><button class="icon-btn" id="matchNew" title="Neue Runde" aria-label="Neue Runde">↻</button></div>' +
    '<p class="muted" style="font-size:13px;margin:8px 2px 0">1. Begriff links wählen, 2. passende Definition rechts tippen.</p>' +
    '<div class="match-cols"><div class="match-col">' + left + '</div><div class="match-col">' + right + '</div></div>' +
    (finished ? '<div class="btn-row"><button class="btn btn-primary" id="matchAgain">Neue Runde</button></div>' : '')
  );
}

function tapMatchLeft(id) {
  const m = state.match;
  if (m.solved.indexOf(id) !== -1) return;
  m.sel = id; m.err = null;
  go('match');
}
function tapMatchRight(id) {
  const m = state.match;
  if (!m.sel || m.solved.indexOf(id) !== -1) return;
  m.tries++;
  if (m.sel === id) {
    m.solved.push(id);
    m.sel = null; m.err = null;
    m.gained += 5;
    addXP(5);
    if (m.solved.length === m.left.length) toast('Geschafft! +' + m.gained + ' XP');
  } else {
    m.err = id;
  }
  go('match');
}

/* ============================================================
   LISTE
   ============================================================ */
function viewList() {
  const l = state.list;
  const cats = ['Alle'].concat(Object.keys(categories()).sort());
  const q = l.query.trim().toLowerCase();
  const filtered = state.terms.filter((t) => {
    const mq = !q || t.begriff.toLowerCase().indexOf(q) !== -1 ||
      t.definition.toLowerCase().indexOf(q) !== -1;
    const mc = l.cat === 'Alle' || t.kategorie === l.cat;
    return mq && mc;
  });
  const pills = cats.map((c) =>
    '<button class="filter-chip' + (l.cat === c ? ' on' : '') + '" data-cat="' + esc(c) + '">' + esc(c) + '</button>'
  ).join('');
  const items = filtered.map((t) => {
    const known = state.known.has(t.id);
    const open = l.openId === t.id;
    return '<section class="card term' + (open ? ' open' : '') + '">' +
      '<button class="term-head" data-open="' + esc(t.id) + '">' +
        '<span class="term-check' + (known ? ' done' : '') + '" data-check="' + esc(t.id) + '" role="checkbox" aria-checked="' + known + '">' + (known ? '✓' : '') + '</span>' +
        '<span class="term-title' + (known ? ' done' : '') + '"><b>' + esc(t.begriff) + '</b><span>' + esc(t.kategorie) + '</span></span>' +
        '<span class="chev">▾</span>' +
      '</button>' +
      '<div class="term-body">' + esc(t.definition) +
        '<div class="example-box" style="margin-top:10px">Beispiel: ' + esc(t.beispiel) + '</div></div>' +
    '</section>';
  }).join('');
  return (
    '<input class="search" id="listSearch" type="search" placeholder="Suchen …" value="' + esc(l.query) + '" aria-label="Begriffe suchen" />' +
    '<div class="cat-row">' + pills + '</div>' +
    '<p class="muted" style="font-size:13px;margin:2px 2px 0">' + filtered.length + ' Begriffe · Haken = kann ich</p>' +
    (items || '<div class="empty">Nichts gefunden.</div>')
  );
}

/* ---------- Events pro Ansicht ---------- */
function bindView(view, root) {
  if (view === 'home') {
    $('#continueBtn').addEventListener('click', () => go('cards'));
    $$('[data-go]', root).forEach((b) => b.addEventListener('click', () => go(b.dataset.go)));
    $$('[data-theme-set]', root).forEach((b) => b.addEventListener('click', () => {
      applyTheme(b.dataset.themeSet);
      toast('Darstellung: ' + THEME_LABEL[state.theme]);
    }));
    applyTheme(state.theme);
    $$('[data-design-set]', root).forEach((b) => {
      b.classList.toggle('on', b.dataset.designSet === state.design);
      b.addEventListener('click', () => applyDesign(b.dataset.designSet));
    });
    $('#resetBtn').addEventListener('click', () => {
      if (confirm('Fortschritt (Begriffe, XP, Streak) wirklich löschen?')) {
        state.known.clear();
        try {
          localStorage.removeItem(LS_KNOWN);
          localStorage.removeItem(LS_BEST);
          localStorage.removeItem(LS_XP);
          localStorage.removeItem(LS_STREAK);
        } catch (e) {}
        state.best = 0;
        state.xp = 0;
        state.streak = { count: 0, last: '' };
        updateHeader();
        go('home');
        toast('Fortschritt gelöscht.');
      }
    });
  } else if (view === 'cards') {
    const again = $('#cardsAll');
    if (again) { again.addEventListener('click', () => { state.cards.onlyUnknown = false; buildCardQueue(); go('cards'); }); return; }
    const flip = $('#flipCard');
    flip.addEventListener('click', () => { state.cards.flipped = !state.cards.flipped; flip.classList.toggle('flipped', state.cards.flipped); });
    flip.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); flip.click(); } });
    $('#cardsYes').addEventListener('click', () => markCard(true));
    $('#cardsNo').addEventListener('click', () => markCard(false));
    $('#cardsPrev').addEventListener('click', () => { if (state.cards.i > 0) { state.cards.i--; state.cards.flipped = false; go('cards'); } });
    $('#cardsNext').addEventListener('click', () => { if (state.cards.i < state.cards.queue.length - 1) { state.cards.i++; state.cards.flipped = false; go('cards'); } });
    $('#cardsShuffle').addEventListener('click', () => { state.cards.queue = shuffle(state.cards.queue); state.cards.i = 0; state.cards.flipped = false; go('cards'); });
    $('#cardsFilter').addEventListener('click', () => { state.cards.onlyUnknown = !state.cards.onlyUnknown; buildCardQueue(); go('cards'); });
  } else if (view === 'quiz') {
    $$('[data-opt]', root).forEach((b) => b.addEventListener('click', () => pickQuiz(b.dataset.opt)));
    const next = $('#quizNext');
    if (next) next.addEventListener('click', nextQuiz);
    const again = $('#quizAgain');
    if (again) again.addEventListener('click', () => { newQuizRound(); go('quiz'); });
  } else if (view === 'match') {
    $$('[data-left]', root).forEach((b) => b.addEventListener('click', () => tapMatchLeft(b.dataset.left)));
    $$('[data-right]', root).forEach((b) => b.addEventListener('click', () => tapMatchRight(b.dataset.right)));
    const n = $('#matchNew');
    if (n) n.addEventListener('click', () => { newMatchRound(); go('match'); });
    const a = $('#matchAgain');
    if (a) a.addEventListener('click', () => { newMatchRound(); go('match'); });
  } else if (view === 'list') {
    const s = $('#listSearch');
    s.addEventListener('input', () => {
      state.list.query = s.value;
      const pos = s.selectionStart;
      const scroll = window.scrollY;
      go('list');
      const ns = $('#listSearch');
      ns.focus();
      try { ns.setSelectionRange(pos, pos); } catch (e) {}
      window.scrollTo(0, scroll);
    });
    $$('[data-cat]', root).forEach((b) => b.addEventListener('click', () => { state.list.cat = b.dataset.cat; go('list'); }));
    $$('[data-check]', root).forEach((b) => b.addEventListener('click', (e) => {
      e.stopPropagation();
      const id = b.dataset.check;
      setKnown(id, !state.known.has(id));
      go('list');
    }));
    $$('[data-open]', root).forEach((b) => b.addEventListener('click', (e) => {
      if (e.target.closest('[data-check]')) return;
      const id = b.dataset.open;
      state.list.openId = state.list.openId === id ? null : id;
      go('list');
    }));
  }
}

/* ---------- Start ---------- */
async function loadTerms() {
  const urls = ['data/terms.json', '../assets/data/terms.json'];
  for (const u of urls) {
    try {
      const res = await fetch(u);
      if (!res.ok) continue;
      const data = await res.json();
      if (Array.isArray(data) && data.length) return data;
    } catch (e) { /* weiter – z. B. file:// blockt fetch */ }
  }
  return FALLBACK_TERMS;
}

function setupInstallBanner() {
  const banner = $('#installBanner');
  let dismissed = false;
  try { dismissed = localStorage.getItem(LS_INSTALL) === '1'; } catch (e) {}
  const isApple = /iPhone|iPad|iPod|Macintosh/.test(navigator.userAgent);
  const standalone = window.navigator.standalone === true ||
    window.matchMedia('(display-mode: standalone)').matches;
  if (isApple && !standalone && !dismissed) banner.hidden = false;
  $('#installClose').addEventListener('click', () => {
    banner.hidden = true;
    try { localStorage.setItem(LS_INSTALL, '1'); } catch (e) {}
  });
}

async function init() {
  state.terms = await loadTerms();
  buildCardQueue();
  state.theme = loadTheme();
  applyTheme(state.theme);
  state.design = loadDesign();
  document.documentElement.dataset.design = state.design;
  $('#themeBtn').addEventListener('click', cycleTheme);
  if (window.matchMedia) {
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const syncMeta = () => {
      const meta = $('#metaTheme');
      if (meta && state.theme === 'system') {
        meta.setAttribute('content', mq.matches ? '#000000' : '#f5f5f7');
      }
    };
    if (mq.addEventListener) mq.addEventListener('change', syncMeta);
    else if (mq.addListener) mq.addListener(syncMeta);
  }
  $$('.tab').forEach((b) => b.addEventListener('click', () => go(b.dataset.view)));
  updateHeader();
  setupInstallBanner();
  if ('serviceWorker' in navigator && /^https?:/.test(location.protocol)) {
    try { await navigator.serviceWorker.register('sw.js'); } catch (e) {}
  }
  go('home');
}

document.addEventListener('DOMContentLoaded', init);
