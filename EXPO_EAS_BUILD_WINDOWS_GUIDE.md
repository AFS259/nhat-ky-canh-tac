# HƯỚNG DẪN: BUILD ỨNG DỤNG iOS TRÊN WINDOWS BẰNG EXPO EAS BUILD (KHÔNG CẦN MAC)

> Mục tiêu: Build file cài đặt iOS (.ipa) hoặc link cài qua EAS trên Windows, sử dụng gói **EAS Free**. Ưu tiên dùng **Internal/Development Distribution** để cài nhanh lên iPhone cá nhân.

## PHẦN 1: KIỂM TRA CÔNG CỤ CẦN CÀI

Đảm bảo các công cụ sau đã có trên Windows:

| Công cụ | Kiểm tra | Ghi chú |
|---|---|---|
| [Node.js LTS](https://nodejs.org/) | `node --version` → v20+ (bạn đang v24.16.0 OK) | Khuyên dùng LTS |
| [npm](https://www.npmjs.com/) | `npm --version` | Cài cùng Node.js |
| [Git](https://git-scm.com/download/win) | `git --version` | Để quản lý source code |
| [eas-cli](https://docs.expo.dev/eas/cli/) | `npx --yes eas-cli --version` → 24.x+ | Gọi qua `npx` hoặc cài toàn cục |

**Cài eas-cli toàn cục (tùy chọn):**
```powershell
npm install -g eas-cli
eas --version
```

## PHẦN 2: TẠO TÀI KHOẢN EXPO & LIÊN KẾT DỰ ÁN

1. Truy cập [expo.dev/signup](https://expo.dev/signup) tạo tài khoản miễn phí.
2. Mở PowerShell tại thư mục dự án:

```powershell
cd "C:\Summary_FILE\PROJECT_DESIGNER\VISUAL_CODE\PROJECT_IOS\NHAT_KY_CANH_TAC"
```

3. Đăng nhập Expo bằng CLI:

```powershell
npx eas-cli login
```

> Sẽ mở trình duyệt để đăng nhập. Hoàn tất rồi quay lại terminal.

4. Liên kết project với Expo (nếu chưa liên kết):

```powershell
npx eas-cli init
```

Chọn các tùy chọn:
- Existing project → chọn dự án hiện tại
- Đặt tên slug (ví dụ: `nhat-ky-canh-tac-afs`) — giữ ngắn gọn
- Chọn `Yes` để tạo `app.json`/`app.config.js` nếu chưa có

Sau bước này sẽ tạo file `eas.json` (nếu chưa tồn tại).

## PHẦN 3: CẤU HÌNH eas.json CHUẨN CHO iOS INTERNAL/DEVELOPMENT

File `eas.json` nằm gốc dự án. Thay nội dung bằng cấu hình dưới đây (phù hợp build miễn phí + cài thử nhanh).

Tạo/sửa `eas.json`:

```json
{
  "cli": {
    "version": ">= 24.0.0",
    "appVersionSource": "local"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "simulator": false,
        "buildConfiguration": "Debug"
      }
    },
    "internal": {
      "distribution": "internal",
      "ios": {
        "simulator": false,
        "buildConfiguration": "Release"
      }
    },
    "preview": {
      "distribution": "internal",
      "ios": {
        "simulator": false,
        "buildConfiguration": "Release"
      }
    },
    "production": {
      "ios": {
        "buildConfiguration": "Release"
      }
    }
  },
  "submit": {
    "production": {}
  }
}
```

**Giải thích nhanh:**
- `development` — dùng kèm [Expo Dev Client](https://docs.expo.dev/develop/development-builds/overview/) (live reload). Phù hợp test nhanh.
- `internal`/`preview` — **khuyên dùng nhất** để cài trực tiếp lên iPhone qua link/QR (không cần App Store). Đây là bản Release rút gọn cho test nội bộ.
- `production` — dành build nộp App Store (TestFlight/App Store).

> Với mục tiêu "cài lên iPhone cá nhân", bạn chỉ cần dùng profile `internal` hoặc `preview`.

## PHẦN 4: KIỂM TRA THÔNG TIN APP (app.json/app.config.ts)

Mở `app.json` (hoặc `app.config.js/ts`) và đảm bảo có ít nhất các trường sau:

```json
{
  "expo": {
    "name": "Nhật ký canh tác AFS",
    "slug": "nhat-ky-canh-tac-afs",
    "version": "1.0.0",
    "icon": "./assets/icon.png",
    "ios": {
      "bundleIdentifier": "com.autofusionsystem.nhatkycanhtac",
      "supportsTablet": false,
      "infoPlist": {
        "NSCameraUsageDescription": "Ứng dụng cần quyền truy cập camera để chụp ảnh trong nhật ký canh tác."
      }
    },
    "android": { ... }
  }
}
```

**Lưu ý quan trọng:**
- `bundleIdentifier` phải **duy nhất** toàn cầu cho iOS (giống bạn đang dùng: `com.autofusionsystem.nhatkycanhtac`).
- Nếu chưa có `assets/icon.png`, bạn có thể tạm bỏ qua để build thử, nhưng nộp App Store sẽ yêu cầu icon chuẩn.

## PHẦN 5: BUILD iOS LÊN CLOUD EXPO EAS

Mở terminal tại gốc dự án. Chạy lần lượt các lệnh sau.

### Bước 5.1: Kiểm tra cấu hình

```powershell
npx eas-cli build:configure
```

### Bước 5.2: Gửi lệnh build iOS (profile INTERNAL — khuyên dùng)

Dùng profile `internal` để nhận link cài nhanh:

```powershell
npx eas-cli build --platform ios --profile internal --non-interactive
```

Hoặc nếu muốn hỏi theo từng bước:

```powershell
npx eas-cli build --platform ios --profile internal
```

**Các profile khác (tùy nhu cầu):**
- Development build (cần Dev Client): `npx eas-cli build --platform ios --profile development`
- Preview/Internal nhanh: `npx eas-cli build --platform ios --profile preview`
- Production (nộp store): `npx eas-cli build --platform ios --profile production`

> **Quan trọng:** Với gói **Expo EAS Free**, bạn vẫn được build iOS trên cloud macOS của Expo. Việc này **KHÔNG yêu cầu bạn có Mac local**.

## PHẦN 6: XÁC THỰC CHỨNG CHỈ iOS (FIRST TIME BUILD)

Lần build iOS đầu tiên, EAS sẽ hỏi cách quản lý **signing credentials**.

Khi prompt hiện ra, chọn một trong hai:

| Lựa chọn | Khuyến nghị | Giải thích |
|---|---|---|
| **Let EAS handle it for me (recommended)** | ★★★ Rất khuyên dùng | Expo tự tạo Ad Hoc Distribution Certificate + Provisioning Profile miễn phí. Phù hợp cài lên iPhone cá nhân/test nội bộ. |
| **Use credentials from my Apple Developer account** | Chỉ khi đã có Apple ID Developer ($99) | Chỉ cần khi bạn muốn build Production trực tiếp chuẩn App Store/TestFlight. Với mục tiêu test nhanh, **không bắt buộc**. |

**Với Free tier:** chọn `Let EAS handle it for me` là đủ để build `internal/preview` và cài lên iPhone qua link.

## PHẦN 7: THEO DÕI BUILD & LẤY LINK CÀI

Sau khi chạy lệnh, terminal sẽ hiển thị:

- Link theo dõi build: `https://expo.dev/accounts/.../projects/.../builds/...`
- Hoặc mở trình duyệt tự động

Bạn có thể theo dõi trực tiếp trên web:
- Trạng thái: `in queue` → `building` → `finished`
- Thời gian thường 10–20 phút (lần đầu có thể lâu hơn)

Khi build **finished (succeeded)**, trên trang build sẽ có:

- **Install QR Code** — quét bằng iPhone để cài
- **Install URL** — mở bằng Safari trên iPhone để cài
- Tùy profile: có thể tải file `.ipa` (với internal/preview)

## PHẦN 8: CÀI ỨNG DỤNG LÊN iPHONE

### Cách A: Quét QR Code (nhanh nhất)

1. Mở trình duyệt Expo build link trên máy tính → hiện QR "Install"
2. Mở **Camera** app trên iPhone → quét QR
3. Chạm **Open in Expo Go?** hoặc **Install** theo hướng dẫn → cài app

### Cách B: Mở link trực tiếp trên iPhone

1. Copy link install từ trang build
2. Mở link đó bằng **Safari** trên iPhone
3. Chạm **Install** → xác nhận cài đặt
4. Vào `Cài đặt > Cài đặt chung > Quản lý thiết bị & VPN > [Developer/App Profile]` → **Tin cậy** profile rồi quay về màn hình chính mở app

> Với **Ad Hoc** (do EAS tự tạo), thiết bị iPhone của bạn phải được liệt kê trong provisioning profile. Lần cài đầu tiên qua link, EAS sẽ yêu cầu bạn **đăng nhập Apple ID** trên trang web để thêm UDID thiết bị tự động. Làm theo hướng dẫn trên trình duyệt là xong.

### Cách C: Dùng TestFlight (sau khi có Apple Developer)

Nếu bạn đăng ký Apple Developer Program ($99/năm), bạn có thể dùng `eas submit` để đẩy lên TestFlight:

```powershell
npx eas-cli submit --platform ios --profile production
```

Nhưng với mục tiêu **cài ngay không cần $99**, bạn **KHÔNG cần** bước này. Hãy dùng **Internal Distribution (Cách A/B)**.

## PHẦN 9: CHECKLIST COPY-PASTE NHANH

Chạy theo thứ tự này trên PowerShell (tại gốc dự án):

```powershell
# 1. Login
npx eas-cli login

# 2. Init (chỉ chạy 1 lần nếu chưa có eas.json)
npx eas-cli init

# 3. Build internal cho iOS
npx eas-cli build --platform ios --profile internal --non-interactive
```

**Khi build xong:** quét QR bằng Camera/Safari trên iPhone → cài → tin cậy profile (nếu được hỏi) → chạy app.

## MẸO NHANH

- **Không cần Mac/Xcode**: Toàn bộ build chạy trên cloud macOS của Expo.
- **Miễn phí**: Đủ dùng `internal/preview` cho test cá nhân/nội bộ.
- **Build lại nhanh**: Chỉ sửa code → chạy lại lệnh build ở trên.
- **Xem lịch sử build**: [expo.dev/builds](https://expo.dev/builds)
- **EAS CLI cập nhật**: `npm install -g eas-cli@latest`

---

**Tài liệu tham khảo:** [Expo EAS Build Docs](https://docs.expo.dev/build/introduction/) | [Internal Distribution](https://docs.expo.dev/build/internal-distribution/) | [App Signing](https://docs.expo.dev/app-signing/app-credentials/)