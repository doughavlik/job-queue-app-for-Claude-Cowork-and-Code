# Job Queue Manager (36074)

Mobile-first web app for managing Claude Cowork and Claude Code job queues, backed by Supabase.

All database objects use the `36074_` prefix to avoid conflicts with other apps in the same Supabase project.

## Setup

### 1. Supabase project

Use your existing **doughavlik's Project** — no new project needed.

### 2. Run the database schema

Open the Supabase **SQL Editor**, paste the contents of `setup.sql`, and click **Run**. The "destructive operations" warning is expected (due to `DROP TRIGGER IF EXISTS`) and is safe to dismiss — click **Run this query**.

This creates:
- Table: `36074_jobs`
- Index: `36074_jobs_queue_status_position`
- Trigger + function: `36074_jobs_updated_at` / `36074_update_updated_at`
- RLS policy: `36074_authenticated_full_access`

### 3. Create a user account

In Supabase → **Authentication** → **Users** → **Add user**, create a user with your email and a password. This is the account you'll use to log in to the app.

### 4. Configure the app

Open `index.html` and replace the two placeholder values near the top of the `<script>` block:

```js
const SUPABASE_URL      = 'YOUR_SUPABASE_URL';       // e.g. https://xxxx.supabase.co
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';  // "anon public" key
```

Both values are in Supabase → **Project Settings** → **API**.

### 5. Deploy

The app is a single static HTML file. Deploy to any free static host:

- **Netlify**: drag-and-drop the `job-queue-app/` folder at [app.netlify.com/drop](https://app.netlify.com/drop)
- **GitHub Pages**: push to a repo, enable Pages on the `main` branch
- **Vercel**: `vercel --prod` from this folder, or import the repo in the dashboard

---

## Claude Scheduled Tasks API

Scheduled tasks use the **service role key** (bypasses RLS). Find it in Supabase → **Project Settings** → **API** → `service_role` (secret).

Store it as an environment variable in each task's configuration — **never** commit it to source control.

### Read todo jobs

```
GET https://<project>.supabase.co/rest/v1/36074_jobs?queue=eq.cowork&status=eq.todo&order=position
Authorization: Bearer <service_role_key>
apikey: <service_role_key>
```

Change `cowork` to `code` for the Code queue.

### Mark a job done

```
PATCH https://<project>.supabase.co/rest/v1/36074_jobs?id=eq.<job-uuid>
Authorization: Bearer <service_role_key>
apikey: <service_role_key>
Content-Type: application/json
Prefer: return=minimal

{"status": "done"}
```

---

## Features

- Two queues: **Claude Cowork** and **Claude Code**
- Add, edit, delete jobs (markdown body)
- Toggle todo / done status
- Reorder with ▲ ▼ buttons
- Filter by todo / done / all
- Mobile-first, works in iPhone Safari (iOS 16+)
- Cmd+Enter / Ctrl+Enter to submit a new job
