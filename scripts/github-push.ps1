# Đăng nhập GitHub lần đầu + tạo repo + push — chạy 1 lần duy nhất.
# Yêu cầu: có tài khoản tại https://github.com/join
# Cách chạy: mở PowerShell mới, gõ:
#   & ".\scripts\github-push.ps1"
# hoặc (sau khi cài gh xong): powershell -ExecutionPolicy Bypass -File scripts\github-push.ps1

$ErrorActionPreference = "Stop"

# Nạp lại PATH để thấy gh (mới cài qua winget cần mở cửa sổ mới)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

$gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
if (-not $gh) { $gh = "C:\Program Files\GitHub CLI\gh.exe" }
if (-not (Test-Path $gh)) { throw "Khong tim thay gh. Chay: winget install --id GitHub.cli" }

& $gh auth login || exit 1
& $gh auth status || exit 1

# Tạo repo public + đẩy code hiện tại lên
& $gh repo create nhat-ky-canh-tac --public --source . --remote origin --push

if ($?) {
  Write-Host ""
  Write-Host "OK! Repo: https://github.com/$(& $gh api user --jq '.login')/nhat-ky-canh-tac" -ForegroundColor Green
  Write-Host "Workflow build .ipa dang san sang: moi lan push thuong xuyen de tu dong build."
} else {
  Write-Host "Repo co the da ton tai. Thu: git remote -v ; git push -u origin main" -ForegroundColor Yellow
}