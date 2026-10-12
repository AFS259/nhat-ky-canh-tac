# Hướng dẫn build .ipa & cài lên iPhone (qua GitHub Actions + AltStore)

Máy Windows không build được iOS, nên ta tận dụng GitHub Actions **macOS runner** để build, ký và trả về file `.ipa`, sau đó cài bằng **AltStore/AltServer** trên Windows. Cần có **một chiếc Mac** lấy giấy phép ký **1 lần duy nhất**; từ đó mọi build sau đều tự động.

---

## Bước 1 — Đưa project lên GitHub

```bash
git init
git add .
git commit -m "Nhat Ky Canh Tac AFS"
git branch -M main
git remote add origin https://github.com/<TEN_NGUOI_DUNG>/nhat-ky-canh-tac.git
git push -u origin main
```

Workflow đã nằm sẵn ở `.github/workflows/build-ipa.yml`.

---

## Bước 2 — Tạo chứng chỉ + provisioning profile trên Mac (1 lần)

Dùng **cùng Apple ID** sẽ dùng để cài app. Không cần tài khoản trả phí ($99).

1. Mở Xcode → `Preferences → Accounts` → **+** thêm Apple ID.
2. Chọn Apple ID → `Manage Certificates...` → **+ → Apple Development** (tạo chứng chỉ ký).
3. Note xuống **Team ID** (sinh 10 ký tự, nằm ở footer dưới tên team trong mục Accounts).
4. Tạo provisioning profile:
   - Mở file project (`NhatKyCanhTacAFS.xcodeproj`) trên Mac, chọn target → *Signing & Capabilities* → Team = chính team Apple ID vừa thêm. Xcode tự sinh profile **"iOS Team Provisioning Profile: com.autofusionsystem.nhatkycanhtac"**.
   - Tìm file: `~/Library/MobileDevice/Provisioning Profiles/` (chọn file mới nhất, mở ra xem tên chứa `com.autofusionsystem.nhatkycanhtac`).
5. Xuất chứng chỉ dạng p12:
   - Mở `Keychain Access` → tab **My Certificates** → chuột phải chứng chỉ **Apple Development: <tên Apple ID>** → `Export "..."` → định dạng `.p12`, đặt **mật khẩu p12** (nhớ nó).
6. Mã hóa base64 2 file trong Terminal:
   ```bash
   base64 -i Certificates.p12     -o cert.b64
   base64 -i <profile>.mobileprovision -o profile.b64
   cat cert.b64     # copy nguyên văn (1 dòng dài)
   cat profile.b64  # copy nguyên văn
   ```

---

## Bước 3 — Đặt GitHub Secrets

Vào repo GitHub → `Settings → Secrets and variables → Actions` → **New repository secret**:

| Tên secret          | Giá trị |
|---------------------|---------|
| `IOS_CERT_BASE64`   | Nội dung `cert.b64` (dán vào) |
| `IOS_CERT_PASSWORD` | Mật khẩu p12 |
| `IOS_PROVPROFILE_BASE64` | Nội dung `profile.b64` |
| `IOS_TEAM_ID`       | Team ID 10 ký tự ở Bước 2 |

---

## Bước 4 — Chạy build & tải .ipa

- Vào tab **Actions** của repo → chọn workflow **Build iOS IPA** → **Run workflow** (hoặc cứ mỗi push lên `main` là tự chạy).
- Khi xong: tải artifact **`NhatKyCanhTacAFS.ipa`** (góc dưới phần "Artifacts").

---

## Bước 5 — Cài lên iPhone bằng AltStore (trên Windows)

1. Tải **AltServer** tại https://altstore.io, cài trên Windows.
2. **Phải tắt** iCloud/Windows Defender quạy can thiệp nếu AltServer không bắt nổi iPhone (theo troubleshoot của AltStore).
3. iPhone cắm USB → chạy AltServer → biểu tượng trên thanh tray → `Install AltStore` → chọn iPhone, nhập Apple ID (cùng ID ở Bước 2, mật khẩu có thể cần **App-Specific Password** nếu iPhone đang bật 2FA).
4. Mở **AltStore** trên iPhone → đăng nhập cùng Apple ID.
5. Đưa file `.ipa` vào iPhone (AirDrop / Files / Safari) → mở bằng **AltStore → Install**.
6. iPhone: `Settings → General → VPN & Device Management` → **Trust** developer profile → mở app **Nhật ký canh tác**.

---

## Ghi chú

- Không có tài khoản trả phí → app chỉ **7 ngày** phải ký lại. AltStore tự re-sign mỗi ngày khi iPhone cùng Wi-Fi với máy có AltServer. Nếu hết hạn: chạy lại workflow (Bước 4) rồi cài lại là xong.
- App chưa cần bất kỳ capability đặc biệt nào ngoài **Camera** (đã khai báo trong source: `NSCameraUsageDescription`).
- Nếu build fail "no profiles": kiểm tra `IOS_PROVPROFILE_BASE64` đúng profile, và `IOS_TEAM_ID` đúng.
- Muốn test nhanh không cần Mac: mở `demo.html` trong trình duyệt để duyệt toàn bộ luồng (tài khoản demo `afs` / `1234`).