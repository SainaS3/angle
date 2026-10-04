#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"
OUT="$ROOT/out/darwin-es3-metal"
mkdir -p "$OUT"
# Dependencies must be present; fetchDependencies.sh pins the repository's versions.
for PLATFORM in device simulator; do
  if [[ "$PLATFORM" == device ]]; then
    SDK=iphoneos; DEST='generic/platform=iOS'; ARCHITECTURES=arm64
  else
    SDK=iphonesimulator; DEST='generic/platform=iOS Simulator'; ARCHITECTURES='arm64 x86_64'
  fi
  xcodebuild build -project ios/xcode/OpenGLES.xcodeproj -scheme MetalANGLE \
    -configuration Release -sdk "$SDK" -destination "$DEST" \
    -derivedDataPath "$OUT/$PLATFORM" ARCHS="$ARCHITECTURES" ONLY_ACTIVE_ARCH=NO \
    IPHONEOS_DEPLOYMENT_TARGET=13.0 SUPPORTS_MACCATALYST=NO \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
    > "$OUT/$PLATFORM-build.log" 2>&1
done
# Check Mach-O platform metadata; architecture alone cannot distinguish Catalyst.
python3 - "$OUT" <<'PYVERIFY'
from pathlib import Path
import re
import subprocess
import sys
out = Path(sys.argv[1])
for name, sdk, expected, count in [
    ("device", "iphoneos", "IOS", 1),
    ("simulator", "iphonesimulator", "IOSSIMULATOR", 2),
]:
    binary = out / name / "Build/Products" / ("Release-" + sdk) / "MetalANGLE.framework/MetalANGLE"
    metadata = subprocess.check_output(["xcrun", "vtool", "-show-build", str(binary)], text=True)
    platforms = re.findall(r"^\s*platform\s+(\S+)", metadata, re.MULTILINE)
    if platforms != [expected] * count:
        raise SystemExit(f"Unexpected platforms for {binary}: {platforms}")
    print(f"Verified {name}: {platforms}")
PYVERIFY
# Preserve any previous package rather than replacing it silently.
if [[ -e "$OUT/MetalANGLE.xcframework" ]]; then
  mv "$OUT/MetalANGLE.xcframework" "$OUT/MetalANGLE.xcframework.previous.$(date +%s)"
fi
xcodebuild -create-xcframework \
  -framework "$OUT/device/Build/Products/Release-iphoneos/MetalANGLE.framework" \
  -framework "$OUT/simulator/Build/Products/Release-iphonesimulator/MetalANGLE.framework" \
  -output "$OUT/MetalANGLE.xcframework"
