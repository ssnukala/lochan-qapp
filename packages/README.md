# `packages/` — your domain package(s)

Each subdirectory is one Lochan package, laid out **exactly as it appears
inside the image** at `/app/packages/<name>/`. That 1:1 correspondence is
deliberate: the path translation between your working tree and the running
container is the identity map, so there is no tier logic and no `src/`
segment to reconcile.

```
packages/<name>/
├── mandi.json              # tier: "domain" — the package manifest
└── backend/<module>/       # your Python module
    ├── auto_wire/          # schemas + models the framework discovers
    ├── services/           # @tool / @on_event decorated services
    └── data/embed-artifacts/<model>/…   # see ../../data/README.md
```

## Why this is a real directory and not a build artifact

A Lochan package is **not** just a Python distribution. A bare
`pip install` carries only what lives *inside* the Python module — it does
**not** carry the sibling `data/embed-artifacts/*.npz`, the `frontend/`
tree, or the root `mandi.json`. The unit that travels is the **whole
working tree**, which is why your package is authored here as ordinary
files rather than assembled at build time.

Declare each package you add in `../packages.json`.
