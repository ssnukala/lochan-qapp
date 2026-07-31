# lochan-qapp

Your first [Lochan](https://lochan.ai) application — a starter repo you clone,
rename, and author into.

Every command below has been run. If one fails for you, that is a bug in this
repo, not a step you did wrong — please open an issue.

## Quick start

```bash
git clone https://github.com/lochanor/lochan-qapp.git my-app
cd my-app

./bootstrap.sh          # generates .env with three fresh secrets
docker compose up -d
```

Then open <http://localhost:3000>, and check the backend is healthy:

```bash
curl http://localhost:8000/api/health
```

### What `bootstrap.sh` does

It copies `.env.example` to `.env` and fills in the three bootstrap secrets:

| Key | Generated with |
|---|---|
| `POSTGRES_PASSWORD` | `openssl rand -base64 24`, stripped of `/+=` so it is safe inside the database URL |
| `ENCRYPTION_KEY` | `openssl rand -base64 32`, translated to URL-safe base64 (Fernet requires this) |
| `JWT_SECRET` | `openssl rand -base64 32` |

It depends on `openssl` only — no Python needed on your machine. It writes
`.env` with mode `600`, and **refuses to overwrite an existing `.env`**, because
rotating `ENCRYPTION_KEY` makes anything already encrypted unreadable.

`.env` is gitignored. `.env.example` is not — that is the template you copy.

## Layout

```
packages/<name>/        your package — this is what you author
  mandi.json            package manifest (name, tier, entry points)
  backend/<module>/     your Python module
  data/embed-artifacts/ embedding artifacts, loaded relative to the module
data/                   app-level data
packages.json           which packages this app runs, and where they live
compose.yml             pulls the framework images from ghcr.io
.env.example            the template bootstrap.sh copies
```

**Why `packages/<name>/` is a real directory rather than a dependency:** a
`pip install` delivers only the Python distribution. It does not carry the
sibling `data/embed-artifacts/*.npz`, the `frontend/`, or the root
`mandi.json` — and the embedding artifacts are loaded on a path relative to
your module, so chat and search do not work without them. The unit that
travels is the working tree, so you clone it.

The path `packages/<name>/` maps one-to-one onto `/app/packages/<name>/` inside
the image. Your development tree and the image tree are the same shape, which
is why `packages.json` points at `./packages/<name>` rather than anywhere else.

## Adding a package

`packages/demo/` is a starting point — rename it, or delete it and author your
own alongside. Edit `packages.json` so `primary` names the package you want the
app to serve.

## Secrets beyond the bootstrap three

`.env` holds only the three values above. Everything else — LLM API keys, OAuth
credentials, SMTP passwords — belongs in LOCKBOX, encrypted at rest:

```bash
daksh secrets push <app> --key CLAUDE_API_KEY --value -
daksh secrets list <app>          # names only, never values
```

## Requirements

- Docker with Compose
- `openssl` (present on macOS, Linux, and Git Bash)
- `git`
