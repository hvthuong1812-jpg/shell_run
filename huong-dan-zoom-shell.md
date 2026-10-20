# Cấu hình Zoom Rooms chạy toàn màn hình (thay Explorer) cho một tài khoản Windows

Mục tiêu: tài khoản **suca** đăng nhập là vào thẳng **Zoom Rooms**, không chạy Explorer.
Tài khoản **Admin** và các tài khoản khác vẫn dùng Windows bình thường, không tự mở Zoom.

## Điều kiện
- Windows **Enterprise, Education hoặc IoT Enterprise** (Shell Launcher không có trên Home/Pro).
- Đã cài **Zoom Rooms for Windows** cho **mọi người dùng** (nằm trong `C:\Program Files\ZoomRooms\`).
- Đã có tài khoản Admin để sửa cấu hình khi cần.
- Zoom Rooms cần **license Zoom Rooms** và **activation code** (tạo ở zoom.us → Rooms).

## Các bước

### 1. Tạo tài khoản cục bộ
PowerShell (Admin):
```powershell
net user suca /add
```
Đăng nhập suca một lần bằng giao diện để Windows tạo hồ sơ, rồi đăng xuất.

### 2. Kiểm tra đường dẫn Zoom Rooms
```powershell
Test-Path "C:\Program Files\ZoomRooms\bin\ZoomRooms.exe"
```
Phải ra `True`. Nếu `False`, tìm đường dẫn thật:
```powershell
Get-ChildItem "C:\Program Files*" -Recurse -Filter "ZoomRooms.exe" -ErrorAction SilentlyContinue | Select FullName
```

### 3. Chạy script cấu hình
Dùng file `cau-hinh-zoom-shell.ps1` trong repo này (PowerShell Admin):
```powershell
.\cau-hinh-zoom-shell.ps1 -UserName suca
```
- Lần đầu có thể phải **khởi động lại** sau khi bật tính năng Shell Launcher, rồi chạy lại script.
- Gỡ cấu hình: `.\cau-hinh-zoom-shell.ps1 -UserName suca -Remove`

### 4. Tự đăng nhập suca khi bật máy (tùy chọn)
- `Win + R` → `netplwiz` → chọn suca → bỏ tích "Users must enter a user name and password" → nhập mật khẩu.
- Nếu netplwiz không cho chọn, dùng Registry `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`:
  `AutoAdminLogon=1`, `DefaultUserName=suca`, `DefaultPassword=<mật khẩu>`, `DefaultDomainName=<tên máy>`.
- Mật khẩu trong Registry lưu dạng văn bản thường, chỉ dùng cho máy riêng.
- Muốn bỏ qua tự đăng nhập để vào Admin: giữ phím **Shift** sau màn hình logo.

### 5. Kiểm tra
- Khởi động lại máy.
- Đăng nhập **suca** → vào thẳng Zoom, không có màn hình nền.
- Đăng nhập **Admin** → Explorer bình thường, không có Zoom.

## Nếu Admin hoặc tài khoản khác cũng bị ảnh hưởng
Có cấu hình dùng chung đang áp dụng cho mọi tài khoản. Kiểm tra và dọn:
- Thư mục startup dùng chung: `shell:common startup` (không được có shortcut Zoom).
- Registry: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run` (không được có Zoom).
- `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`, giá trị **Shell** phải là `explorer.exe`.
- Task Scheduler (`taskschd.msc`): tác vụ Zoom/ThinkSmart chạy lúc log on cho mọi người dùng.
- Phần mềm quản lý của Lenovo (ThinkSmart Manager) có thể tự mở Zoom.
- Xóa Default Shell của Shell Launcher nếu có:
```powershell
$SL = [wmiclass]"\\localhost\root\standardcimv2\embedded:WESL_UserSetting"
$SL.RemoveDefaultShell()
```
Xem cấu hình hiện tại:
```powershell
Get-WmiObject -Namespace "root\standardcimv2\embedded" -Class WESL_UserSetting | Select Sid, Shell
```

## Sự cố thường gặp
| Hiện tượng | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| suca ra **màn hình đen + con trỏ chuột** | Sai đường dẫn `ZoomRooms.exe`, hoặc Zoom cài theo từng người dùng | Đăng nhập Admin, kiểm tra đường dẫn, cài lại Zoom Rooms cho mọi người dùng, chạy lại script |
| Vẫn thấy Explorer rồi mới vào Zoom | Shell Launcher chưa áp dụng, Zoom được mở bằng Startup/Registry/Task | Chạy lệnh xem cấu hình ở trên, dọn các mục tự chạy |
| Không có Shell Launcher | Windows Home/Pro | Dùng cách giả kiosk: tự đăng nhập + shortcut Zoom trong `shell:startup` của suca |
| Cần thoát khỏi suca | Không có Explorer/Taskbar | `Ctrl + Alt + Del` → Sign out, rồi đăng nhập Admin |
| `netplwiz` không cho chọn tài khoản | Windows Hello hoặc chính sách | Dùng cách Registry ở bước 4 |

## Cách thay thế bằng Registry (chưa kiểm chứng đầy đủ)
Đặt giá trị `Shell` riêng trong hive của suca (chỉ áp dụng cho suca):
1. Admin mở `regedit`, chọn `HKEY_USERS` → File → **Load Hive** → `C:\Users\suca\NTUSER.DAT`, đặt tên `suca_tmp`.
2. Tạo khóa `HKEY_USERS\suca_tmp\Software\Microsoft\Windows NT\CurrentVersion\Winlogon` nếu chưa có.
3. Tạo String Value `Shell` = `C:\Program Files\ZoomRooms\bin\ZoomRooms.exe`.
4. Chọn `suca_tmp` → File → **Unload Hive**.

Cách này không được Microsoft ghi tài liệu chính thức, nên ưu tiên dùng Shell Launcher.

## Lưu ý
- Luôn giữ một tài khoản Admin bình thường để sửa cấu hình.
- **Không lưu mật khẩu hay activation code Zoom lên GitHub.**
- Khi cài Zoom Rooms, các tùy chọn như "Never put the computer to sleep" hay "Disable Windows auto update" áp dụng cho cả máy.
