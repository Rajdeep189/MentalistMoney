/* ============================================================
   mentalist — web build
   Mirrors lib/providers/app_provider.dart 1:1 (seed, analytics,
   streaks, Bia insight) and renders the same 5 screens.
   Offline-first: persisted to localStorage (stands in for sqflite).
   ============================================================ */
'use strict';

/* ---------------- icons (inline SVG, stroke style) ---------------- */
const ICONS = {
  home: '<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/>',
  chart: '<path d="M5 20v-8"/><path d="M12 20V5"/><path d="M19 20v-6"/>',
  receipt: '<path d="M6 3h12v18l-2-1.5L14 21l-2-1.5L10 21l-2-1.5L6 21z"/><path d="M9 8h6M9 12h6"/>',
  wallet: '<rect x="3" y="6" width="18" height="13" rx="3"/><path d="M3 10h18"/><circle cx="16.5" cy="14.5" r="1" fill="currentColor" stroke="none"/>',
  add: '<path d="M12 5v14M5 12h14"/>',
  flame: '<path fill="currentColor" stroke="none" d="M12 2.5c2.2 3.2 5 5.8 5 9.3a5 5 0 0 1-10 0c0-3.5 2.8-6.1 5-9.3z"/>',
  sparkle: '<path d="M12 3l1.9 5.4L19.5 10l-5.6 1.6L12 17l-1.9-5.4L4.5 10l5.6-1.6z"/><path d="M18.5 15.5l.8 2.2 2.2.8-2.2.8-.8 2.2-.8-2.2-2.2-.8 2.2-.8z"/>',
  eye: '<path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6-10-6-10-6z"/><circle cx="12" cy="12" r="2.5"/>',
  eyeOff: '<path d="M2 12s3.5-6 10-6c1.8 0 3.4.5 4.8 1.3M22 12s-3.5 6-10 6c-1.8 0-3.4-.5-4.8-1.3"/><path d="M4 4l16 16"/>',
  bell: '<path d="M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6"/><path d="M10 19a2 2 0 0 0 4 0"/>',
  close: '<path d="M6 6l12 12M18 6 6 18"/>',
  check: '<path d="M4 12.5 9.5 18 20 6.5"/>',
  warn: '<path d="M12 3 2.5 20h19z"/><path d="M12 9.5v4.5"/><circle cx="12" cy="17" r=".6" fill="currentColor" stroke="none"/>',
  arrowUp: '<path d="M12 19V5M6 11l6-6 6 6"/>',
  arrowDown: '<path d="M12 5v14M6 13l6 6 6-6"/>',
  swap: '<path d="M7 4v13M7 4 4 7m3-3 3 3"/><path d="M17 20V7m0 13 3-3m-3 3-3-3"/>',
  users: '<circle cx="9" cy="8" r="3"/><path d="M3 20c0-3.3 2.7-6 6-6s6 2.7 6 6"/><circle cx="17" cy="9" r="2.5"/><path d="M16.5 14.6c2.6.5 4.5 2.7 4.5 5.4"/>',
  refresh: '<path d="M20 12a8 8 0 1 1-2.3-5.7"/><path d="M20 4v5h-5"/>',
  help: '<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 1 1 3.8 2.1c-.9.5-1.3 1-1.3 1.9"/><circle cx="12" cy="17" r=".6" fill="currentColor" stroke="none"/>',
  calendar: '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/>',
  rocket: '<path d="M12 15c-2 0-3.5-1.2-3.5-3.2C8.5 7.5 12 3 12 3s3.5 4.5 3.5 8.8c0 2-1.5 3.2-3.5 3.2z"/><path d="M8.5 11.5 5 14l1 3.5L9.5 15M15.5 11.5 19 14l-1 3.5L14.5 15"/><circle cx="12" cy="9" r="1.2"/>',
  memory: '<rect x="6" y="6" width="12" height="12" rx="2"/><path d="M9 2v4M15 2v4M9 18v4M15 18v4M2 9h4M2 15h4M18 9h4M18 15h4"/>',
  food: '<path d="M6 3v7a2.5 2.5 0 0 0 5 0V3"/><path d="M8.5 3v18"/><path d="M17 3c-1.8 1.8-1.8 5.2 0 7v11"/>',
  car: '<path d="M4.5 14 6 9.8A2 2 0 0 1 7.9 8.5h8.2A2 2 0 0 1 18 9.8L19.5 14"/><rect x="3" y="14" width="18" height="4.5" rx="1.5"/><circle cx="7.5" cy="18.5" r="1.6"/><circle cx="16.5" cy="18.5" r="1.6"/>',
  bag: '<path d="M6 8h12l-1.2 12.2a1.5 1.5 0 0 1-1.5 1.3H8.7a1.5 1.5 0 0 1-1.5-1.3z"/><path d="M9 10V7a3 3 0 0 1 6 0v3"/>',
  cart: '<circle cx="9.5" cy="20" r="1.4"/><circle cx="17" cy="20" r="1.4"/><path d="M3 4h2.2L7.6 15h10.2L20.5 8H6"/>',
  film: '<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M7.5 5v14M16.5 5v14M3 10h4.5M3 14h4.5M16.5 10H21M16.5 14H21"/>',
  heart: '<path d="M12 20.5S3.5 15.6 3.5 9.8A4.6 4.6 0 0 1 12 6.7a4.6 4.6 0 0 1 8.5 3.1c0 5.8-8.5 10.7-8.5 10.7z"/>',
  briefcase: '<rect x="3" y="8" width="18" height="12" rx="2.5"/><path d="M9 8V6.5A2.5 2.5 0 0 1 11.5 4h1A2.5 2.5 0 0 1 15 6.5V8"/><path d="M3 13h18"/>',
  grid: '<rect x="4" y="4" width="7" height="7" rx="2"/><rect x="13" y="4" width="7" height="7" rx="2"/><rect x="4" y="13" width="7" height="7" rx="2"/><rect x="13" y="13" width="7" height="7" rx="2"/>',
};
function icon(name, size) {
  size = size || 24;
  return '<svg viewBox="0 0 24 24" width="' + size + '" height="' + size + '" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' + (ICONS[name] || ICONS.grid) + '</svg>';
}

