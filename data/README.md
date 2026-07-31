# `data/` — runtime and seed data

Data that belongs to your app rather than to the framework image.

## Embedding artifacts

Lochan's chat and semantic search read their embedding artifacts from a
path **relative to the installed package module**, not from a global
location. Framework artifacts are baked into the base image; your app's
artifacts layer in on top from your package's own
`backend/<module>/data/embed-artifacts/<model>/…`.

If that directory is missing, chat and semantic search will not work — the
loader has nothing to read. Generate artifacts before building your app
image, not after.

> Embeddings are generated **locally**. Lochan requires no cloud LLM for
> embedding.

## Seed data

Demo and fixture data for `daksh seed-demo` lives here. Seeding **writes to
your database** — point `.env` at the right one first.
