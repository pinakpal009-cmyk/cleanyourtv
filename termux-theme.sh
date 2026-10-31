#!/data/data/com.termux/files/usr/bin/bash
# Push my-theme/ from this fork to the CleanYourTV launcher over adb, from Termux.
# Usage: bash termux-theme.sh <tv ip>        Undo: bash termux-theme.sh <tv ip> --reset
set -e
TV="${1:?usage: bash termux-theme.sh <tv ip> [--reset]}"
THEME="${THEME:-my-theme}"
RAW=https://raw.githubusercontent.com/pinakpal009-cmyk/cleanyourtv/main/$THEME
PKG=com.gathin.tvhome
DIR=/sdcard/Android/data/$PKG/files
URI=content://$PKG.theme
TMP=/data/local/tmp/cyt
adb connect "$TV:5555" >/dev/null
A() { adb -s "$TV:5555" "$@"; }
put() { # $1 = local file, $2 = name on the TV
  A push "$1" "$TMP-x" >/dev/null
  A shell "rm -f $DIR/$2 2>/dev/null; content write --uri $URI/$2 < $TMP-x || cp $TMP-x $DIR/$2; rm -f $TMP-x"
}
del() { A shell "rm -f $DIR/$1 2>/dev/null; content delete --uri $URI/$1 2>/dev/null" || true; }
W=$(mktemp -d); T=$(date +%s)
A shell "mkdir -p $DIR/wallpapers 2>/dev/null; rm -f $DIR/wallpapers/* 2>/dev/null; content delete --uri $URI/wallpapers 2>/dev/null" || true
del wallpaper.jpg
if [ "${2:-}" = --reset ]; then
  del config.json
  echo "Theme removed."
else
  echo "Downloading theme..."
  curl -fsSL "$RAW/config.json?t=$T" -o "$W/config.json"
  curl -fsSL "$RAW/files.txt?t=$T" -o "$W/files.txt"
  put "$W/config.json" config.json
  for f in $(cat "$W/files.txt"); do
    curl -fsSL "$RAW/wallpapers/$f?t=$T" -o "$W/$f"
    put "$W/$f" "wallpapers/$f"; echo "  sent $f"
  done
  if curl -fsSL "$RAW/wallpapers/captions.txt?t=$T" -o "$W/captions.txt" 2>/dev/null; then put "$W/captions.txt" wallpapers/captions.txt; fi
  echo "Theme sent."
fi
printf '%s' "$(date +%s%N)" > "$W/rev"; put "$W/rev" theme_revision
A shell "am force-stop $PKG; am start -a android.intent.action.MAIN -c android.intent.category.HOME" >/dev/null
rm -rf "$W"
echo "Done. Look at the TV."
