#!/data/data/com.termux/files/usr/bin/bash
# Push my-theme/ from this fork to the CleanYourTV launcher over adb, from Termux.
# Usage: bash termux-theme.sh <tv ip>        Undo: bash termux-theme.sh <tv ip> --reset
set -e
TV="${1:?usage: bash termux-theme.sh <tv ip> [--reset]}"
RAW=https://raw.githubusercontent.com/pinakpal009-cmyk/cleanyourtv/main/my-theme
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
W=$(mktemp -d)
A shell "mkdir -p $DIR/wallpapers 2>/dev/null; rm -f $DIR/wallpapers/* 2>/dev/null; content delete --uri $URI/wallpapers 2>/dev/null" || true
if [ "${2:-}" = --reset ]; then
  del config.json; del wallpaper.jpg
  echo "Theme removed."
else
  echo "Downloading theme..."
  curl -fsSL "$RAW/config.json" -o "$W/config.json"
  curl -fsSL "$RAW/wallpaper.jpg" -o "$W/wallpaper.jpg"
  put "$W/config.json" config.json
  put "$W/wallpaper.jpg" wallpaper.jpg
  echo "Theme sent."
fi
printf '%s' "$(date +%s%N)" > "$W/rev"; put "$W/rev" theme_revision
A shell "am force-stop $PKG; am start -a android.intent.action.MAIN -c android.intent.category.HOME" >/dev/null
rm -rf "$W"
echo "Done. Look at the TV."
