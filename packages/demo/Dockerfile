# demo domain package image (Tier 2)
# Usage: COPY --from=demo:latest /pkg/ /app/packages/demo/
FROM busybox
# Patent + opencontainers provenance — the 5 LABELs daksh verify requires on
# every package image. Stamped here so the package image can't drift back to 0/5.
LABEL org.lochan.patent.filing="FP11"
LABEL org.lochan.patent.filing_date="2026-04-19"
LABEL org.lochan.patent.claims="33"
LABEL org.lochan.patent.status="filed"
LABEL org.opencontainers.image.source="https://github.com/gyanamlabs/lochan-qapp"
LABEL org.opencontainers.image.licenses="MIT"
COPY . /pkg/