/* ---------------- categories ---------------- */
const CATS = {
  food:        { key: 'food', label: 'Food & Dining', icon: 'food', c1: '#FF8A3D', c2: '#FF5E62' },
  transport:   { key: 'transport', label: 'Transport', icon: 'car', c1: '#4E9BFF', c2: '#2E6BF6' },
  shopping:    { key: 'shopping', label: 'Shopping', icon: 'bag', c1: '#FF5EA8', c2: '#D63384' },
  groceries:   { key: 'groceries', label: 'Groceries', icon: 'cart', c1: '#34C77B', c2: '#1FA85C' },
  bills:       { key: 'bills', label: 'Bills & Utilities', icon: 'receipt', c1: '#22B8CF', c2: '#0E8FA8' },
  entertainment:{ key: 'entertainment', label: 'Entertainment', icon: 'film', c1: '#9B6BFF', c2: '#6C3DF4' },
  health:      { key: 'health', label: 'Health', icon: 'heart', c1: '#FF5E62', c2: '#E5484D' },
  salary:      { key: 'salary', label: 'Salary', icon: 'wallet', c1: '#2FBF71', c2: '#128A4C' },
  freelance:   { key: 'freelance', label: 'Freelance', icon: 'briefcase', c1: '#FFB020', c2: '#FF8A00' },
  transfer:    { key: 'transfer', label: 'Transfer', icon: 'swap', c1: '#8A93A6', c2: '#5B6472' },
  other:       { key: 'other', label: 'Other', icon: 'grid', c1: '#B8A98A', c2: '#8A7B5E' },
};
const EXPENSE_CATS = ['food','transport','shopping','groceries','bills','entertainment','health','other'];
const INCOME_CATS = ['salary','freelance','other'];

/* ---------------- helpers ---------------- */
const $ = (s, el) => (el || document).querySelector(s);
const dayStart = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
const nfINR = (digits) => new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', minimumFractionDigits: digits, maximumFractionDigits: digits });
function fmtMoney(v, digits) { return nfINR(digits === undefined ? 2 : digits).format(v); }
function fmtShort(v) { const s = fmtMoney(v, 2); return s.endsWith('.00') ? s.slice(0, -3) : s; }
const dfDay = new Intl.DateTimeFormat('en-IN', { day: 'numeric', month: 'short' });
const dfFull = new Intl.DateTimeFormat('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
const dfMY = new Intl.DateTimeFormat('en-IN', { month: 'long', year: 'numeric' });
const dfMD = new Intl.DateTimeFormat('en-IN', { month: 'short', day: 'numeric' });
const dfMDY = new Intl.DateTimeFormat('en-IN', { month: 'short', day: 'numeric', year: 'numeric' });
const fmtDay = (ms) => dfDay.format(new Date(ms));
const fmtDayFull = (ms) => dfFull.format(new Date(ms));
function esc(s) { return String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c])); }

