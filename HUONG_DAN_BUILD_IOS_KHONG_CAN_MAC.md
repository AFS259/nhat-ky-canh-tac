# HƯỚNG DẪN BUILD & CÀI APP "NHẬT KÝ CANH TÁC AFS" LÊN IPHONE KHÔNG CẦN MACBOOK

> Dành cho: dự án **native SwiftUI** tại `NhatKyCanhTacAFS.xcodeproj`
> Bundle ID: `com.autofusionsystem.nhatkycanhtac` | Tên hiển thị: **Nhật Ký Canh Tác** | iOS 16.0+ (iPhone & iPad)
> Repo: `https://github.com/AFS259/nhat-ky-canh-tac`
> Nền tảng thao tác: **Windows + PowerShell**. Không cần sở hữu MacBook.

---

## 0. TÓM TẮT CÁCH LÀM (đọc trước)

Máy Windows **không biên dịch được iOS** (cần toolchain Xcode/macOS). Vì vậy ta chia việc thành 2 nửa:

| Việc | Làm ở đâu | Công cụ |
|---|---|---|
| Biên dịch + đóng gói `.ipa` | **Cloud macOS** (GitHub Actions runner `macos-15`) | Workflow `.github/workflows/build-ipa.yml` đã có sẵn |
| Ký (sign) + cài lên iPhone | **Máy Windows của bạn** | **Sideloadly** (dùng Apple ID miễn phí) |

**Điểm mấu chốt:** workflow hiện tại build ra **IPA KHÔNG KÝ (unsigned)**. File này KHÔNG cài trực tiếp được. Bạn dùng **Sideloadly** trên Windows để nó **ký lại bằng Apple ID của bạn** rồi đẩy vào iPhone qua cáp USB. Toàn bộ quá trình **không cần Mac**, chỉ cần một Apple ID (không cần trả $99).

Kết quả: app chạy trên iPhone, hiệu lực **7 ngày/lần ký** (giới hạn của Apple ID miễn phí). Hết hạn thì chạy lại 1 lệnh — mất vài phút.

---

## 1. ĐIỀU KIỆN CẦN CÓ

| Thứ cần | Ghi chú |
|---|---|
| Tài khoản GitHub | Repo đã có sẵn: `AFS259/nhat-ky-canh-tac` |
| Apple ID thường | Dùng để ký app miễn phí. Bật 2FA thì cần thêm **App-Specific Password** (xem Mục 6) |
| iPhone | iOS 16.0 trở lên |
| Cáp USB (Lightning/USB-C) | Cắm iPhone vào máy Windows |
| iTunes (bản Microsoft Store) | Sideloadly cần driver Apple để nhận iPhone |
| Sideloadly | Tải tại https://sideloadly.io |

---

## 2. BƯỚC 1 — ĐƯA CODE LÊN GITHUB (nếu chưa có)

Repo đã tồn tại nên thường chỉ cần commit & push thay đổi mới:

```powershell
git add -A
git commit -m "update"
git push origin main
```

Nếu làm máy mới chưa clone:

```powershell
git clone https://github.com/AFS259/nhat-ky-canh-tac.git
```

> Mỗi lần push lên nhánh `main`, workflow sẽ **tự động chạy build**.

---

## 3. BƯỚC 2 — ĐỂ GITHUB ACTIONS BUILD IPA (trên cloud macOS)

### 3.1 Cơ chế workflow hiện có

File `.github/workflows/build-ipa.yml` làm các việc sau trên runner `macos-15`:

1. Checkout code.
2. In phiên bản Xcode (`xcodebuild -version`).
3. `xcodebuild ... archive` với **tắt hoàn toàn code signing**:
   `CODE_SIGNING_ALLOWED=NO`, `CODE_SIGNING_REQUIRED=NO`, `CODE_SIGN_IDENTITY=""`.
4. Đóng gói thư mục `Payload/` thành `NhatKyCanhTacAFS.ipa` (IPA **unsigned**).
5. Upload artifact `NhatKyCanhTacAFS-unsigned.ipa`.
6. Phát hành file lên **GitHub Release** với tag cố định `unsigned-latest` để có link tải trực tiếp.

### 3.2 Kích hoạt build

**Cách A — Tự động:** push code lên `main` (xem Bước 1).

**Cách B — Thủ công:**
- Vào `https://github.com/AFS259/nhat-ky-canh-tac/actions`
- Chọn workflow **Build iOS IPA (unsigned)** → nút **Run workflow** → chọn nhánh `main` → **Run workflow**.

Theo dõi: trạng thái chuyển `queued` → `in progress` → dấu tích xanh ✅. Lần đầu ~10–20 phút.

### 3.3 Lấy file .ipa

Sau khi build xong, tải ở MỘT trong hai chỗ:

- **Artifacts:** trong trang của lần chạy workflow → mục **Artifacts** → tải `NhatKyCanhTacAFS-unsigned.ipa` (dạng .zip, giải nén ra .ipa).
- **Release (tiện hơn, link trực tiếp):**
  `https://github.com/AFS259/nhat-ky-canh-tac/releases/tag/unsigned-latest`
  → tải `NhatKyCanhTacAFS.ipa`.

> Xem log lỗi: trong workflow run → chọn step bị đỏ. Nếu build fail, workflow còn tự commit file `build.log.txt` vào repo để bạn soi.

---

## 4. BƯỚC 3 — CÀI LÊN IPHONE BẰNG SIDELOADLY (trên Windows)

Sideloadly ký lại file IPA unsigned bằng Apple ID của bạn rồi cài qua USB.

### 4.1 Chuẩn bị

1. Cài **iTunes** (bản từ Microsoft Store) và **iCloud** bản Windows để có driver nhận iPhone. Mở iTunes một lần cho nó nhận diện thiết bị rồi có thể đóng.
2. Tải & cài **Sideloadly**: https://sideloadly.io (chọn bản Windows).
3. Cắm iPhone vào máy tính bằng cáp, bấm **Trust** trên iPhone khi được hỏi.

### 4.2 Thực hiện

1. Mở **Sideloadly**.
2. **IPA**: kéo/thả hoặc chọn file `NhatKyCanhTacAFS.ipa` đã tải ở Bước 3.3.
3. **Apple ID**: nhập Apple ID sẽ dùng để ký (mục `iOS device`, dòng Apple ID).
4. Chọn **iPhone** đúng ở ô thiết bị (nếu chưa hiện, rút cắm lại cáp).
5. Bấm **Start**. Nhập **mật khẩu Apple ID** khi được hỏi.
   - Nếu Apple ID bật 2FA: Sideloadly sẽ yêu cầu **App-Specific Password** thay vì mật khẩu thường (xem Mục 6 để tạo).
6. Chờ Sideloadly báo `Done`. App **Nhật Ký Canh Tác** xuất hiện trên màn hình chính.

### 4.3 Tin cậy (Trust) để mở được app

Lần đầu mở app sẽ báo lỗi nhà phát triển chưa tin cậy. Trên iPhone:

`Cài đặt (Settings) → Cài đặt chung (General) → Quản lý VPN & thiết bị (VPN & Device Management) → chọn tên Apple ID của bạn → Tin cậy (Trust)`.

Quay về màn hình chính → mở app. Xong.

---

## 5. BƯỚC 4 — KÝ LẠI KHI HẾT HẠN (mỗi 7 ngày)

Apple ID miễn phí chỉ cho phép app ký có hiệu lực **7 ngày**. Hết hạn app không mở được, phải ký lại:

1. (Tùy chọn) Nếu muốn dùng code mới nhất: chạy lại Bước 2 để lấy IPA mới.
2. Mở Sideloadly → chọn lại file `.ipa` → **Start** (dùng cùng Apple ID như trước).

> Không cần build lại trên GitHub nếu code không đổi — có thể ký lại chính file `.ipa` đã tải. Chỉ mất vài phút.

**Mẹo tự động hóa (tùy chọn):** Dùng **AltStore + AltServer** trên Windows để tự ký lại mỗi ngày khi iPhone cùng Wi-Fi với máy tính. Xem Mục 7.

---

## 6. APP-SPECIFIC PASSWORD CHO APPLE ID (khi bật 2FA)

Nếu Sideloadly báo lỗi đăng nhập vì 2FA:

1. Mở https://account.apple.com → đăng nhập.
2. Vào **Sign-In and Security → App-Specific Passwords**.
3. Tạo mật khẩu mới, đặt tên ví dụ `Sideloadly` → copy chuỗi vừa sinh.
4. Trong Sideloadly, dán chuỗi đó vào ô mật khẩu.

---

## 7. PHƯƠNG ÁN THAY THẾ

### 7.1 AltStore / AltServer (tự ký lại mỗi 7 ngày)

- Tải AltServer tại https://altstore.io, cài trên Windows.
- Cắm iPhone → biểu tượng AltServer ở khay hệ thống → **Install AltStore** → chọn iPhone, nhập Apple ID.
- Mở **AltStore** trên iPhone (đăng nhập cùng Apple ID) → mở file `.ipa` bằng **AltStore → Install**.
- AltStore sẽ tự ký lại app khi iPhone cùng Wi-Fi với máy có AltServer, khỏi phải thao tác thủ công mỗi tuần.
- Lưu ý: đôi khi iCloud/Windows Defender chặn AltServer — thử tạm tắt nếu không nhận thiết bị.

### 7.2 Tài khoản Apple Developer Program ($99/năm)

