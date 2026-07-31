"""Demo — the starter package for a new Lochan app.

Declarations ONLY, no business logic. See
``framework/lochan/docs/features/PACKAGE-CONVENTION.md`` for the canonical
package shape.

AUTO-WIRE: the framework discovers and wires everything by convention —
``models.py`` / ``models/``, ``services/*.py`` (via ``@tool``, ``@on_event``,
``@context``, ``@health_metric``), ``schemas/*.json``, ``PACKAGE_PERMISSIONS``,
``ROLE_PERMISSIONS``, ``PROVIDES``. Add those directories as your package
grows; nothing here needs to register them by hand.

This package deliberately defines neither ``provide(ctx)`` nor
``make_routers(ctx)``: per the convention both are OPTIONAL, and this package
exposes no cross-package singletons and serves no HTTP routes yet. Add
``make_routers(ctx)`` when you have routes, and ``provide(ctx)`` only if other
packages consume singletons from this one.
"""

import logging

logger = logging.getLogger(__name__)

# ── Identity ────────────────────────────────────────────────────────────────

PROVIDES = [
    "demo.greeting",
]

AGENT_CARD = {
    "package": "demo",
    "name": "Demo Agent",
    "capabilities": [
        "demo.greeting.read",
    ],
    "accepts": [],
    "trust_minimum": 0.0,
    "version": "1.0",
}

# ── Security ────────────────────────────────────────────────────────────────
# Format: (slug, display_name, description, is_package_admin)

PACKAGE_ROLES = [
    ("demo.admin", "Demo Admin", "Full access to demo", True),
    ("demo.user", "Demo User", "Standard demo access", False),
]

PACKAGE_PERMISSIONS = [
    ("demo.view", "Demo View", "View demo data"),
]

ROLE_PERMISSIONS = {
    "demo.admin": ["demo.*"],
    "demo.user": ["demo.view"],
    "user": ["demo.view"],
}


# ── Lifecycle ───────────────────────────────────────────────────────────────


async def startup() -> None:
    """Phase 10c — async lifespan hook, runs after routers register."""
    logger.info("demo package started")


def health_check() -> dict:
    """Health probe surfaced by the framework's health aggregation."""
    return {"status": "ok", "package": "demo"}
