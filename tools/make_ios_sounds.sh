#!/usr/bin/env bash
#
# Tạo bản AAC (.m4a) cho iOS từ các file OGG của Android.
#
# iOS không phát được OGG Vorbis bằng API hệ thống, nên mỗi file .ogg cần một bản .m4a cùng tên.
# Đọc sounds/android/*.ogg (không sửa), ghi sounds/ios/*.m4a.
#
# Cách dùng (chạy từ gốc repo):
#   tools/make_ios_sounds.sh                  chuyển mọi file .ogg (bỏ qua file đã có bản .m4a mới hơn)
#   tools/make_ios_sounds.sh sound_001 ...    chỉ chuyển các file nêu tên (không kèm đuôi)
#   FORCE=1 tools/make_ios_sounds.sh          chuyển lại tất cả
#   BITRATE=96000 tools/make_ios_sounds.sh    đổi bitrate (bit/giây, tính cho file stereo)
#
# Cần: ffmpeg và ffprobe (giải mã OGG, đọc số kênh) và afconvert (bộ mã hoá AAC của Apple, có sẵn trên macOS).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="$ROOT/sounds/android"
OUT_DIR="$ROOT/sounds/ios"
# File OGG nguồn trung bình khoảng 104 kbps. 128 kbps để dư một chút cho lần nén thứ hai; cao hơn chỉ tốn chỗ.
BITRATE="${BITRATE:-128000}"
FORCE="${FORCE:-0}"

if [ ! -d "$SRC_DIR" ]; then
    echo "Không tìm thấy thư mục chứa file .ogg: $SRC_DIR" >&2
    exit 1
fi

for tool in ffmpeg ffprobe afconvert; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Thiếu công cụ: $tool" >&2
        exit 1
    fi
done

mkdir -p "$OUT_DIR"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [ "$#" -gt 0 ]; then
    NAMES=("$@")
else
    NAMES=()
    for ogg in "$SRC_DIR"/*.ogg; do
        NAMES+=("$(basename "$ogg" .ogg)")
    done
fi

converted=0
skipped=0
for name in "${NAMES[@]}"; do
    ogg="$SRC_DIR/$name.ogg"
    m4a="$OUT_DIR/$name.m4a"
    if [ ! -f "$ogg" ]; then
        echo "Không có file nguồn: $ogg" >&2
        exit 1
    fi
    if [ "$FORCE" != "1" ] && [ -f "$m4a" ] && [ "$m4a" -nt "$ogg" ]; then
        skipped=$((skipped + 1))
        continue
    fi

    # -b của afconvert là tổng bitrate cho mọi kênh, nên file mono chỉ cần một nửa.
    channels="$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$ogg")"
    if [ "$channels" = "1" ]; then
        file_bitrate=$((BITRATE / 2))
    else
        file_bitrate="$BITRATE"
    fi

    wav="$TMP_DIR/$name.wav"
    ffmpeg -v error -y -i "$ogg" -c:a pcm_s16le "$wav"
    # -s 2: bitrate biến thiên có giới hạn; -q 127: chất lượng mã hoá cao nhất.
    afconvert "$wav" -o "$m4a" -f m4af -d aac -s 2 -b "$file_bitrate" -q 127
    rm -f "$wav"
    converted=$((converted + 1))
    echo "OK  $name.m4a"
done

total=$(find "$OUT_DIR" -name '*.m4a' | wc -l | tr -d ' ')
size=$(du -sh "$OUT_DIR" | cut -f1)
echo "Đã chuyển: $converted, bỏ qua (đã có): $skipped. sounds/ios hiện có $total file .m4a, $size."