/* mulberry32 — deterministic PRNG (stands in for Dart's Random(42)) */
function mulberry32(a) {
  return function () {
    a |= 0; a = (a + 0x6D2B79F5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/* ---------------- state + persistence (sqflite stand-in) ---------------- */
const LS_KEY = 'mentalist-data-v1';
let state = null;

function save() { localStorage.setItem(LS_KEY, JSON.stringify(state)); }
function load() {
  try {
    const raw = localStorage.getItem(LS_KEY);
    if (raw) { state = JSON.parse(raw); return; }
  } catch (e) { /* fall through to seed */ }
  state = seed();
  save();
}

function seed() {
  const accounts = [
    { id: 1, name: 'HDFC Bank', type: 'bank', balance: 84250.00, maskedNumber: 'Account **4821', c1: '#1E3A8A', c2: '#3B82F6' },
    { id: 2, name: 'ICICI Credit Card', type: 'card', balance: -12480.50, maskedNumber: '**** 3264', c1: '#0F172A', c2: '#475569' },
    { id: 3, name: 'Cash Wallet', type: 'cash', balance: 3200.00, maskedNumber: 'Physical cash', c1: '#065F46', c2: '#34D399' },
  ];
  const budgets = [
    { id: 1, categoryKey: 'food', limit: 9000, period: 'Monthly' },
    { id: 2, categoryKey: 'transport', limit: 3500, period: 'Monthly' },
    { id: 3, categoryKey: 'shopping', limit: 6000, period: 'Monthly' },
    { id: 4, categoryKey: 'entertainment', limit: 2500, period: 'Monthly' },
    { id: 5, categoryKey: 'bills', limit: 7000, period: 'Monthly' },
  ];
  const now = new Date();
  const nextMonthly = (day) => {
    let d = new Date(now.getFullYear(), now.getMonth(), day);
    if (!(d.getTime() > now.getTime())) d = new Date(now.getFullYear(), now.getMonth() + 1, day);
    return d.getTime();
  };
  const subscriptions = [
    { id: 1, name: 'Netflix', fromName: 'Netflix Inc.', toName: 'Rajdeep', amount: 649, cycle: 'Monthly', nextDue: nextMonthly(5), issued: now.getTime() - 25 * 864e5, isPaid: true, color: '#E50914', icon: 'film', items: [{ description: 'Premium 4K plan', hours: 1, ppu: 649 }] },
    { id: 2, name: 'Spotify', fromName: 'Spotify AB', toName: 'Rajdeep', amount: 119, cycle: 'Monthly', nextDue: nextMonthly(12), issued: now.getTime() - 18 * 864e5, isPaid: true, color: '#1DB954', icon: 'sparkle', items: [{ description: 'Premium Individual', hours: 1, ppu: 119 }] },
    { id: 3, name: 'House Rent', fromName: 'Landlord — Mr. Verma', toName: 'Rajdeep', amount: 18000, cycle: 'Monthly', nextDue: nextMonthly(1), issued: now.getTime() - 3 * 864e5, isPaid: false, color: '#8A5CF6', icon: 'home', items: [{ description: 'Rent — monthly', hours: 1, ppu: 18000 }] },
    { id: 4, name: 'Studio Sphere BV', fromName: 'Studio Sphere BV', toName: 'Dip Inc.', amount: 13310, cycle: 'Invoice IN-001', nextDue: now.getTime() + 14 * 864e5, issued: now.getTime() - 16 * 864e5, isPaid: false, color: '#FF7A1A', icon: 'receipt', items: [
      { description: 'Discovery', hours: 12, ppu: 180 },
      { description: 'Identity', hours: 36, ppu: 190 },
      { description: 'Guidelines', hours: 10, ppu: 180 },
    ] },
  ];

  // 45 days of deterministic demo activity (heatmap / streaks / charts)
  const rnd = mulberry32(42);
  const today = dayStart(now);
  const cats = ['food', 'transport', 'shopping', 'groceries', 'bills', 'entertainment', 'health'];
  const notes = {
    food: ['Lunch at café', 'Dinner out', 'Coffee & snacks', 'Street food'],
    transport: ['Uber ride', 'Metro recharge', 'Fuel'],
    shopping: ['Amazon order', 'New clothes', 'Gadget'],
    groceries: ['BigBasket', 'Local kirana', 'Fruits & veg'],
    bills: ['Electricity', 'Wi-Fi recharge', 'Mobile recharge'],
    entertainment: ['Movie tickets', 'Game', 'Concert'],
    health: ['Pharmacy', 'Gym', 'Doctor visit'],
  };
  const tagPool = ['Work', 'Personal', 'Fun', 'Urgent'];
  const people = ['Aarav', 'Priya', 'Rahul', 'Sara'];
  const amountFor = (cat) => {
    switch (cat) {
      case 'food': return 120 + rnd() * 780;
      case 'transport': return 40 + rnd() * 360;
      case 'shopping': return 499 + rnd() * 3500;
      case 'groceries': return 250 + rnd() * 1250;
      case 'bills': return 199 + rnd() * 2300;
      case 'entertainment': return 150 + rnd() * 1050;
      case 'health': return 200 + rnd() * 4800;
      default: return 100 + rnd() * 900;
    }
  };
  const transactions = [];
  let id = 1;
  for (let d = 44; d >= 0; d--) {
    const day = today - d * 864e5;
    let count = rnd() < 1 / 6 ? 0 : 1 + Math.floor(rnd() * 3);
    if (d === 0) count = 2;
    if (d === 3 || d === 11) count = 0;
    for (let i = 0; i < count; i++) {
      const cat = cats[Math.floor(rnd() * cats.length)];
      const note = notes[cat][Math.floor(rnd() * notes[cat].length)];
      const tags = rnd() < 1 / 3 ? [tagPool[Math.floor(rnd() * tagPool.length)]] : [];
      const split = rnd() < 1 / 8 ? [people[Math.floor(rnd() * people.length)], people[Math.floor(rnd() * people.length)]] : [];
      const dt = new Date(day + (8 + Math.floor(rnd() * 12)) * 36e5 + Math.floor(rnd() * 60) * 6e4);
      transactions.push({ id: id++, amount: Math.round(amountFor(cat) * 100) / 100, type: 'expense', category: cat, note, accountId: 1 + Math.floor(rnd() * 3), tags, splitWith: split, date: dt.getTime() });
    }
  }
  transactions.push({ id: id++, amount: 85000, type: 'income', category: 'salary', note: 'Salary — monthly', accountId: 1, tags: ['Work'], splitWith: [], date: today - 30 * 864e5 + 9 * 36e5 });
  transactions.sort((a, b) => b.date - a.date);

  return { accounts, transactions, budgets, subscriptions, hideBalance: false, nextId: id };
}

/* ---------------- analytics (mirrors AppProvider) ---------------- */
function activityByDay() {
  const map = {};
  for (const t of state.transactions) {
    if (t.type === 'transfer') continue;
    const d = dayStart(new Date(t.date));
    map[d] = (map[d] || 0) + 1;
  }
  return map;
}
function loggedDaysLast31() {
  const map = activityByDay();
  const today = dayStart(new Date());
  let c = 0;
  for (let i = 0; i < 31; i++) if ((map[today - i * 864e5] || 0) > 0) c++;
  return c;
}
const consistencyPercent = () => (loggedDaysLast31() / 31) * 100;
function currentStreak() {
  const map = activityByDay();
  const today = dayStart(new Date());
  let d = (map[today] || 0) > 0 ? today : today - 864e5;
  if ((map[d] || 0) === 0) return 0;
  let s = 0;
  while ((map[d] || 0) > 0) { s++; d -= 864e5; }
  return s;
}
function longestStreakInfo() {
  const map = activityByDay();
  const days = Object.keys(map).map(Number).sort((a, b) => a - b);
  let best = 0, cur = 0, prev = null, bestEnd = null;
  for (const d of days) {
    cur = prev !== null && d - prev === 864e5 ? cur + 1 : 1;
    if (cur > best) { best = cur; bestEnd = d; }
    prev = d;
  }
  if (!bestEnd) return { best: 0, range: '' };
  const start = bestEnd - (best - 1) * 864e5;
  return { best, range: dfMD.format(new Date(start)) + ' - ' + dfMDY.format(new Date(bestEnd)) };
}
function last7DaysSpending() {
  const map = {};
  for (const t of state.transactions) {
    if (t.type !== 'expense') continue;
    const d = dayStart(new Date(t.date));
    map[d] = (map[d] || 0) + t.amount;
  }
  const today = dayStart(new Date());
  const out = [];
  for (let i = 0; i < 7; i++) out.push(map[today - (6 - i) * 864e5] || 0);
  return out;
}
function mondayOf(ms) {
  const d = new Date(dayStart(new Date(ms)));
  return dayStart(new Date(d.getFullYear(), d.getMonth(), d.getDate() - (d.getDay() === 0 ? 6 : d.getDay() - 1)));
}
function weekSpend(weekStart) {
  const end = weekStart + 7 * 864e5;
  let s = 0;
  for (const t of state.transactions) {
    if (t.type !== 'expense') continue;
    const d = dayStart(new Date(t.date));
    if (d >= weekStart && d < end) s += t.amount;
  }
  return s;
}
const thisWeekSpend = () => weekSpend(mondayOf(Date.now()));
const lastWeekSpend = () => weekSpend(mondayOf(Date.now()) - 7 * 864e5);
function weeklyChangePercent() {
  const lw = lastWeekSpend();
  if (lw <= 0) return 0;
  return ((thisWeekSpend() - lw) / lw) * 100;
}
function categoryTotalsThisMonth() {
  const now = new Date();
  const map = {};
  for (const t of state.transactions) {
    if (t.type !== 'expense') continue;
    const d = new Date(t.date);
    if (d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth()) {
      map[t.category] = (map[t.category] || 0) + t.amount;
    }
  }
  return map;
}
const budgetSpent = (key) => categoryTotalsThisMonth()[key] || 0;
function topCategoryThisWeek() {
  const monday = mondayOf(Date.now());
  const end = monday + 7 * 864e5;
  const map = {};
  for (const t of state.transactions) {
    if (t.type !== 'expense') continue;
    const d = dayStart(new Date(t.date));
    if (d >= monday && d < end) map[t.category] = (map[t.category] || 0) + t.amount;
  }
  let bestKey = 'other', bestVal = -1;
  for (const k of Object.keys(map)) if (map[k] > bestVal) { bestVal = map[k]; bestKey = k; }
  return { key: bestKey, value: Math.max(0, bestVal) };
}
function biaInsight() {
  const pct = consistencyPercent().toFixed(0);
  const logged = loggedDaysLast31();
  const change = weeklyChangePercent();
  const dir = change <= 0 ? 'down' : 'up';
  const top = CATS[topCategoryThisWeek().key].label;
  const ls = longestStreakInfo();
  const cs = currentStreak();
  const gap = ls.best - cs;
  const streakLine = gap > 0
    ? gap + ' day' + (gap === 1 ? '' : 's') + ' to beat your best streak of ' + ls.best + '.'
    : 'You are at your best streak — keep it alive.';
  return 'You logged on ' + logged + ' of the last 31 days (' + pct + '% consistency). ' +
    'This week you spent ' + fmtShort(thisWeekSpend()) + ' — ' + Math.abs(change).toFixed(0) + '% ' + dir +
    ' vs last week, led by ' + top + '. On weeks you log consistently, discretionary spending trends down. ' + streakLine;
}
const totalBalance = () => state.accounts.reduce((s, a) => s + a.balance, 0);
function todayTransactions() {
  const today = dayStart(new Date());
  return state.transactions.filter((t) => dayStart(new Date(t.date)) === today);
}

/* ---------------- mutations ---------------- */
function addTransaction(t) {
  t.id = state.nextId++;
  state.transactions.unshift(t);
  const a = state.accounts.find((x) => x.id === t.accountId);
  if (a) a.balance += t.type === 'income' ? t.amount : -t.amount;
  save();
}
function markSubscriptionPaid(s) {
  s.isPaid = true;
  const subtotal = s.items.reduce((x, i) => x + i.hours * i.ppu, 0);
  const total = subtotal * 1.21;
  addTransaction({
    amount: total > 0 ? total : s.amount,
    type: 'expense', category: 'bills', note: s.name + ' — paid',
    accountId: state.accounts[0].id, tags: ['Bills'], splitWith: [], date: Date.now(),
  });
}

/* ---------------- snackbar ---------------- */
let snackTimer = null;
function snack(msg) {
  const el = $('#snackbar');
  el.textContent = msg;
  el.classList.remove('hidden');
  requestAnimationFrame(() => el.classList.add('show'));
  clearTimeout(snackTimer);
  snackTimer = setTimeout(() => {
    el.classList.remove('show');
    setTimeout(() => el.classList.add('hidden'), 300);
  }, 2200);
}

/* ---------------- sheet / modal plumbing ---------------- */
const overlay = () => $('#overlay');
const sheetRoot = () => $('#sheet-root');
function openSheet(html, frosted) {
  const ov = overlay();
  ov.classList.remove('hidden');
  ov.classList.toggle('frosted', !!frosted);
  requestAnimationFrame(() => ov.classList.add('show'));
  sheetRoot().innerHTML = '<div class="sheet' + (frosted ? ' frosted' : '') + '">' + html + '</div>';
  const sh = $('.sheet', sheetRoot());
  requestAnimationFrame(() => requestAnimationFrame(() => sh.classList.add('show')));
  ov.onclick = closeSheet;
}
function closeSheet() {
  const ov = overlay();
  const sh = $('.sheet', sheetRoot());
  ov.classList.remove('show');
  if (sh) sh.classList.remove('show');
  setTimeout(() => {
    ov.classList.add('hidden');
    ov.classList.remove('frosted');
    sheetRoot().innerHTML = '';
  }, 320);
}

/* ---------------- zigzag receipt clip-path ---------------- */
function receiptClip(teeth) {
  teeth = teeth || 22;
  const pts = [];
  for (let i = 0; i <= teeth; i++) {
    const x = (i / teeth) * 100;
    pts.push(x.toFixed(3) + '% ' + (i % 2 === 0 ? '0px' : '6px'));
  }
  for (let i = teeth; i >= 0; i--) {
    const x = (i / teeth) * 100;
    pts.push(x.toFixed(3) + '% calc(100% - ' + (i % 2 === 0 ? '0px' : '6px') + ')');
  }
  return 'polygon(' + pts.join(',') + ')';
}

/* ---------------- dock ---------------- */
const TABS = [
  { id: 'home', label: 'Home', icon: 'home' },
  { id: 'stats', label: 'Stats', icon: 'chart' },
  { id: 'bills', label: 'Bills', icon: 'receipt' },
  { id: 'budgets', label: 'Budgets', icon: 'wallet' },
];
let currentTab = 'home';
function renderDock() {
  const dock = $('#dock');
  dock.innerHTML =
    '<button id="fab" aria-label="add">' + icon('add', 32) + '</button>' +
    '<div class="bar">' +
    TABS.slice(0, 2).map((t) => dockItem(t)).join('') +
    '<div class="gap"></div>' +
    TABS.slice(2).map((t) => dockItem(t)).join('') +
    '</div>';
  $('#fab').onclick = openAddSheet;
}
function dockItem(t) {
  const on = currentTab === t.id;
  return '<button class="item' + (on ? ' active' : '') + '" data-tab="' + t.id + '">' + icon(t.icon, 24) + '<span>' + t.label + '</span></button>';
}
function bindDock() {
  $('#dock').addEventListener('click', (e) => {
    const b = e.target.closest('[data-tab]');
    if (!b) return;
    currentTab = b.dataset.tab;
    render();
  });
}

/* ---------------- render root ---------------- */
function render() {
  renderDock();
  const view = $('#view');
  if (currentTab === 'home') { view.classList.remove('dark'); view.innerHTML = homeHtml(); bindHome(); }
  else if (currentTab === 'stats') { view.classList.add('dark'); view.innerHTML = statsHtml(); bindStats(); }
  else if (currentTab === 'bills') { view.classList.remove('dark'); view.innerHTML = billsHtml(); bindBills(); }
  else { view.classList.remove('dark'); view.innerHTML = budgetsHtml(); }
  view.scrollTop = 0;
}

/* ---------------- HOME ---------------- */
let showAll = false;
function homeHtml() {
  const change = weeklyChangePercent();
  const down = change <= 0;
  const items = showAll ? state.transactions.slice(0, 12) : (todayTransactions().length ? todayTransactions() : state.transactions.slice(0, 6));
  const bars = last7DaysSpending();
  const max = Math.max(1, ...bars);
  return '' +
  '<div class="hdr">' +
    '<div class="avatar">R</div>' +
    '<div class="who"><small>Good morning</small><b>' + esc(dfMY.format(new Date())) + '</b></div>' +
    '<div class="spacer"></div>' +
    '<button class="neo-btn" id="bell">' + icon('bell', 21) + '</button>' +
  '</div>' +
  '<div class="neo balance">' +
    '<div class="row"><span class="label">Total Balance</span><div class="spacer" style="flex:1"></div>' +
    '<button class="neo-btn" id="eye" style="width:36px;height:36px">' + icon(state.hideBalance ? 'eyeOff' : 'eye', 18) + '</button></div>' +
    '<div class="amount">' + (state.hideBalance ? '₹ ••••••' : esc(fmtShort(totalBalance()))) + '</div>' +
    '<div class="row">' +
      '<span class="chip ' + (down ? 'good' : 'bad') + '">' + icon(down ? 'arrowDown' : 'arrowUp', 13) + Math.abs(change).toFixed(1) + '% this week</span>' +
      '<div class="minibars">' + bars.map((b) => '<i style="height:' + (b <= 0 ? 4 : Math.max(6, (b / max) * 42)) + 'px"></i>').join('') + '</div>' +
    '</div>' +
  '</div>' +
  '<div class="sec"><h2>Accounts</h2><button class="act">Manage</button></div>' +
  '<div class="carousel-wrap"><div class="carousel" id="carousel">' +
    state.accounts.map((a) =>
      '<div class="slide"><div class="card3d" style="--c1:' + a.c1 + ';--c2:' + a.c2 + '">' +
        '<div class="wcard-ghost" style="--c1:' + a.c1 + ';--c2:' + a.c2 + '"></div>' +
        '<div class="wcard" style="--c1:' + a.c1 + ';--c2:' + a.c2 + '">' +
          '<div class="top"><span class="type">' + a.type.toUpperCase() + '</span><span class="chipicon">' + icon('memory', 16) + '</span></div>' +
          '<div class="name">' + esc(a.name) + '</div>' +
          '<div class="num">' + esc(a.maskedNumber) + '</div>' +
          '<div class="bottom"><div class="bal"><small>BALANCE</small><b>' + esc(fmtShort(a.balance)) + '</b></div>' +
          '<span class="pill">' + (a.type === 'bank' ? 'Bank' : a.type === 'card' ? 'Credit Card' : 'Cash') + '</span></div>' +
        '</div>' +
      '</div></div>'
    ).join('') +
  '</div></div>' +
  '<div class="sec"><h2>' + (showAll ? 'Recent activity' : 'Today’s activity') + '</h2><button class="act" id="seeall">' + (showAll ? 'Today' : 'See all') + '</button></div>' +
  '<div class="receipt-wrap"><div class="receipt" id="receipt" style="clip-path:' + receiptClip() + '">' +
    (items.length === 0
      ? '<div class="empty">No transactions yet — tap + to add one</div>'
      : items.map((t, i) => txRowHtml(t) + (i < items.length - 1 ? '<div class="dash"></div>' : '')).join('')) +
  '</div></div>';
}
function txRowHtml(t) {
  const c = CATS[t.category] || CATS.other;
  const isIncome = t.type === 'income';
  return '<div class="txrow">' +
    '<div class="catdisc" style="background:linear-gradient(135deg,' + c.c1 + ',' + c.c2 + ')">' + icon(c.icon, 22) + '</div>' +
    '<div class="mid"><div class="t">' + esc(t.note || c.label) + '</div>' +
      '<div class="sub">' +
        (t.tags.length ? '<span class="tag" style="background:' + c.c1 + '24;color:' + c.c1 + '">' + esc(t.tags[0].toUpperCase()) + '</span>' : '') +
        t.splitWith.slice(0, 3).map((n) => '<span class="pav">' + esc(n[0]) + '</span>').join('') +
      '</div></div>' +
    '<div class="amt' + (isIncome ? ' in' : '') + '">' + (isIncome ? '+' : '−') + esc(fmtShort(t.amount)) + '</div>' +
  '</div>';
}
function bindHome() {
  $('#eye').onclick = () => { state.hideBalance = !state.hideBalance; save(); render(); };
  $('#bell').onclick = () => snack('No new notifications');
  const sa = $('#seeall'); if (sa) sa.onclick = () => { showAll = !showAll; render(); };
  // 3D tilt + parallax on the wallet carousel
  const c = $('#carousel');
  if (!c) return;
  const slides = Array.from(c.querySelectorAll('.slide'));
  const upd = () => {
    const r = c.getBoundingClientRect();
    const mid = r.left + r.width / 2;
    for (const s of slides) {
      const sr = s.getBoundingClientRect();
      const off = (sr.left + sr.width / 2 - mid) / r.width;
      const t = Math.max(-1, Math.min(1, off));
      const card = $('.card3d', s);
      card.style.transform = 'translateX(' + (off * 26).toFixed(1) + 'px) rotateY(' + (t * 38).toFixed(2) + 'deg) rotateX(' + (t * -8).toFixed(2) + 'deg) scale(' + (1 - Math.abs(t) * 0.05).toFixed(3) + ')';
      s.style.opacity = String(1 - Math.abs(t) * 0.25);
    }
  };
  c.addEventListener('scroll', () => requestAnimationFrame(upd), { passive: true });
  window.addEventListener('resize', upd);
  setTimeout(upd, 60);
}

/* ---------------- STATS (dark) ---------------- */
function hmColor(n) {
  if (n <= 0) return '#1B2130';
  if (n <= 2) return '#155E9E';
  if (n <= 4) return '#1E88E5';
  if (n <= 6) return '#42A5F5';
  return '#90CAF9';
}
function statsHtml() {
  const map = activityByDay();
  const today = dayStart(new Date());
  const monday = today - ((new Date(today).getDay() === 0 ? 6 : new Date(today).getDay() - 1)) * 864e5;
  const start = monday - 19 * 7 * 864e5;
  const weeks = 20;
  let cols = '';
  for (let w = 0; w < weeks; w++) {
    let cells = '';
    for (let d = 0; d < 7; d++) {
      const date = start + (w * 7 + d) * 864e5;
      const future = date > today;
      const n = future ? -1 : (map[date] || 0);
      cells += '<div class="hm-cell" style="background:' + (future ? '#12161F' : hmColor(n)) + '"></div>';
    }
    cols += '<div class="hm-col">' + cells + '</div>';
  }
  const labels = ['M', '', 'W', '', 'F', '', 'S'].map((l) => '<span>' + l + '</span>').join('');
  const bars = last7DaysSpending();
  const max = Math.max(1, ...bars);
  const dayL = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const cs = currentStreak();
  const ls = longestStreakInfo();
  return '' +
  '<div class="page-title" style="display:flex;align-items:center">' +
    '<div><h1 style="color:var(--dark-ink)">Statistics</h1><p>' + esc(dfMY.format(new Date())) + ' • ' + loggedDaysLast31() + '/31 days logged</p></div>' +
    '<div style="margin-left:auto;width:44px;height:44px;border-radius:50%;background:var(--dark-card);border:1px solid var(--dark-line);display:flex;align-items:center;justify-content:center;color:var(--dark-soft)">' + icon('calendar', 20) + '</div>' +
  '</div>' +
  '<div style="height:16px"></div>' +
  '<div class="dcard"><h4>Consistency ' + icon('help', 15) + '<span class="r">' + icon('refresh', 18) + '</span></h4>' +
    '<div class="big">' + consistencyPercent().toFixed(0) + '%</div>' +
    '<div class="heatmap"><div class="hm-labels">' + labels + '</div>' + cols + '</div>' +
    '<div class="legend">Less' + [0, 2, 4, 6, 8].map((n) => '<i style="background:' + hmColor(n) + '"></i>').join('') + 'More</div>' +
  '</div>' +
  '<div class="streakrow">' +
    '<div class="dcard"><h4 style="color:var(--dark-soft);font-size:12px;font-weight:600">Current Streak</h4>' +
      '<div style="display:flex;align-items:center;gap:6px;margin-top:10px"><span class="flame">' + icon('flame', 26) + '</span><span class="num">' + cs + '</span><span class="unit">days</span></div>' +
      '<div class="dots">' + Array.from({ length: 6 }, () => '<i></i>').join('') + '</div></div>' +
    '<div class="dcard"><h4 style="color:var(--dark-soft);font-size:12px;font-weight:600">Longest Streak</h4>' +
      '<div style="display:flex;align-items:center;gap:6px;margin-top:10px"><span class="flame">' + icon('flame', 26) + '</span><span class="num">' + ls.best + '</span><span class="unit">days</span></div>' +
      '<div class="range">' + esc(ls.range) + '</div></div>' +
  '</div>' +
  '<div class="dcard"><h4>Spending — last 7 days</h4><div class="weekbars">' +
    bars.map((b, i) => '<div class="wb"><i style="height:' + (b <= 0 ? 4 : Math.max(6, (b / max) * 118)) + 'px"></i><span>' + dayL[i] + '</span></div>').join('') +
  '</div></div>' +
  '<div class="bia"><h4>' + icon('sparkle', 20) + 'Bia Analysis</h4><p>' + esc(biaInsight()) + '</p></div>';
}
function bindStats() { /* static render */ }

/* ---------------- BILLS ---------------- */
function billsHtml() {
  const monthly = state.subscriptions.filter((s) => s.cycle === 'Monthly').reduce((s, x) => s + x.amount, 0);
  const unpaid = state.subscriptions.filter((s) => !s.isPaid).length;
  return '' +
  '<div class="page-title"><h1>Bills & Subscriptions</h1><p>' + unpaid + ' pending payment' + (unpaid === 1 ? '' : 's') + '</p></div>' +
  '<div class="neo sumcard"><div class="l"><small>Monthly recurring</small><b>' + esc(fmtShort(monthly)) + '</b></div><span class="count">' + state.subscriptions.length + ' active</span></div>' +
  '<div class="sec"><h2>All bills</h2></div>' +
  state.subscriptions.map((s) =>
    '<div class="neo subcard" data-id="' + s.id + '">' +
      '<div class="ic" style="background:' + s.color + '26;color:' + s.color + '">' + icon(s.icon, 24) + '</div>' +
      '<div class="mid"><div class="n">' + esc(s.name) + '</div><div class="d">' + esc(s.cycle) + ' • due ' + esc(fmtDay(s.nextDue)) + '</div></div>' +
      '<div class="right"><div class="a">' + esc(fmtShort(s.amount)) + '</div><span class="status ' + (s.isPaid ? 'paid' : 'due') + '">' + (s.isPaid ? 'PAID' : 'DUE') + '</span></div>' +
    '</div>'
  ).join('');
}
function bindBills() {
  document.querySelectorAll('.subcard').forEach((el) => {
    el.onclick = () => {
      const s = state.subscriptions.find((x) => x.id === Number(el.dataset.id));
      if (!s) return;
      if (s.isPaid) { snack(s.name + ' is already paid'); return; }
      openInvoice(s);
    };
  });
}

/* ---------------- invoice (frosted glass) ---------------- */
function openInvoice(s) {
  const subtotal = s.items.reduce((x, i) => x + i.hours * i.ppu, 0);
  const vat = subtotal * 0.21;
  const total = subtotal + vat;
  const daysIn = Math.max(0, Math.round((s.nextDue - Date.now()) / 864e5));
  const rows = s.items.map((i) =>
    '<tr><td>' + esc(i.description) + '</td><td>' + i.hours + '</td><td>' + esc(fmtShort(i.ppu)) + '</td><td class="r">' + esc(fmtShort(i.hours * i.ppu)) + '</td></tr>'
  ).join('');
  openSheet(
    '<div class="grab"></div>' +
    '<div class="inv-head"><span class="inv-id">' + esc(s.cycle) + '</span><span class="ic" style="background:' + s.color + '26;color:' + s.color + '">' + icon(s.icon, 22) + '</span></div>' +
    '<div class="receipt-wrap" style="margin:0"><div class="receipt" style="clip-path:' + receiptClip() + ';padding:18px">' +
      '<div class="kv"><div class="k"><small>ISSUED</small><b>' + esc(fmtDayFull(s.issued)) + '</b><span>14d net</span></div>' +
      '<div class="k" style="text-align:right"><small>DUE</small><b>' + esc(fmtDayFull(s.nextDue)) + '</b><span>Auto-reminder</span></div></div>' +
      '<div style="height:14px"></div>' +
      '<table class="inv-table"><thead><tr><th>DESCRIPTION</th><th>HRS</th><th>PPU</th><th class="r">AMOUNT</th></tr></thead><tbody>' + rows + '</tbody></table>' +
      '<div class="dash" style="margin:8px 0"></div>' +
      '<div class="inv-sum"><span>SUBTOTAL</span><b>' + esc(fmtShort(subtotal)) + '</b></div>' +
      '<div class="inv-sum"><span>VAT 21%</span><b>' + esc(fmtShort(vat)) + '</b></div>' +
    '</div></div>' +
    '<div class="partybox"><div class="fromto">' +
      '<div class="p"><small>FROM</small><b>' + esc(s.fromName) + '</b></div>' +
      '<span style="color:var(--ink-soft)">' + icon('swap', 18) + '</span>' +
      '<div class="p" style="margin-left:auto;text-align:right"><small>FOR</small><b>' + esc(s.toName) + '</b></div>' +
    '</div>' +
    '<div class="total-row"><div class="t"><small>TOTAL DUE</small><b>' + esc(fmtShort(total)) + '</b></div>' +
    '<div class="due"><small>DUE</small><b>' + esc(fmtDay(s.nextDue)) + '</b><br><span>in ' + daysIn + ' days</span></div></div></div>' +
    '<button class="btn-dark" id="paybtn">' + icon('check', 20) + 'Approve &amp; Pay</button>',
    true
  );
  $('#paybtn').onclick = () => {
    markSubscriptionPaid(s);
    closeSheet();
    render();
    snack(s.name + ' paid — ' + fmtShort(total));
  };
}

/* ---------------- BUDGETS ---------------- */
function budgetsHtml() {
  const goalTarget = 120000, goalSaved = 54300;
  const goalPct = Math.min(1, goalSaved / goalTarget);
  const cards = state.budgets.map((b) => {
    const c = CATS[b.categoryKey] || CATS.other;
    const spent = budgetSpent(b.categoryKey);
    const p = b.limit <= 0 ? 0 : spent / b.limit;
    const alert = p >= 0.9, warn = p >= 0.75;
    const col = alert ? ['#E5484D', '#FF8A80'] : warn ? ['#FF7A1A', '#FFB020'] : ['#2FBF71', '#C6F24E'];
    return '<div class="neo bcard">' +
      '<div class="top"><div class="catdisc" style="width:44px;height:44px;flex-basis:44px;background:linear-gradient(135deg,' + c.c1 + ',' + c.c2 + ')">' + icon(c.icon, 21) + '</div>' +
      '<div class="mid"><div class="n">' + esc(c.label) + '</div><div class="s">' + esc(fmtShort(spent)) + ' of ' + esc(fmtShort(b.limit)) + '</div></div>' +
      '<div class="p' + (alert ? ' alert' : '') + '">' + Math.min(999, Math.round(p * 100)) + '%</div></div>' +
      '<div class="btrack"><div class="bfill" style="width:' + Math.min(100, p * 100).toFixed(1) + '%;background:linear-gradient(90deg,' + col[0] + ',' + col[1] + ')"></div></div>' +
      (alert ? '<div class="balert">' + icon('warn', 16) + '90% reached — slow down on ' + esc(c.label.toLowerCase()) + '</div>' : '') +
    '</div>';
  }).join('');
  return '' +
  '<div class="page-title"><h1>Budgets & Goals</h1><p>' + esc(dfMY.format(new Date())) + '</p></div>' +
  '<div class="goal"><div class="top">' + icon('rocket', 20) + 'Savings Goal<span>New MacBook Pro</span></div>' +
    '<div class="amt">' + esc(fmtShort(goalSaved)) + ' of ' + esc(fmtShort(goalTarget)) + '</div>' +
    '<div class="track"><div class="fill" style="width:' + (goalPct * 100).toFixed(0) + '%"></div></div>' +
    '<div class="pct">' + Math.round(goalPct * 100) + '% saved — on track</div></div>' +
  '<div class="sec"><h2>Monthly budgets</h2></div>' + cards;
}

/* ---------------- ADD TRANSACTION sheet ---------------- */
const TAG_OPTIONS = ['Work', 'Personal', 'Fun', 'Urgent'];
const CONTACTS = ['Aarav', 'Priya', 'Rahul', 'Sara'];
function openAddSheet() {
  const form = { type: 'expense', category: 'food', accountId: state.accounts[0].id, tags: new Set(), split: false, people: new Set(), amount: '', note: '' };
  const catsFor = () => (form.type === 'income' ? INCOME_CATS : EXPENSE_CATS);

  openSheet(
    '<div class="grab"></div>' +
    '<h3>New transaction <button class="x" id="closex">' + icon('close', 18) + '</button></h3>' +
    '<div class="seg" id="seg"></div>' +
    '<div class="amount-wrap"><span class="cur">₹</span><input id="amount-input" inputmode="decimal" placeholder="0" autocomplete="off"></div>' +
    '<div class="err" id="err"></div>' +
    '<div class="flabel">CATEGORY</div><div class="catgrid" id="catgrid"></div>' +
    '<div class="flabel">ACCOUNT</div><div class="chips" id="acctchips"></div>' +
    '<div class="flabel">NOTE</div><input class="note-input" id="note" placeholder="Add a note…">' +
    '<div class="flabel">TAGS</div><div class="chips" id="tagchips"></div>' +
    '<div class="splitbox"><span style="color:var(--ink-soft)">' + icon('users', 22) + '</span><span class="lbl">Split this bill</span>' +
      '<label class="switch"><input type="checkbox" id="splitsw"><span class="tr"></span></label></div>' +
    '<div id="splitbox" style="display:none"><div class="flabel">SPLIT WITH</div><div class="chips" id="people"></div><div class="perperson" id="perperson"></div></div>' +
    '<button class="btn-primary" id="savebtn">Add Transaction</button>'
  );

  $('#closex').onclick = closeSheet;

  // segmented control
  const seg = $('#seg');
  const segBtns = {};
  ['expense', 'income', 'transfer'].forEach((t) => {
    const b = document.createElement('button');
    const col = t === 'expense' ? '#E5484D' : t === 'income' ? '#2FBF71' : '#3E9BFF';
    const ic = t === 'expense' ? 'arrowDown' : t === 'income' ? 'arrowUp' : 'swap';
    b.innerHTML = icon(ic, 16) + (t[0].toUpperCase() + t.slice(1));
    b.onclick = () => {
      form.type = t;
      form.category = catsFor()[0];
      paintSeg(); paintCats();
    };
    b.dataset.t = t;
    b._col = col;
    seg.appendChild(b);
    segBtns[t] = b;
  });
  function paintSeg() {
    for (const k of Object.keys(segBtns)) {
      const on = form.type === k;
      segBtns[k].classList.toggle('on', on);
      segBtns[k].style.background = on ? segBtns[k]._col : '';
      segBtns[k].style.color = on ? '#fff' : '';
    }
  }

  // category grid
  const grid = $('#catgrid');
  function paintCats() {
    grid.innerHTML = '';
    for (const key of catsFor()) {
      const c = CATS[key];
      const b = document.createElement('button');
      b.className = 'c' + (form.category === key ? ' on' : '');
      b.style.color = c.c1;
      b.innerHTML = '<span class="disc" style="background:' + (form.category === key ? 'linear-gradient(135deg,' + c.c1 + ',' + c.c2 + ')' : c.c1 + '1F') + ';color:' + (form.category === key ? '#fff' : c.c1) + '">' + icon(c.icon, 24) + '</span><span>' + esc(c.label.split(' ')[0]) + '</span>';
      b.onclick = () => { form.category = key; paintCats(); };
      grid.appendChild(b);
    }
  }

  // accounts
  const ac = $('#acctchips');
  state.accounts.forEach((a) => {
    const b = document.createElement('button');
    b.className = 'chipbtn';
    b.textContent = a.name;
    b.onclick = () => { form.accountId = a.id; paintAccts(); };
    b._id = a.id;
    ac.appendChild(b);
  });
  function paintAccts() {
    Array.from(ac.children).forEach((b) => b.classList.toggle('on', b._id === form.accountId));
  }

  // tags
  const tc = $('#tagchips');
  TAG_OPTIONS.forEach((t) => {
    const b = document.createElement('button');
    b.className = 'chipbtn tag';
    b.textContent = t.toUpperCase();
    b.onclick = () => { form.tags.has(t) ? form.tags.delete(t) : form.tags.add(t); b.classList.toggle('on'); };
    tc.appendChild(b);
  });

  // split
  const sw = $('#splitsw');
  sw.onchange = () => {
    form.split = sw.checked;
    $('#splitbox').style.display = form.split ? 'block' : 'none';
    paintPer();
  };
  const pc = $('#people');
  CONTACTS.forEach((p) => {
    const b = document.createElement('button');
    b.className = 'chipbtn person';
    b.textContent = p;
    b.onclick = () => { form.people.has(p) ? form.people.delete(p) : form.people.add(p); b.classList.toggle('on'); paintPer(); };
    pc.appendChild(b);
  });
  function paintPer() {
    const amt = parseFloat(($('#amount-input').value || '').replace(/,/g, '')) || 0;
    const n = form.people.size;
    $('#perperson').textContent = (form.split && n > 0 && amt > 0)
      ? fmtMoney(amt / n, 0) + ' per person (' + n + ')'
      : '';
  }
  $('#amount-input').addEventListener('input', (e) => {
    form.amount = e.target.value;
    $('#err').textContent = '';
    paintPer();
  });
  $('#note').addEventListener('input', (e) => { form.note = e.target.value; });

  $('#savebtn').onclick = () => {
    const amount = parseFloat((form.amount || '').replace(/,/g, ''));
    if (!amount || amount <= 0) { $('#err').textContent = 'Enter an amount greater than zero'; return; }
    addTransaction({
      amount,
      type: form.type,
      category: form.category,
      note: form.note.trim(),
      accountId: form.accountId,
      tags: Array.from(form.tags),
      splitWith: form.split ? Array.from(form.people) : [],
      date: Date.now(),
    });
    closeSheet();
    render();
    const label = form.type[0].toUpperCase() + form.type.slice(1);
    snack(label + ' of ' + fmtShort(amount) + ' added');
  };

  paintSeg(); paintCats(); paintAccts(); paintPer();
  setTimeout(() => { const i = $('#amount-input'); if (i) i.focus(); }, 380);
}

/* ---------------- boot ---------------- */
load();
render();
bindDock();
