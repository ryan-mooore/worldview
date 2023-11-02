cd "$(dirname "$0")"
Rscript ../worldview.R
magick convert "$HOME/worldview.jpg" \
    -pointsize 16 \
    -font Arial-Unicode-MS \
    -undercolor "#00000060" \
    -fill "#ffffff" \
    -gravity "southwest" \
    -annotate +150+150 \
    "$(cat $HOME/worldview.txt)" "$HOME/annotated.jpg"
osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$HOME/annotated.jpg\""
killall Dock
