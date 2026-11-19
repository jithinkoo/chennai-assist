# Chennai Assist

A help desk and personal assistant website for anyone moving to, living in or
visiting Chennai. Built with Elixir, Phoenix LiveView and PostgreSQL.

## What it does

**For visitors**
- **Live chat** (`/chat`): enter name and email, then chat in real time with
  the admin. The private chat link is emailed to the visitor so they can come
  back later.
- **Ask a question** (`/ask`): post a question by topic; the answer is emailed
  back, and answers marked public are listed on the page (without name or email).
- **City guide** (`/guide`): articles on moving, rent and areas, autos and
  transport, weather, food, culture, people, politics, neighbourhoods and jobs.
  Eight starter articles are included in the seeds.
- **Photos** (`/photos`): a gallery of Chennai photographs.
- **Local voices** (`/interviews`): interviews with local people about their area.

**For the admin** (`/admin`, login at `/users/log_in`)
- Dashboard with live counts of unread chats and unanswered questions.
- Chat inbox: new chats and messages appear instantly; reply, close or re-open.
- Answer questions, choose whether each answer is public.
- Upload photos (drag and drop, up to 10 at a time).
- Write and edit guide articles and interviews (draft or published).

Public sign-up is disabled: only the admin account created by the seeds can log in.

## Run it locally

You need Elixir 1.15+ (tested on 1.17 / OTP 25) and PostgreSQL.

```bash
mix setup                       # deps, database, migrations, assets
ADMIN_EMAIL=you@example.com ADMIN_PASSWORD='a-long-password' mix run priv/repo/seeds.exs
ADMIN_EMAIL=you@example.com mix phx.server
```

Open http://localhost:4000. In development, sent emails appear at
http://localhost:4000/dev/mailbox.

Database settings for development are in `config/dev.exs` (default user
`postgres` / password `postgres`).

## Deploy to Render

The database runs on [Neon](https://neon.tech) (free Postgres); the app runs on
Render. The repo includes `render.yaml`, `build.sh` and `rel/overlays/bin/start`.

1. **Neon:** create a project (region: Singapore, closest to Chennai). On the
   dashboard click **Connect** and copy the connection string
   (`postgresql://...neon.tech/neondb?sslmode=require...`).
2. **Render:** **New → Blueprint**, pick this GitHub repo. It creates a web
   service named `city-assist` (address `city-assist.onrender.com` if the name is free).
3. When asked, fill in `DATABASE_URL` (the Neon string), `ADMIN_EMAIL` and
   `ADMIN_PASSWORD` (12+ characters). `BREVO_API_KEY` and `MAIL_FROM` are
   optional (for real emails). Click **Apply**.
4. Wait for the first deploy. On every start the app migrates the database,
   loads the starter articles and creates the admin if missing.
5. Log in at `https://<your-address>/users/log_in`.

SSL is switched on automatically for `*.neon.tech` hosts (override with
`DATABASE_SSL=true|false`).

Free-plan limits: the Render service sleeps after 15 minutes idle (first visit
then takes about a minute), and its disk is wiped on each deploy, so uploaded
photos disappear. For a real site use a paid instance with a persistent disk
mounted at `UPLOADS_DIR`. Neon's free database does not expire.

## Configuration

| Variable | Purpose |
| --- | --- |
| `ADMIN_EMAIL` | Receives emails about new chats and questions. Also used by the seeds to create the admin. |
| `ADMIN_PASSWORD` | Admin password used by the seeds (at least 12 characters). |
| `MAIL_FROM` | Sender address for outgoing email. |
| `UPLOADS_DIR` | Where uploaded photos are stored. Use a persistent disk in production. |
| `DATABASE_URL`, `SECRET_KEY_BASE`, `PHX_HOST` | Standard Phoenix production settings (`config/runtime.exs`). |

### Email in production

Development uses Swoosh's local mailbox. For real email, set an adapter in
`config/runtime.exs`, for example SMTP, Mailgun, Postmark or Brevo; see
https://hexdocs.pm/swoosh. Until then, emails are only logged.

### Photos in production

Photos are saved to disk and served at `/uploads/...`. On hosts with
ephemeral disks (Fly.io, Render, Gigalixir), mount a volume and set
`UPLOADS_DIR` to it, or switch to S3-compatible storage.

## Mobile app

A Flutter visitor app lives in [`mobile/`](mobile/README.md). It uses the JSON
API under `/api/v1` and the `chat:<token>` channel on `/socket`. GitHub Actions
builds an Android APK on every change to `mobile/`.

## Tests

```bash
mix test
```

## Writing guide articles

In the admin article editor, write plain text:
- a blank line starts a new paragraph;
- lines starting with `- ` become bullet points;
- a short line (no full stop) followed by text becomes a sub-heading.
