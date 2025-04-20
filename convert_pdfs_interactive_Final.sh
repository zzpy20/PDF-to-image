
#!/bin/bash
set -e
set -x

# ===== 1. Ask for DPI =====
read -p "Enter DPI (default is 300): " dpi
dpi=${dpi:-300}

# ===== 2. Choose Portrait or Landscape =====
echo "Choose output mode:"
select mode in "Portrait (A4 2480x3508)" "Landscape (A4 3508x2480)"; do
  case $REPLY in
    1)
      rotate_degrees=270
      size="2480x3508"
      break
      ;;
    2)
      rotate_degrees=0
      size="3508x2480"
      break
      ;;
    *)
      echo "Invalid selection. Please choose 1 or 2."
      ;;
  esac
done

canvas_width=$(echo "$size" | cut -d'x' -f1)
canvas_height=$(echo "$size" | cut -d'x' -f2)

# ===== 3. Choose Background Color =====
read -p "Background color (white or black)? [white]: " bgcolor
bgcolor=${bgcolor:-white}

# ===== 4. Choose Input Folder =====
read -e -p "Enter input folder containing PDFs (e.g. ./PDF): " input_folder
cd "$input_folder" || { echo "❌ Cannot find folder: $input_folder"; exit 1; }

# ===== 5. Choose Output Folders =====
read -e -p "Enter output folder for raw images (e.g. ../Images): " images_folder
read -e -p "Enter output folder for final padded images (e.g. ../Resized): " final_folder
mkdir -p "$images_folder"
mkdir -p "$final_folder"

# ===== 6. Convert PDFs to JPEGs using pdftocairo (no rotate) =====
shopt -s nullglob
for file in *.pdf *.PDF; do
  [ -e "$file" ] || continue
  base_filename="${file%.*}"
  clean_name=$(echo "$base_filename" | tr ' ' '_' | tr -cd '[:alnum:]_-')

  pdftocairo -jpeg -r "$dpi" "$file" "$images_folder/$clean_name"
  echo "✅ Converted: $file → $images_folder/$clean_name"
done

# ===== 7. Resize proportionally and center on A4 canvas =====
for img in "$images_folder"/*.jpg; do
  [ -e "$img" ] || continue
  base=$(basename "$img")
  convert "$img" -resize "${size}"^ \
    -gravity center -background "$bgcolor" -extent "${size}" "$final_folder/$base"
done

# ===== 8. Rotate final images (if needed) =====
if [ "$rotate_degrees" -ne 0 ]; then
  for img in "$final_folder"/*.jpg; do
    mogrify -rotate "$rotate_degrees" "$img"
  done
fi

# ===== 9. Open the output folder in Finder =====
open "$final_folder"

echo "✅ All done! Final images saved in: $final_folder"