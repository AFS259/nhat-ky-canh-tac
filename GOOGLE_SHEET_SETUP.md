# KẾT NỐI GOOGLE SHEET — LƯU DỮ LIỆU TỪ APP iOS

App tự động gửi dữ liệu (chữ + ảnh minh chứng) lên Google Sheet **mỗi khi lưu** (thêm/sửa khu vực, vụ, nhật ký; xoá khu vực).
Quy tắc: **mỗi KHU VỰC (Area) = một sheet riêng**; trong mỗi sheet ghi thông tin khu vực, từng **vụ canh tác**, **bảng nhật ký** và **ảnh minh chứng** của từng dòng nhật ký.

- File Apps Script: `google-apps-script/Code.gs`
- File app: `NhatKyCanhTacAFS/Services/GoogleSheetService.swift`
- Google Sheet đích: `1Jk461TKiDvHJv6dh8LZQ6lBltJpWFkChzI2coYo4QQQ`

---

## 1. Triển khai Apps Script (làm 1 lần)

1. Mở Google Sheet đích → menu **Tiện ích mở rộng (Extensions) → Apps Script**.
2. Xoá nội dung `Code.gs` cũ, dán **toàn bộ** nội dung file `google-apps-script/Code.gs` trong repo.
3. Kiểm tra hằng số đầu file (đã điền sẵn):
   ```js
   const SPREADSHEET_ID = '1Jk461TKiDvHJv6dh8LZQ6lBltJpWFkChzI2coYo4QQQ';
   ```
4. Bấm **Triển khai (Deploy) → Triển khai mới (New deployment)**:
   - Loại (Type): **Ứng dụng web (Web app)**
   - Thực thi dưới danh nghĩa (Execute as): **Tôi (Me)**
   - Ai có quyền truy cập (Who has access): **Bất kỳ ai (Anyone)**  ← **BẮT BUỘC**, vì app gửi không đăng nhập.
5. Bấm **Deploy**, cấp quyền khi Google hỏi (Advanced → Go to project → Allow).
6. Copy **URL ứng dụng web** (kết thúc bằng `/exec`).

> Nếu sau này sửa `Code.gs`, phải tạo **phiên bản mới**: `Deploy → Manage deployments → (bút chì) → Version: New version → Deploy`. Chỉ lưu file là chưa đủ.

---

## 2. Gắn URL vào app

Mở `NhatKyCanhTacAFS/Services/GoogleSheetService.swift`, thay dòng đầu:

```swift
static let webAppURL = URL(string: "<DÁN_URL_/exec_VÀO_ĐÂY>")!
```

> Nếu URL deploy mới giống URL cũ thì **không cần đổi gì** — app đã trỏ sẵn URL hiện tại.

---

## 3. Kiểm tra nhanh sau khi deploy

- Mở URL `/exec` bằng trình duyệt → phải thấy JSON:
  ```json
  {"ok":true,"service":"AFS Nhat Ky Canh Tac","time":"..."}
  ```
  - Nếu hiện **trang đăng nhập Google** → quyền truy cập chưa đặt là **Anyone**. Sửa ở bước 1.4 rồi deploy lại.
- Trong app: thêm/sửa một khu vực → mở Google Sheet → xuất hiện sheet mới mang tên khu vực.

---

## 4. Bố cục mỗi sheet

```
NHẬT KÝ CANH TÁC AFS
Khu vực | <tên khu vực>
Địa chỉ | <địa chỉ>
Ghi chú | <ghi chú>
Ngày tạo | dd/MM/yyyy
Người dùng | <username>
Cập nhật | dd/MM/yyyy HH:mm

VỤ | <loại cây> · <giống>
Giống | <giống>
Diện tích (m²) | <...>
Số hạt gieo | <...>
Ngày gieo | dd/MM/yyyy
Số cây trồng | <...>
Ngày trồng | dd/MM/yyyy
STT | Ngày trồng | Công việc | Ngày thực hiện | Ghi chú | Ảnh 1 | Ảnh 2 | ...
1   | ... | ... | ... | ... | <ảnh minh chứng> | <ảnh thứ 2> | ...
... (vụ tiếp theo)
```

- Sheet ẩn `_AFS_INDEX` lưu ánh xạ `UUID khu vực → tên sheet` (đừng xoá).
- **Ảnh minh chứng gửi kèm thật** (app co nhỏ ~480px, nén JPEG trước khi gửi); Apps Script giải mã base64 và gắn ảnh trực tiếp vào sheet ở các cột "Ảnh 1, Ảnh 2, ...". Ảnh gốc vẫn được giữ nguyên trên máy.

---

## 5. Cách hoạt động trong code

- `AppState` gọi `syncToSheet(_:)` sau `addArea` / `updateArea` / `updateArea(id:transform:)`.
- Xoá khu vực → gọi `GoogleSheetService.deleteArea(...)` để xoá sheet tương ứng.
- `GoogleSheetService` đóng gói `Area → Crop → WorkLog` thành JSON (ảnh nén thành base64) và `POST` lên Web App (`dataTask`, không chặn giao diện).
- Vì gửi **ghi đè toàn bộ khu vực** mỗi lần lưu, sheet luôn phản ánh đúng trạng thái hiện tại.

---

## 6. Xử lý sự cố

| Hiện tượng | Cách xử lý |
|---|---|
| Mở `/exec` ra trang đăng nhập | Quyền truy cập chưa là **Anyone**. Sửa ở bước 1.4, deploy lại. |
| Sửa code mà không thấy đổi | Chưa tạo **version mới** khi deploy (bước 1 lưu ý). |
| Không thấy sheet mới | Kiểm tra `SPREADSHEET_ID` đúng sheet; app đã đăng nhập; mạng OK. |
| Sheet không cập nhật nhật ký mới | Mỗi lần lưu app gửi lại cả khu vực; thử thêm/sửa rồi mở lại Sheet. |
| Thấy số cột "Ảnh 1, Ảnh 2" nhưng không thấy ảnh | Phần lớn do app cài trên máy còn bản cũ (chỉ gửi số ảnh). Cài lại bản app mới nhất rồi lưu khu vực. |
| Báo lỗi quyền khi deploy | Chọn lại **Execute as: Me**, hoàn tất màn hình cấp quyền (Advanced → Allow). |
