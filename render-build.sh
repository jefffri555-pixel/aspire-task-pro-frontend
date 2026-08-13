#!/usr/bin/env bash
set -e

if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"

flutter config --enable-web
flutter pub get
flutter build web --release

echo "Flutter web build completed successfully."
