cd "$(dirname "$0")"
Rscript ../worldview.R
magick convert "$HOME/worldview.jpg" \
    -pointsize 16 \
    -undercolor "#00000060" \
    -fill "#ffffff" \
    -gravity "southwest" \
    -annotate +80+80 \
    "$(cat $HOME/worldview.txt)" "$HOME/worldview.jpg"
osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$HOME/annotated.jpg\""
killall Dock
