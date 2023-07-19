cd "$(dirname "$0")"
Rscript ../worldview.R
osascript -e "tell application \"Finder\" to set desktop picture to POSIX file \"$(readlink -f ~/worldview.jpg)\""
killall Dock
