#!/bin/bash
# Download the photographs from Wikimedia Commons and the fonts from Google
# Fonts into assets/. Only needed if you have cleared assets/; the repo ships
# them. See assets/SOURCES.md.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
mkdir -p assets/fonts

api="https://commons.wikimedia.org/w/api.php"
ua="omarchy-bahai-theme (https://github.com/ninepointlabs/omarchy-bahai-theme)"

# local-name:commons-file-title
photos=(
  "shrine-night.jpg:2014, The Shrine from Yefe Nof Street - panoramio.jpg"
  "terraces-night.jpg:Bahai Garden in Haifa Israel.jpg"
  "gardens-day.jpg:IPhO-2019 07-11 Haifa Bahai garden view.jpg"
)

for entry in "${photos[@]}"; do
  out="assets/${entry%%:*}"
  title="File:${entry#*:}"

  # Ask Commons where the original lives rather than guessing at the URL
  # encoding of titles with commas and apostrophes.
  url=$(curl -sfG -A "$ua" "$api" \
    --data-urlencode action=query --data-urlencode prop=imageinfo \
    --data-urlencode "titles=$title" --data-urlencode iiprop=url \
    --data-urlencode format=json |
    python3 -c 'import sys,json
p=next(iter(json.load(sys.stdin)["query"]["pages"].values()))
print(p["imageinfo"][0]["url"] if "imageinfo" in p else "")')

  if [[ -z $url ]]; then
    echo "Could not resolve $title" >&2
    exit 1
  fi

  curl -sfL -A "$ua" "$url" -o "$out"
  echo "$out  <-  $title"
done

fonts="https://github.com/google/fonts/raw/main/ofl"
curl -sfL "$fonts/cormorantgaramond/CormorantGaramond%5Bwght%5D.ttf" -o "assets/fonts/CormorantGaramond[wght].ttf"
curl -sfL "$fonts/cormorantgaramond/OFL.txt" -o assets/fonts/OFL-CormorantGaramond.txt
curl -sfL "$fonts/cinzel/Cinzel%5Bwght%5D.ttf" -o "assets/fonts/Cinzel[wght].ttf"
curl -sfL "$fonts/cinzel/OFL.txt" -o assets/fonts/OFL-Cinzel.txt
echo "assets/fonts  <-  Google Fonts (Cormorant Garamond, Cinzel)"
