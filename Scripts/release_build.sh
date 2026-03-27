#!/bin/zsh
set -euo pipefail

PROJECT_PATH="${PROJECT_PATH:-iPhoneMediaImporter.xcodeproj}"
SCHEME="${SCHEME:-iPhoneMediaImporter}"
CONFIGURATION="${CONFIGURATION:-Release}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$PWD/build/release/iPhoneMediaImporter.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$PWD/build/release/export}"
ZIP_PATH="${ZIP_PATH:-$PWD/build/release/iPhoneMediaImporter.zip}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:-}"
PRODUCT_BUNDLE_IDENTIFIER="${PRODUCT_BUNDLE_IDENTIFIER:-}"
SKIP_NOTARIZATION="${SKIP_NOTARIZATION:-0}"

if [[ -z "${DEVELOPMENT_TEAM}" ]]; then
  echo "DEVELOPMENT_TEAM tanimli olmali."
  exit 1
fi

if [[ -z "${PRODUCT_BUNDLE_IDENTIFIER}" ]]; then
  echo "PRODUCT_BUNDLE_IDENTIFIER tanimli olmali."
  exit 1
fi

if [[ "${SKIP_NOTARIZATION}" != "1" && -z "${NOTARY_PROFILE}" ]]; then
  echo "Notarization icin NOTARY_PROFILE tanimli olmali ya da SKIP_NOTARIZATION=1 kullanin."
  exit 1
fi

mkdir -p "$PWD/build/release"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH" "$ZIP_PATH"
mkdir -p "$EXPORT_PATH"

EXPORT_OPTIONS_PLIST="$(mktemp /tmp/iPhoneMediaImporterExportOptions.XXXXXX.plist)"
trap 'rm -f "$EXPORT_OPTIONS_PLIST"' EXIT

cat > "$EXPORT_OPTIONS_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>${DEVELOPMENT_TEAM}</string>
</dict>
</plist>
PLIST

echo "==> Archive olusturuluyor"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  PRODUCT_BUNDLE_IDENTIFIER="$PRODUCT_BUNDLE_IDENTIFIER"

echo "==> Developer ID export olusturuluyor"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  PRODUCT_BUNDLE_IDENTIFIER="$PRODUCT_BUNDLE_IDENTIFIER"

APP_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -name '*.app' -print -quit)"
if [[ -z "$APP_PATH" ]]; then
  echo "Export sonrasi .app bulunamadi."
  exit 1
fi

echo "==> App zipleniyor"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

if [[ "${SKIP_NOTARIZATION}" == "1" ]]; then
  echo "==> Notarization atlandi"
  echo "Hazir app: $APP_PATH"
  exit 0
fi

echo "==> Notarization gonderiliyor"
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> Ticket stapler ile uygulaniyor"
xcrun stapler staple "$APP_PATH"

echo "==> Gatekeeper dogrulamasi"
spctl -a -vv "$APP_PATH"

echo "Tamamlandi: $APP_PATH"
