#!/usr/bin/env bash
set -euo pipefail

# ─── Paths ─────────────────────────────────────────────────
ROOT="$(cd "$(dirname "$0")" && pwd)"
COMPONENTS="$ROOT/components"
CONTENT="$ROOT/content"
HEADER="$COMPONENTS/header.html"
FOOTER="$COMPONENTS/footer.html"

# ─── Temp files ────────────────────────────────────────────
TMP_HEADER=$(mktemp /tmp/sg-header.XXXXXX)
TMP_FOOTER=$(mktemp /tmp/sg-footer.XXXXXX)
TMP_CONTENT=$(mktemp /tmp/sg-content.XXXXXX)
trap 'rm -f "$TMP_HEADER" "$TMP_FOOTER" "$TMP_CONTENT"' EXIT

# ─── build_page function ───────────────────────────────────
# Args: TITLE DESC CANONICAL OG_TITLE CSS_EXTRA ACTIVE_NAV OUT DEPTH CONTENT_FILE [JSONLD_FILE]
build_page() {
  local TITLE="$1"
  local DESC="$2"
  local CANONICAL="$3"
  local OG_TITLE="$4"
  local CSS_EXTRA="${5:-}"
  local ACTIVE_NAV="$6"
  local OUT="$7"
  local DEPTH="$8"
  local CONTENT_FILE="$9"
  local JSONLD_FILE="${10:-}"

  # BASE path prefix based on depth
  if [ "$DEPTH" -eq 0 ]; then
    BASE=""
    ROOT_HREF="./"
  else
    BASE="../"
    ROOT_HREF="../"
  fi

  # Process header: inject active class FIRST (while path still absolute), then convert paths
  sed \
    -e "s|href=\"${ACTIVE_NAV}\">|href=\"${ACTIVE_NAV}\" class=\"active\">|g" \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    "$HEADER" > "$TMP_HEADER"

  # Process footer: convert paths only
  sed \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    "$FOOTER" > "$TMP_FOOTER"

  # Process content: convert paths only (href, src, and CSS url())
  sed \
    -e "s|href=\"/\"|href=\"${ROOT_HREF}\"|g" \
    -e "s|href=\"/\([^\"]*\)\"|href=\"${BASE}\1\"|g" \
    -e "s|src=\"/\([^\"]*\)\"|src=\"${BASE}\1\"|g" \
    -e "s|url('/\([^']*\)')|url('${BASE}\1')|g" \
    -e "s|url(\"/\([^\"]*\)\")|url(\"${BASE}\1\")|g" \
    "$CONTENT_FILE" > "$TMP_CONTENT"

  # Create output directory
  mkdir -p "$(dirname "$OUT")"

  # Assemble page using printf + cat (NEVER heredoc with variables)
  {
    printf '<!DOCTYPE html>\n'
    printf '<html lang="en">\n'
    printf '<head>\n'
    printf '<meta charset="UTF-8">\n'
    printf '<meta name="viewport" content="width=device-width, initial-scale=1.0">\n'
    printf '<title>%s</title>\n' "$TITLE"
    printf '<meta name="description" content="%s">\n' "$DESC"
    printf '<link rel="canonical" href="%s">\n' "$CANONICAL"
    printf '<meta property="og:type" content="article">\n'
    printf '<meta property="og:title" content="%s">\n' "$OG_TITLE"
    printf '<meta property="og:description" content="%s">\n' "$DESC"
    printf '<meta property="og:url" content="%s">\n' "$CANONICAL"
    printf '<meta property="og:site_name" content="South Georgia Small Ship Cruise Guide">\n'
    printf '<link rel="icon" type="image/svg+xml" href="%sfavicon.svg">\n' "$BASE"
    printf '<link rel="preconnect" href="https://fonts.googleapis.com">\n'
    printf '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n'
    printf '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;0,700;1,400&family=DM+Sans:wght@400;500;600&display=swap">\n'
    printf '<link rel="stylesheet" href="%scss/global.css">\n' "$BASE"
    if [ -n "$CSS_EXTRA" ]; then
      printf '<link rel="stylesheet" href="%scss/%s">\n' "$BASE" "$CSS_EXTRA"
    fi
    if [ -n "$JSONLD_FILE" ] && [ -f "$JSONLD_FILE" ]; then
      cat "$JSONLD_FILE"
    fi
    printf '</head>\n'
    printf '<body class="grain-overlay">\n'
    printf '<a href="#main-content" class="skip-link" style="position:absolute;left:-9999px;top:auto;width:1px;height:1px;overflow:hidden;">Skip to content</a>\n'
    cat "$TMP_HEADER"
    cat "$TMP_CONTENT"
    cat "$TMP_FOOTER"
    printf '</body>\n'
    printf '</html>\n'
  } > "$OUT"

  echo "✓ Built: $OUT"
}

