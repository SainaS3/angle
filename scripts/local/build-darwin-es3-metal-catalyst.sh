#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
OUT="$ROOT/out/darwin-es3-metal"
mkdir -p "$OUT"
xcodebuild build -project ios/xcode/OpenGLES.xcodeproj -scheme MetalANGLE \
  -configuration Release -destination 'generic/platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath "$OUT/catalyst" ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  SUPPORTS_MACCATALYST=YES IPHONEOS_DEPLOYMENT_TARGET=14.0 \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO > "$OUT/catalyst-build.log" 2>&1
FRAMEWORK="$OUT/catalyst/Build/Products/Release-maccatalyst/MetalANGLE.framework"
python3 - "$FRAMEWORK/MetalANGLE" <<'PYVERIFY'
import re, subprocess, sys
metadata = subprocess.check_output(["xcrun", "vtool", "-show-build", sys.argv[1]], text=True)
platforms = re.findall(r"^\s*platform\s+(\S+)", metadata, re.MULTILINE)
architectures = subprocess.check_output(["xcrun", "lipo", "-archs", sys.argv[1]], text=True).split()
if platforms != ["MACCATALYST", "MACCATALYST"] or set(architectures) != {"arm64", "x86_64"}:
    raise SystemExit(f"Unexpected Catalyst binary: {platforms}, {architectures}")
print(metadata)
PYVERIFY
PACKAGE="$OUT/MetalANGLE-Catalyst.xcframework"
if [[ -e "$PACKAGE" ]]; then
  mv "$PACKAGE" "$PACKAGE.previous.$(date +%s)"
fi
xcodebuild -create-xcframework -framework "$FRAMEWORK" -output "$PACKAGE"
# Add Catalyst to the shared package when the iOS builds are available.
DEVICE="$OUT/device/Build/Products/Release-iphoneos/MetalANGLE.framework"
SIMULATOR="$OUT/simulator/Build/Products/Release-iphonesimulator/MetalANGLE.framework"
if [[ -d "$DEVICE" && -d "$SIMULATOR" ]]; then
  COMBINED="$OUT/MetalANGLE.xcframework"
  if [[ -e "$COMBINED" ]]; then
    mv "$COMBINED" "$COMBINED.previous.$(date +%s)"
  fi
  xcodebuild -create-xcframework -framework "$DEVICE" -framework "$SIMULATOR" \
    -framework "$FRAMEWORK" -output "$COMBINED"
fi
