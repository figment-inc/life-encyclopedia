#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# release.sh — Build, archive, and upload to App Store Connect
# Usage: ./scripts/release.sh
# ─────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_NAME="life-encyclopedia"
SCHEME="life-encyclopedia"
ARCHIVE_PATH="$PROJECT_DIR/build/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
EXPORT_OPTIONS="$PROJECT_DIR/ExportOptions-local.plist"

# ─── Load credentials ───────────────────────────────────────
ENV_FILE="$SCRIPT_DIR/.env.release"
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found."
    echo "Copy .env.release.template to .env.release and fill in your credentials."
    exit 1
fi
source "$ENV_FILE"

# Expand tilde in key path
ASC_KEY_PATH="${ASC_KEY_PATH/#\~/$HOME}"

if [ ! -f "$ASC_KEY_PATH" ]; then
    echo "ERROR: API key not found at $ASC_KEY_PATH"
    exit 1
fi

echo "================================================"
echo "  App Store Connect Release Script"
echo "================================================"
echo ""

# ─── Step 1: Auto-increment build number ────────────────────
echo "→ Step 1: Incrementing build number..."

PBXPROJ="$PROJECT_DIR/${PROJECT_NAME}.xcodeproj/project.pbxproj"
CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION' "$PBXPROJ" | sed 's/[^0-9]//g')
NEW_BUILD=$((CURRENT_BUILD + 1))

# Replace all CURRENT_PROJECT_VERSION entries
sed -i '' "s/CURRENT_PROJECT_VERSION = ${CURRENT_BUILD};/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" "$PBXPROJ"

echo "   Build number: $CURRENT_BUILD → $NEW_BUILD"
echo ""

# ─── Step 2: Clean previous builds ──────────────────────────
echo "→ Step 2: Cleaning previous build artifacts..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
echo "   Done."
echo ""

# ─── Step 3: Archive ────────────────────────────────────────
echo "→ Step 3: Archiving (this may take a minute)..."

xcodebuild \
    -project "$PROJECT_DIR/${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    CODE_SIGN_STYLE=Automatic \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$ASC_KEY_PATH" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    -quiet

echo "   Archive succeeded."
echo ""

# ─── Step 4: Export IPA locally ──────────────────────────────
echo "→ Step 4: Exporting IPA..."

# Create export options plist for local export (no direct upload)
cat > "$EXPORT_OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>teamID</key>
	<string>QU8R2P5MVQ</string>
	<key>uploadSymbols</key>
	<true/>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>destination</key>
	<string>export</string>
</dict>
</plist>
PLIST

xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$ASC_KEY_PATH" \
    -authenticationKeyID "$ASC_KEY_ID" \
    -authenticationKeyIssuerID "$ASC_ISSUER_ID"

echo "   Export succeeded."
echo ""

# ─── Step 5: Upload to App Store Connect via altool ──────────
echo "→ Step 5: Uploading to App Store Connect..."

IPA_PATH="$EXPORT_PATH/${PROJECT_NAME}.ipa"

if [ ! -f "$IPA_PATH" ]; then
    echo "ERROR: IPA not found at $IPA_PATH"
    exit 1
fi

xcrun altool \
    --upload-app \
    -f "$IPA_PATH" \
    -t ios \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID"

# Clean up temporary export options
rm -f "$EXPORT_OPTIONS"

echo ""
echo "================================================"
echo "  Upload complete!"
echo "  Build $NEW_BUILD uploaded to App Store Connect."
echo "  Check status: https://appstoreconnect.apple.com"
echo "================================================"
