// ─────────────────────────────────────────────
//  STEP 1: Paste your Supabase credentials here
//  Get them from: supabase.com → Project Settings → API
// ─────────────────────────────────────────────
const SUPABASE_URL  = 'https://mrkpydwmdyiwqtjikhvb.supabase.co';
const SUPABASE_KEY  = 'sb_publishable_yABcWZTw5N3nht8NQm0wRQ_H4cZgOf0';
const ADMIN_EMAIL   = 'hamzafarman00755@gmail.com';

// ─────────────────────────────────────────────
//  Supabase client (loaded via CDN in HTML)
// ─────────────────────────────────────────────
const _sb = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// ─────────────────────────────────────────────
//  Auth helpers
// ─────────────────────────────────────────────
async function getSession() {
  const { data: { session } } = await _sb.auth.getSession();
  return session;
}

async function getProfile(userId) {
  const { data } = await _sb.from('profiles').select('*').eq('id', userId).single();
  return data;
}

async function requireAuth(expectedRole) {
  const session = await getSession();
  if (!session) { window.location.href = '../index.html'; return null; }
  const profile = await getProfile(session.user.id);
  if (!profile) { window.location.href = '../index.html'; return null; }
  if (expectedRole && profile.role !== expectedRole) {
    window.location.href = profile.role === 'admin' ? '../admin/index.html' : '../intern/course.html';
    return null;
  }
  return { session, profile };
}

async function signOut() {
  await _sb.auth.signOut();
  window.location.href = '../index.html';
}

// ─────────────────────────────────────────────
//  Utility
// ─────────────────────────────────────────────
function grade(pct) {
  if (pct >= 85) return { label: 'A', color: '#fbbf24', badge: '🏆 Distinction' };
  if (pct >= 70) return { label: 'B', color: '#34d399', badge: '✅ Merit' };
  if (pct >= 60) return { label: 'C', color: '#38bdf8', badge: '✔️ Pass' };
  if (pct >= 50) return { label: 'D', color: '#fb923c', badge: '⚠️ Borderline' };
  return { label: 'F', color: '#f87171', badge: '❌ Fail' };
}

function fmtDate(ts) {
  return new Date(ts).toLocaleDateString('en-PK', { day:'2-digit', month:'short', year:'numeric' });
}

function showToast(msg, type = 'success') {
  const t = document.createElement('div');
  t.className = 'toast toast-' + type;
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => t.classList.add('show'), 10);
  setTimeout(() => { t.classList.remove('show'); setTimeout(() => t.remove(), 400); }, 3000);
}
