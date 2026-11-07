# Raider Judging Bench · Brownell Talbot

A web app for judging VEX Robotics Competition events, using the Global Robotics Engineering Notebook Rubric (v2.0) and Team Interview Rubric (v1.0), with a Brownell Talbot "Portrait of a Graduate" coaching layer.

- Judges sign in with **their email** (a one-time link or 6-digit code, no passwords).
- Each judge keeps **their own scoresheet**. Everyone on the panel can read every sheet; only the owner of a sheet can change it.
- The **Judge Advisor** manages the judge list, teams, event settings, performance ranks and award decisions.
- The **Panel** tab shows every judge's scores side by side, the final averaged scores, and where judges disagree.

It is a static website (HTML + JavaScript) backed by a free [Supabase](https://supabase.com) project for sign-in and the shared database. Hosting the site costs nothing on Netlify, GitHub Pages, Vercel or Cloudflare Pages.

---

## What's in the folder

| File | What it is |
|---|---|
| `index.html` | The app |
| `config.js` | Your Supabase connection settings (you fill this in) |
| `vendor/supabase.js` | Supabase's browser library (v2.45.4), bundled so the site has no extra dependencies |
| `supabase/schema.sql` | Creates the database tables and the access rules |
| `assets/` | Brownell Talbot seal, favicon and home-screen icon |

## Try it right now (demo mode)

Open `index.html` in a browser. With `config.js` left blank, the app runs in **demo mode**: no sign-in, and scores stay in that browser. Click **Try it on this device**, then **Setup → Load example panel** to see the dashboard.

---

## Set up the live version (about 20 minutes)

### 1. Create the Supabase project
1. Sign up at [supabase.com](https://supabase.com) (the free plan is enough) and click **New project**. Pick a name like `bt-judging` and a strong database password (you won't need it in the app).
2. When the project is ready, go to **SQL Editor → New query**.
3. Open `supabase/schema.sql`, change `advisor@example.com` at the bottom to **your** email (the Judge Advisor), paste the whole file in, and click **Run**. You should see "Success". It's safe to run again later.

### 2. Connect the app
1. In Supabase go to **Project Settings → API** (also listed as "Data API").
2. Copy the **Project URL** and the **anon public** key into `config.js`:
   ```js
   window.BT_CONFIG = {
     supabaseUrl: "https://abcdefghijklm.supabase.co",
     supabaseAnonKey: "eyJhbGciOi...",
     eventName: "Brownell Talbot VEX Invitational"
   };
   ```
   The anon key is meant to be public. The access rules in `schema.sql` decide who can read or change anything, and anyone not on your judge list sees nothing.

### 3. Set up email sign-in
1. **Custom email sender (required for real judges).** Supabase's built-in email is for testing only: it sends to pre-approved addresses only, about 2 emails an hour. Go to **Authentication → Emails → SMTP Settings**, turn on **Enable Custom SMTP**, and enter the details from an email service. Good free options: [Resend](https://resend.com), [Brevo](https://www.brevo.com), [SendGrid](https://sendgrid.com), or a school Google Workspace / Microsoft 365 account with SMTP enabled. Use a sender like `judging@yourdomain.org`.
2. **Rate limit.** Under **Authentication → Rate Limits**, raise "emails per hour" to cover your panel (for example 60).
3. **Add the 6-digit code to the emails** (so judges on a different device than their email can type the code). Under **Authentication → Emails → Templates**, edit both **Confirm signup** and **Magic Link**, and add this line to each:
   ```html
   <p>Or enter this code on the judging site: <strong>{{ .Token }}</strong></p>
   ```
   (First-time judges get the "Confirm signup" email; returning judges get "Magic Link".)

### 4. Put the site on the web
Pick one:

- **Netlify Drop (easiest):** go to [app.netlify.com/drop](https://app.netlify.com/drop) and drag the whole `bt-judging-bench` folder onto the page. You get a link like `https://bt-judging.netlify.app` (you can rename it in Site settings).
- **GitHub Pages:** create a repository, upload the folder's contents, then **Settings → Pages → Deploy from branch → main / root**.
- **Vercel or Cloudflare Pages:** create a new project from the folder (no build step; output directory is the folder itself).
- **School web server:** upload the folder's contents to any web directory. It must be served over **https**.

### 5. Tell Supabase your site address
In **Authentication → URL Configuration**:
- **Site URL:** your site's address, e.g. `https://bt-judging.netlify.app`
- **Redirect URLs:** add the same address, plus `https://bt-judging.netlify.app/**` (or `/index.html` if you use a subfolder)

Without this, the sign-in links in the emails won't return judges to your site.

### 6. Sign in as Judge Advisor
Open your site, enter the email you put in `schema.sql`, and sign in with the link or code. You'll land on the Panel dashboard with **JA** next to your initials.

---

## Running an event

1. **Setup → Judges & access:** add each judge's name and email. Add a co-advisor by choosing the **Judge Advisor** role.
2. **Setup → Paste roster:** paste your team list (number, name, school per line). Set the event name, date and awards offered.
3. Invite judges. Adding a judge emails them a sign-in link and 6-digit code (uncheck "Email them a sign-in link now" to wait). In the **Sign-in email** column, **Send invite / Resend** emails a fresh link and code at any time, and **Email all who haven't joined** does everyone still waiting. Each row shows when the last email went out, or why it couldn't be sent. Judges can also request their own link on the site. Judges who haven't signed in yet show as **Invited** on the Panel tab.
4. Judges score in **Score** (notebook rubric, interview rubric, BT Lens, flags and notes). Everything saves as they tap.
5. Watch **Panel**: coverage, each judge's notebook and interview totals per team, final averages, and amber flags where judges disagree. Open a team to see every criterion by judge, plus judges' notes.
6. **Deliberate:** enter qualification and Skills ranks from the tournament software, review suggested winners, and record panel decisions.
7. After the event, turn off judges' access (uncheck **can sign in**) or remove them. Remove example data before your first real event.

**Exporting data:** in Supabase, **Table Editor → sheets / teams → Export to CSV** downloads everything.

## Who can do what

| | Judge | Judge Advisor | Not on the list |
|---|---|---|---|
| Sign in | ✓ | ✓ | Signs in, but sees "Not on this judging panel" and no data |
| Read teams, every scoresheet, dashboard | ✓ | ✓ | — |
| Score (own sheet only) | ✓ | ✓ | — |
| Change another judge's sheet | — | ✓ (cleanup only) | — |
| Teams, settings, ranks, award decisions, judge list | — | ✓ | — |

These rules are enforced by the database itself (Postgres row-level security in `schema.sql`), not just hidden in the page, so they hold even if someone edits the page in their browser.

## Troubleshooting

- **"Not on this judging panel":** the email must match exactly what's in Judges & access (case doesn't matter). Fix it there, then click **Check again**.
- **No email arrives:** check spam; make sure custom SMTP is on (step 3.1) and the rate limit is high enough. Supabase allows one new link per email every 60 seconds.
- **"Hourly email limit reached" in Setup:** custom SMTP is off, or the limit in **Authentication → Rate Limits** is too low. With custom SMTP off, Supabase's built-in email allows only 2 emails an hour for the whole site and only delivers to members of your Supabase organization, so judges won't get invites.
- **"The email server refused to send":** the SMTP username or password is wrong. For Gmail, use a 16-character app password; for Brevo, use the SMTP login and SMTP key from Brevo's SMTP page.
- **Link opens but doesn't sign in, or says it expired:** add your site address to Redirect URLs (step 5). Links work once and expire after an hour. Request a new one or use the 6-digit code.
- **Live updates paused banner:** the app retries on its own and reloads data when you return to the tab. Check that `schema.sql` ran fully (its last section turns on live updates).
- **Only demo mode shows:** `config.js` is blank or didn't upload with the site.

## Sources

[Competition Judging Overview](https://library.globalrobotics.org/hc/en-us/articles/50473477689364-Competition-Judging-Overview) ·
[Engineering Notebook Rubric v2.0](https://content.vexrobotics.com/kb/global-robotics/engineering-notebook-rubric-letter-v2.0.pdf) ·
[Team Interview Rubric v1.0](https://content.vexrobotics.com/kb/global-robotics/interview-rubric-1.0.pdf) ·
[Award Descriptions](https://library.globalrobotics.org/hc/en-us/articles/50474217598612-Award-Descriptions) ·
[Portrait of a BT Graduate](https://www.brownell.edu/about-us/mission-outcomes) ·
[Supabase passwordless email](https://supabase.com/docs/guides/auth/auth-email-passwordless)
