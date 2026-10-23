#!/usr/bin/env bash
#
# Sinh manifest.json và thư mục phẳng dist/ cho một release.
#
# App Pomodoro tải manifest.json của đúng tag nó biết (RemoteAssetConfig.TAG), rồi tải từng file trong đó từ
#   https://github.com/PhamVuYen/data_pomodoro/releases/download/<tag>/<file>
# Tên file trong release phải duy nhất, nên dist/ gom phẳng images/, sounds/android/, sounds/ios/ và manifest.json.
#
# Cách dùng (chạy từ gốc repo):
#   tools/make_manifest.sh assets-v1
# Sau đó: commit manifest.json, rồi tạo release cùng tag với mọi file trong dist/, ví dụ
#   gh release create assets-v1 dist/* --title assets-v1 --notes "..."

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Cách dùng: tools/make_manifest.sh <tag>   (ví dụ assets-v1)" >&2
    exit 1
fi
TAG="$1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Âm thanh Android và iOS phải có cùng một bộ tên.
if ! diff <(ls sounds/android | sed 's/\.ogg$//') <(ls sounds/ios | sed 's/\.m4a$//') >/dev/null; then
    echo "sounds/android và sounds/ios không cùng bộ tên. Chạy tools/make_ios_sounds.sh trước." >&2
    exit 1
fi

# Tên ảnh (bỏ đuôi) là tên Res.drawable trong app, nên không được trùng.
duplicates="$(ls images | sed 's/\.[^.]*$//' | sort | uniq -d)"
if [ -n "$duplicates" ]; then
    echo "Ảnh trùng tên (khác đuôi): $duplicates" >&2
    exit 1
fi

# In một mảng JSON cho các file khớp mẫu: [{ "name", "file", "size" }, ...]
entries() {
    local first=1
    printf '[\n'
    for path in "$@"; do
        local file name size
        file="$(basename "$path")"
        name="${file%.*}"
        size="$(wc -c < "$path" | tr -d ' ')"
        if [ "$first" -eq 0 ]; then printf ',\n'; fi
        first=0
        printf '    { "name": "%s", "file": "%s", "size": %s }' "$name" "$file" "$size"
    done
    printf '\n  ]'
}

{
    printf '{\n'
    printf '  "tag": "%s",\n' "$TAG"
    printf '  "images": '; entries images/*; printf ',\n'
    printf '  "sounds_android": '; entries sounds/android/*.ogg; printf ',\n'
    printf '  "sounds_ios": '; entries sounds/ios/*.m4a; printf '\n'
    printf '}\n'
} > manifest.json

rm -rf dist
mkdir dist
cp -p images/* sounds/android/*.ogg sounds/ios/*.m4a manifest.json dist/

echo "manifest.json: tag $TAG, $(ls images | wc -l | tr -d ' ') ảnh, $(ls sounds/android | wc -l | tr -d ' ') âm thanh mỗi nền tảng."
echo "dist/: $(ls dist | wc -l | tr -d ' ') file, $(du -sh dist | cut -f1)."
