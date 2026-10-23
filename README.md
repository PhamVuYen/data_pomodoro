# data_pomodoro

Ảnh và âm thanh của app Pomodoro (Android + iOS). App không đóng gói các file này nữa, để file cài nhỏ: lần đầu mở app,
màn Splash tải hết từ **GitHub Release** của repo này rồi lưu trong máy. Những lần sau app dùng file đã lưu, không cần mạng.

## Cấu trúc

| Thư mục / file | Nội dung |
|---|---|
| `images/<tên>.webp` | Ảnh. `<tên>` trùng với `Res.drawable.<tên>` trong app. |
| `sounds/android/<tên>.ogg` | Âm thanh cho Android. `<tên>` là tên mà mã của app dùng (ví dụ `sound_001`). |
| `sounds/ios/<tên>.m4a` | Cùng bộ âm thanh, bản AAC cho iOS (iOS không phát được OGG). Sinh bằng `tools/make_ios_sounds.sh`. |
| `manifest.json` | Danh sách tên, file và số byte của mọi file. Sinh bằng `tools/make_manifest.sh`. |
| `dist/` | Không commit. Bản phẳng của mọi file + `manifest.json`, để tải lên release. |

## App tải thế nào

- Địa chỉ: `https://github.com/PhamVuYen/data_pomodoro/releases/download/<tag>/<file>`. Tag nằm trong
  `RemoteAssetConfig.TAG` của app (module `data`).
- App tải `manifest.json` trước, rồi tải những file còn thiếu hoặc sai số byte (4 file một lúc, mỗi file thử lại 3 lần).
  Xong hết thì lưu `manifest.json` vào máy. File trong máy mà không còn trong manifest thì bị xoá.
- Lần mở sau, app kiểm file trong máy theo `manifest.json` đã lưu. Đủ thì không gọi mạng.

## Thêm hoặc thay file

1. Ảnh: đặt `images/<tên>.webp` (PNG nên đổi sang WebP trước, ví dụ `cwebp -q 90 -alpha_q 100 -m 6 in.png -o <tên>.webp`).
   Trong app, thêm một **ảnh giữ chỗ WebP 1×1** cùng tên vào `presentation/src/commonMain/composeResources/drawable/` để
   Compose sinh `Res.drawable.<tên>`. Ảnh phải hiện trước khi tải xong (như ảnh của màn Splash) thì để ảnh thật trong app,
   không đưa lên đây.
2. Âm thanh: đặt `sounds/android/<tên>.ogg`, chạy `tools/make_ios_sounds.sh <tên>` để có bản `.m4a`.
3. Chọn tag mới (`assets-v2`, `assets-v3`…), chạy `tools/make_manifest.sh <tag>`, commit và push.
4. Tạo release với tag đó, tải lên **mọi** file trong `dist/` (không chỉ file mới):
   `gh release create <tag> dist/* --title <tag> --notes "..."`
5. Trong app, đổi `RemoteAssetConfig.TAG` thành tag mới. Bản app đó chỉ tải file mới hoặc đổi số byte.

**Không bao giờ xoá hoặc sửa một release đã phát hành.** Các bản app đang có trên máy người dùng vẫn đọc release cũ của
chúng.
