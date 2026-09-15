echo "Starting..."

mkdir -p ~/.local/share/applications && find ~/.config/wofi/applications -maxdepth 1 -type f -name "*.desktop" -exec ln -sf {} ~/.local/share/applications/ \;

update-desktop-database ~/.local/share/applications 2>/dev/null

echo "Done"