Nếu cần **không giới hạn 7 ngày**, cài nhiều máy, hoặc phát hành **TestFlight/App Store**:

- Đăng ký tại https://developer.apple.com/programs/.
- Tạo **Distribution Certificate** + **Provisioning Profile (Ad Hoc / App Store)**.
- Có thể build bản **signed** ngay trong GitHub Actions bằng cách nạp secrets (base64 cert + profile + Team ID) và bỏ các cờ tắt signing — hoặc dùng Xcode Cloud.
- Với TestFlight: upload IPA rồi mời người test qua app TestFlight, hiệu lực 90 ngày/lần.

### 7.3 Thuê Mac cloud (khi bắt buộc cần Xcode giao diện)

Các dịch vụ như **MacinCloud**, **MacStadium**, **Scaleway Mac mini**: thuê macOS qua RDP/VNC, mở Xcode như máy thật rồi build/archive/deploy. Có phí theo giờ/tháng. Chỉ nên dùng khi cần debug trực tiếp trên Simulator/Instruments.

---

## 8. XỬ LÝ SỰ CỐ THƯỜNG GẶP

| Triệu chứng | Nguyên nhân & cách xử lý |
|---|---|
| Workflow fail ngay ở bước archive | Xem log; thường do scheme/tên target sai. Kiểm tra tên scheme là `NhatKyCanhTacAFS`. |
| Không thấy mục **Artifacts** | Build chưa xong, hoặc đang xem nhầm run. Đợi tới khi có ✅. |
| Sideloadly không nhận iPhone | Cài iTunes (Store) + iCloud bản Windows; đổi cáp/đổi cổng USB; bấm **Trust** trên iPhone; khởi động lại Sideloadly. |
| Sideloadly báo sai mật khẩu | Apple ID bật 2FA → dùng **App-Specific Password** (Mục 6). |
| Cài xong mở app báo "Untrusted Developer" | Vào `Cài đặt → Cài đặt chung → Quản lý VPN & Thiết bị → Trust` (Mục 4.3). |
| App tự dưng không mở được sau vài ngày | Chứng chỉ 7 ngày hết hạn → ký lại bằng Sideloadly (Bước 4). |
| `bundle identifier` bị trùng/không hợp lệ | Đảm bảo `com.autofusionsystem.nhatkycanhtac` là duy nhất; Sideloadly có thể tự đổi thành hậu tố khi cần. |

---

## 9. CHECKLIST COPY-PASTE

```powershell
# 1) Đẩy code (kích hoạt build tự động trên GitHub Actions)
git add -A
git commit -m "update build"
git push origin main

# 2) Vào https://github.com/AFS259/nhat-ky-canh-tac/actions để xem build
#    Hoặc tải IPA trực tiếp tại:
#    https://github.com/AFS259/nhat-ky-canh-tac/releases/tag/unsigned-latest

# 3) Mở Sideloadly -> chọn file NhatKyCanhTacAFS.ipa -> nhập Apple ID -> Start
# 4) Trên iPhone: Settings > General > VPN & Device Management > Trust
```

---

## 10. THÔNG TIN KỸ THUẬT DỰ ÁN (tham khảo)

| Trường | Giá trị |
|---|---|
| Loại app | Native SwiftUI (Xcode project) |
| File project | `NhatKyCanhTacAFS.xcodeproj` |
| Scheme | `NhatKyCanhTacAFS` |
| Bundle ID | `com.autofusionsystem.nhatkycanhtac` |
| Tên hiển thị | Nhật Ký Canh Tác |
| Phiên bản | 1.1 (build 2) |
| Deployment target | iOS 16.0 |
| Thiết bị | iPhone + iPad |
| Quyền cần | Camera, Thư viện ảnh (khai báo trong `project.pbxproj` qua `INFOPLIST_KEY_*`) |
| Runner build | `macos-15` (GitHub Actions) |
| Workflow | `.github/workflows/build-ipa.yml` |
| Tag Release IPA | `unsigned-latest` |

---

## 11. VÌ SAO KHÔNG DÙNG FILE `EXPO_EAS_BUILD_WINDOWS_GUIDE.md`?

Dự án này là **app native SwiftUI**, KHÔNG phải dự án Expo/React Native, nên **EAS Build không áp dụng được**. Hãy dùng quy trình trong tài liệu này (GitHub Actions + Sideloadly). File `EXPO_EAS_BUILD_WINDOWS_GUIDE.md` chỉ mang tính tham khảo nếu sau này bạn chuyển sang Expo.

---

**Tài liệu liên quan:** `IOS_BUILD_GUIDE.md` (bản tóm tắt cũ) | Workflow: `.github/workflows/build-ipa.yml` | Script hỗ trợ: `scripts/github-push.ps1`
