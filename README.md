# 📊 DA Internship LMS — Setup Guide
### KPITB 2026 · Get live in 15 minutes

---

## What You'll Have After Setup

```
hamzafarman00755.github.io/da-lms-kpitb
│
├── /                → Login page (admin + interns)
├── /admin/          → Your admin dashboard
└── /intern/course   → Intern course + tests
```

---

## STEP 1 — Create Your Supabase Database (5 min)

1. Go to **[supabase.com](https://supabase.com)**
2. Click **"Start your project"** → Sign in with GitHub
3. Click **"New project"**
   - Name: `da-lms-kpitb`
   - Database Password: choose a strong password (save it!)
   - Region: **Southeast Asia (Singapore)** ← closest to Pakistan
4. Wait ~2 minutes for it to set up
5. Go to **SQL Editor** (left sidebar) → **New Query**
6. Open the file `setup.sql` from this folder
7. **Copy all the text** and paste it into Supabase SQL Editor
8. Click **Run** (green button)
9. You should see "Success. No rows returned"

---

## STEP 2 — Get Your Supabase Keys (1 min)

1. In Supabase, go to **Project Settings** (gear icon, bottom left)
2. Click **API**
3. Copy two values:
   - **Project URL** (looks like `https://abcdefgh.supabase.co`)
   - **anon / public key** (long string starting with `eyJ...`)

---

## STEP 3 — Add Keys to the App (2 min)

Open each of these 3 files and replace the placeholder values at the TOP of the `<script>` section:

```
lms/index.html          → lines 2-3 of the script
lms/admin/index.html    → lines 2-3 of the script
lms/intern/course.html  → lines 2-3 of the script
```

Change:
```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL_HERE';
const SUPABASE_KEY = 'YOUR_SUPABASE_ANON_KEY_HERE';
```

To:
```javascript
const SUPABASE_URL = 'https://your-actual-project.supabase.co';
const SUPABASE_KEY = 'eyJyour-actual-anon-key...';
```

---

## STEP 4 — Create Your Admin Account (2 min)

1. Go to **Supabase Dashboard → Authentication → Users**
2. Click **"Add user"** → **"Create new user"**
3. Email: `hamzafarman00755@gmail.com`
4. Password: choose your admin password
5. Click **Create User**
6. Now go to **SQL Editor** and run this:

```sql
INSERT INTO public.profiles (id, full_name, role, batch)
SELECT id, 'Hamza Farman', 'admin', 'Admin'
FROM auth.users
WHERE email = 'hamzafarman00755@gmail.com'
ON CONFLICT (id) DO UPDATE SET role = 'admin';
```

---

## STEP 5 — Push to GitHub & Go Live (5 min)

### First time setup:
```bash
# In Terminal, navigate to the lms folder
cd /Users/hamza/Documents/KPITB/AL/lms

# Initialize git
git init
git add .
git commit -m "Initial LMS setup"

# Create repo on GitHub (go to github.com → New repository)
# Name it: da-lms-kpitb
# Keep it Public
# Don't initialize with README

# Then connect and push:
git remote add origin https://github.com/hamzafarman00755/da-lms-kpitb.git
git branch -M main
git push -u origin main
```

### Enable GitHub Pages:
1. Go to your GitHub repo → **Settings**
2. Click **Pages** (left sidebar)
3. Source: **Deploy from a branch**
4. Branch: **main**, folder: **/ (root)**
5. Click **Save**
6. Wait 2-3 minutes
7. Your site is live at: `https://hamzafarman00755.github.io/da-lms-kpitb`

---

## STEP 6 — Add Intern Accounts

1. Log in to your admin panel at the live URL
2. Go to **Interns** tab
3. Click **Create Intern**
4. Fill in: Name, Email, Temporary Password, Batch
5. Share the URL and their login credentials with the intern

---

## How to Update Content After Setup

### Update course content (lessons/text):
1. Edit `intern/course.html` locally
2. Run: `git add . && git commit -m "Update course content" && git push`
3. GitHub Pages auto-updates within 2 minutes

### Update/add questions:
1. Log in as admin
2. Go to **Questions** tab
3. Select the week
4. Edit any question and click Save
5. Changes are instant (saved to Supabase)

### Open a weekly test:
1. Log in as admin
2. Go to **Weekly Tests** tab
3. Click **Open Test** for the relevant week
4. Interns can now take it

---

## File Structure

```
lms/
├── index.html          ← Login page
├── config.js           ← (not used - keys are inline in each HTML)
├── setup.sql           ← Run once in Supabase
├── README.md           ← This file
├── admin/
│   └── index.html      ← Admin dashboard (all features)
└── intern/
    └── course.html     ← Intern course + tests + progress
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| Login fails | Check Supabase URL and key are pasted correctly |
| "Profile not found" | Run the admin profile SQL in Step 4 again |
| Intern can't see test | Open the test window in Admin → Weekly Tests tab |
| Site not loading | Check GitHub Pages is enabled in repo Settings |
| Questions not showing | Verify setup.sql ran successfully (check Supabase Table Editor → questions) |

---

## Need Help?
All data is in your Supabase dashboard at [supabase.com](https://supabase.com).
Go to **Table Editor** to see all tables, users, and scores directly.

---
*KPITB DA Internship LMS · Built with Supabase + GitHub Pages*
