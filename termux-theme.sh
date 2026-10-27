#!/data/data/com.termux/files/usr/bin/bash
# Push my-theme/ from this fork to the CleanYourTV launcher over adb (Termux on a phone/tablet).
# Usage: bash termux-theme.sh <tv ip>      Undo: bash termux-theme.sh <tv ip> --reset
set -e
TV="${1:?usage: bash termux-theme.sh <tv ip> [--reset]}"
RAW=https://raw.githubusercontent.com/pinakpal009-cmyk/cleanyourtv/main/my-theme
PKG=com.gathin.tvhome
DIR=/sdcard/Android/data/$PKG/files
URI=content://$PKG.theme
TMP=/data/local/tmp/cyt
adb connect "$TV:5555" >/dev/null
A() { adb -s "$TV:5555" "$@"; }
put() { # $1 = local file, $2 = name on TV (e.g. wallpapers/001.jpg)
  A push "$1" "$TMP-x" >/dev/null
  A shell "rm -f $DIR/$2 2>/dev/null; content write --uri $URI/$2 < $TMP-x || cp $TMP-x $DIR/$2; rm -f $TMP-x"
}
W=$(mktemp -d)
A shell "mkdir -p $DIR/wallpapers 2>/dev/null; rm -f $DIR/wallpapers/*.jpg $DIR/wallpaper.jpg 2>/dev/null; content delete --uri $URI/wallpapers 2>/dev/null; content delete --uri $URI/wallpaper.jpg 2>/dev/null" || true
if [ "${2:-}" = --reset ]; then
  A shell "rm -f $DIR/config.json $DIR/wallpapers/captions.txt 2>/dev/null; content delete --uri $URI/config.json 2>/dev/null; content delete --uri $URI/wallpapers/captions.txt 2>/dev/null" || true
else
  echo "Downloading theme..."
  curl -fsSL "$RAW/config.json" -o "$W/config.json"
  curl -fsSL "$RAW/wallpapers/captions.txt" -o "$W/captions.txt"
  put "$W/config.json" config.json
  for i in 001 002 003 004 005 006 007 008 009 010 011 012; do
    curl -fsSL "$RAW/wallpapers/$i.jpg" -o "$W/$i.jpg"
    put "$W/$i.jpg" "wallpapers/$i.jpg"; echo "  wallpaper $i sent"
  done
  put "$W/captions.txt" wallpapers/captions.txt
fi
printf '%s' "$(date +%s%N)" > "$W/rev"; put "$W/rev" theme_revision
A shell "am force-stop $PKG; am start -a android.intent.action.MAIN -c android.intent.category.HOME" >/dev/null
rm -rf "$W"
echo "Done. Press Home on the remote if the TV hasn't refreshed."
