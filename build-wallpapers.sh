#!/bin/bash
# Regenerate backgrounds/, preview.png, unlock.png and preview-unlock.png from
# the photographs and fonts in assets/ and the star drawn by star.py.
# Requires ImageMagick 7, librsvg (rsvg-convert) and python3.
# Run ./fetch-assets.sh first if assets/ has been cleared.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
root=$PWD
mkdir -p build backgrounds

W=3840
H=2160
BG='#0F1715'
GOLD='#D9AE5B'
IVORY='#ECE4D0'

# rsvg-convert finds the bundled OFL fonts through this, without installing them.
cat >build/fonts.conf <<EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
  <dir>$root/assets/fonts</dir>
  <cachedir>$root/build/fontcache</cachedir>
</fontconfig>
EOF
export FONTCONFIG_FILE=$root/build/fonts.conf

python3 star.py build/star.svg 2000

# backdrop <out> <centre-colour> <edge-colour>
# A radial pool of cypress-green light on a near-black ground, roughened with a
# blurred fractal so the gradient does not band across a large display, then
# vignetted back down at the corners.
backdrop() {
  local out=$1 centre=$2 edge=$3
  magick -size ${W}x${H} radial-gradient:"$centre"-"$edge" \
    \( -size ${W}x${H} -seed 1844 plasma:fractal -colorspace Gray -blur 0x14 -auto-level \
       -function polynomial 0.40,0.30 \) \
    -compose Overlay -composite \
    \( -size ${W}x${H} radial-gradient:white-black -blur 0x90 \
       -function polynomial 0.55,0.45 \) \
    -compose Multiply -composite \
    -depth 8 "$out"
}

# star <height-px> <out> — the emblem rendered crisp at its final size.
star() {
  rsvg-convert -h "$1" -f png -o "$2" build/star.svg
}

# glow <emblem-png> <out> <colour>
# A soft halo cut from the emblem's own silhouette, so the star sits in light
# rather than pasted on the ground. Keep the colour dim; it is screened on.
glow() {
  local src=$1 out=$2 colour=$3
  magick "$src" -alpha extract -blur 0x40 -auto-level \
    \( +clone -fill "$colour" -colorize 100 \) \
    +swap -compose CopyOpacity -composite \
    -background none -layers merge "$out"
}

# emblem <backdrop> <out> <height-px> <offset>
emblem() {
  local bg=$1 out=$2 eh=$3 off=$4
  star "$eh" build/emblem.png
  magick "$bg" \
    \( build/glow.png -resize x$((eh + eh / 3)) \) -gravity center -geometry "$off" \
       -compose Screen -composite \
    build/emblem.png -gravity center -geometry "$off" -compose Over -composite \
    -depth 8 "$out"
}

# photo <src> <out> <crop-geometry>
# Crop a photograph to 16:9, fit it to the frame and pull the corners down so
# the bar and windows sit on shadow rather than on streetlights.
photo() {
  local src=$1 out=$2 crop=$3
  magick "$src" -auto-orient -crop "$crop" +repage \
    -filter Lanczos -resize ${W}x${H}^ -gravity center -extent ${W}x${H} \
    \( -size ${W}x${H} radial-gradient:white-black -blur 0x120 \
       -function polynomial 0.50,0.50 \) \
    -compose Multiply -composite \
    -depth 8 -quality 92 "$out"
}

backdrop build/bd.png '#1D3530' '#050A09'
star 1000 build/glow-src.png
glow build/glow-src.png build/glow.png '#5C4618'

# 1. The star, large and centred. The default.
emblem build/bd.png backgrounds/1-star.png 1560 '+0+0'

# 2. The Shrine of the Báb, lit at night, from Yefe Nof Street.
photo assets/shrine-night.jpg backgrounds/2-shrine.jpg 4608x2592+0+220

# 3. The Terraces climbing to the Shrine at night, from Ben Gurion Avenue.
photo assets/terraces-night.jpg backgrounds/3-terraces.jpg 4600x2588+721+330

# 4. The star over "The earth is but one country, and mankind its citizens."
emblem build/bd.png build/unity.png 980 '+0-330'
cat >build/unity-text.svg <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="$W" height="$H" viewBox="0 0 $W $H">
  <text x="1920" y="1600" text-anchor="middle" font-family="Cormorant Garamond"
        font-weight="500" font-size="120" fill="$IVORY">The earth is but one country, and mankind its citizens.</text>
  <line x1="1770" y1="1712" x2="1892" y2="1712" stroke="$GOLD" stroke-width="2.5" stroke-opacity="0.7"/>
  <circle cx="1920" cy="1712" r="7" fill="$GOLD"/>
  <line x1="1948" y1="1712" x2="2070" y2="1712" stroke="$GOLD" stroke-width="2.5" stroke-opacity="0.7"/>
  <text x="1927" y="1830" text-anchor="middle" font-family="Cinzel"
        font-weight="500" font-size="48" letter-spacing="14" fill="$GOLD">BAHÁ’U’LLÁH</text>
</svg>
EOF
rsvg-convert -w $W -h $H -f png -o build/unity-text.png build/unity-text.svg
magick build/unity.png build/unity-text.png -compose Over -composite -depth 8 backgrounds/4-unity.png

# 5. The gardens by day, down the mountain to the Bay of Haifa.
photo assets/gardens-day.jpg backgrounds/5-carmel.jpg 3984x2241+0+180

# The theme picker preview.
magick backgrounds/1-star.png -resize 1800x1012 -strip -depth 8 preview.png

# The boot/disk-unlock logo for `omarchy plymouth set-by-theme bahai`, and the
# picture of it the Plymouth switcher shows.
star 360 unlock.png
magick -size 1920x1080 xc:"$BG" \
  \( unlock.png -resize x340 \) -gravity center -geometry +0-80 -compose Over -composite \
  -fill '#18231F' -stroke "$IVORY" -strokewidth 3 -draw "rectangle 818,720 1102,766" \
  -stroke none -fill "$IVORY" \
  -draw "circle 840,743 845,743" -draw "circle 858,743 863,743" \
  -draw "circle 876,743 881,743" -draw "circle 894,743 899,743" \
  -depth 8 preview-unlock.png

echo "Backgrounds written to backgrounds/."