# ─── Build all pages ───────────────────────────────────────

echo "Building south-georgia-small-ship-cruise.com..."
echo ""

# 1. Index (main ranking page, depth 0)
build_page \
  "Best South Georgia Small Ship Cruises 2026: Operator Rankings" \
  "Independent rankings of the 6 best South Georgia small ship cruise operators for 2026. Expert ratings across wildlife access, ship size, guiding quality, and value from \$8,577." \
  "https://south-georgia-small-ship-cruise.com/" \
  "Best South Georgia Small Ship Cruises 2026: Operator Rankings" \
  "south-georgia-ranking.css" \
  "/" \
  "$ROOT/index.html" \
  0 \
  "$CONTENT/south-georgia-ranking.html" \
  "$ROOT/components/jsonld-index.html"

# 2. Guide page (depth 1)
build_page \
  "South Georgia Expedition Guide 2026: Wildlife, History & Landing Sites" \
  "Complete expedition guide to South Georgia: wildlife species, key landing sites, Shackleton history, IAATO regulations, and practical planning advice for 2026 voyages." \
  "https://south-georgia-small-ship-cruise.com/guide/" \
  "South Georgia Expedition Guide 2026: Wildlife, History & Landing Sites" \
  "guide.css" \
  "/guide/" \
  "$ROOT/guide/index.html" \
  1 \
  "$CONTENT/guide.html"

# 3. About (depth 1)
build_page \
  "About Our South Georgia Cruise Rankings | Editorial Methodology" \
  "Learn how we independently evaluate and rank South Georgia small ship cruise operators. Our 6-point methodology, editorial principles, and team background explained." \
  "https://south-georgia-small-ship-cruise.com/about/" \
  "About Our South Georgia Cruise Rankings" \
  "" \
  "/about/" \
  "$ROOT/about/index.html" \
  1 \
  "$CONTENT/about.html"

# 4. Editorial Policy (depth 1)
build_page \
  "Editorial Policy | South Georgia Small Ship Cruise Rankings" \
  "Our rating criteria, weightings, data sources, update schedule, and conflict-of-interest policy for South Georgia cruise operator rankings." \
  "https://south-georgia-small-ship-cruise.com/editorial-policy/" \
  "Editorial Policy | South Georgia Cruise Rankings" \
  "" \
  "/editorial-policy/" \
  "$ROOT/editorial-policy/index.html" \
  1 \
  "$CONTENT/editorial-policy.html"

# 5. FAQ (depth 1)
build_page \
  "South Georgia Cruise FAQ: 15 Common Questions Answered" \
  "Answers to the most common questions about South Georgia small ship cruises: itinerary length, costs, wildlife, Drake Passage, visa requirements, and booking advice." \
  "https://south-georgia-small-ship-cruise.com/faq/" \
  "South Georgia Cruise FAQ: 15 Common Questions Answered" \
  "" \
  "/faq/" \
  "$ROOT/faq/index.html" \
  1 \
  "$CONTENT/faq.html"

# 6. Contact (depth 1)
build_page \
  "Contact | South Georgia Small Ship Cruise Guide" \
  "Contact the South Georgia Small Ship Cruise editorial team. Questions, corrections, and feedback welcome. We respond within 48 hours." \
  "https://south-georgia-small-ship-cruise.com/contact/" \
  "Contact | South Georgia Small Ship Cruise Guide" \
  "" \
  "/contact/" \
  "$ROOT/contact/index.html" \
  1 \
  "$CONTENT/contact.html"

# 7. Cookie Policy (depth 1)
build_page \
  "Cookie Policy | South Georgia Small Ship Cruise Guide" \
  "Information about how south-georgia-small-ship-cruise.com uses cookies and local storage on this website." \
  "https://south-georgia-small-ship-cruise.com/cookie-policy/" \
  "Cookie Policy | South Georgia Small Ship Cruise Guide" \
  "" \
  "/cookie-policy/" \
  "$ROOT/cookie-policy/index.html" \
  1 \
  "$CONTENT/cookie-policy.html"

echo ""
echo "Build complete! 7 pages assembled."
echo ""
echo "To preview locally: node serve.mjs"
echo "Then open: http://localhost:3000"
