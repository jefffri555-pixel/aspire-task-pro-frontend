#!/usr/bin/env bash
set -e

FLUTTER_DIR="$HOME/flutter"

# Remove incomplete/corrupted cached Flutter installation
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Flutter SDK missing or incomplete. Reinstalling..."
  rm -rf "$FLUTTER_DIR"

  git clone https://github.com/flutter/flutter.git \
    --branch stable \
    --depth 1 \
    "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

echo "Flutter location:"
ls -la "$FLUTTER_DIR/bin/flutter"

"$FLUTTER_DIR/bin/flutter" --version
"$FLUTTER_DIR/bin/flutter" config --enable-web
"$FLUTTER_DIR/bin/flutter" pub get
"$FLUTTER_DIR/bin/flutter" build web --release

echo "Flutter web build completed successfully."
