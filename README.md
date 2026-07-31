# lochan-qapp — your first Lochan app

Clone this repo, point it at your config, and bring the app up. The Lochan
runtime itself ships as a **container image**; this repo carries only the
*recipe* — a compose file, your environment, and the declaration of which
Lochan packages your app is composed from.

```bash
git clone https://github.com/ssnukala/lochan-qapp myapp
cd myapp
cp .env.example .env      # edit: DB credentials, ports, LOCHAN_LICENSE_KEY
docker compose up
```

## What is in here

| Path | What it is |
|---|---|
| `compose.yml` | Pulls the Lochan base images and wires your app |
| `.env.example` | Every setting the app needs — copy to `.env` and edit |
| `packages.json` | **Which Lochan packages your app is composed from** |
| `packages/` | Your own domain package(s) live here — see `packages/README.md` |
| `data/` | Runtime + seed data, incl. embedding artifacts — see `data/README.md` |

## Composing your app from packages

`packages.json` declares the package set. Each entry names an **image** to
pull; a `dev` path is for in-monorepo development only and is not used here.

```json
{
  "primary": "myapp",
  "packages": {
    "myapp":   { "image": "myapp:latest" },
    "grahaka": { "image": "ghcr.io/ssnukala/lochan-grahaka:latest" }
  }
}
```

> ## ⚠ Status — not yet working end-to-end
>
> This repo is public so the shape can be reviewed, **but the quickstart above
> does not work yet.** Three things are still in flight:
>
> - the Lochan base images are **not published** — `docker compose up` cannot
>   pull them yet
> - `daksh scaffold` does not currently run, so `packages/<name>/` must be
>   authored by hand
> - `daksh install` does not yet work from inside the image without a
>   development checkout
>
> Each is being fixed and walked from a clean clone before this notice is
> removed. **Until it is, treat every step here as unverified.**
