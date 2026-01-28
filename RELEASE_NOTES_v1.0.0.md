# Release Notes - v1.0.0

## 🎉 Phiên bản đầu tiên của V2Node Manager Pro

Đây là phiên bản release chính thức đầu tiên của V2Node với đầy đủ tính năng quản lý và giao diện tiếng Việt.

---

## ✨ **Tính năng chính**

### 🔧 **V2Node Manager Pro**
- ✅ **Quản lý node chuyên nghiệp** với giao diện menu đẹp mắt
- ✅ **Tự động cài đặt V2Node** - Kiểm tra và cài đặt tự động nếu chưa có
- ✅ **Cập nhật V2Node** - Cập nhật lên phiên bản mới nhất một lệnh
- ✅ **Backup tự động** - Backup config trước mỗi lần thay đổi
- ✅ **Khôi phục từ backup** - Quản lý và khôi phục từ các bản backup
- ✅ **Kiểm tra trạng thái** - Xem trạng thái dịch vụ, phiên bản, auto-start

### 📝 **Quản lý Node**
- ✅ **Thêm node** - Hỗ trợ thêm theo phạm vi (ví dụ: 1-5)
- ✅ **Xóa node** - Hỗ trợ xóa theo phạm vi hoặc NodeID (ví dụ: 96-98)
- ✅ **Sửa node** - Chỉnh sửa cấu hình node hiện có
- ✅ **Liệt kê node** - Hiển thị tất cả node với đầy đủ thông tin
- ✅ **Tái sử dụng config** - Dùng lại ApiHost/ApiKey từ node có sẵn

### 🛠️ **Script cài đặt (`install.sh`)**
- ✅ **Tự động phát hiện OS** - Hỗ trợ CentOS, Ubuntu, Debian, Alpine, Arch
- ✅ **Tự động phát hiện kiến trúc** - x86_64, ARM64, s390x
- ✅ **Cài đặt dependencies** - Tự động cài đặt các gói cần thiết
- ✅ **Tạo systemd/OpenRC service** - Tự động khởi động cùng hệ thống
- ✅ **Tạo config tự động** - Hỗ trợ tham số command-line

### 🎮 **Script quản lý (`v2node.sh`)**
- ✅ **Menu quản lý đầy đủ** - 15 tùy chọn quản lý
- ✅ **Quản lý service** - Start, stop, restart, status
- ✅ **Xem log** - Theo dõi log realtime
- ✅ **Auto-start** - Bật/tắt khởi động cùng hệ thống
- ✅ **Cập nhật version** - Cập nhật hoặc cài phiên bản cụ thể
- ✅ **Tạo config** - Tạo file cấu hình tương tác
- ✅ **Mở firewall** - Mở tất cả cổng VPS

---

## 🌐 **Hoàn toàn tiếng Việt**

Tất cả script đã được dịch 100% sang tiếng Việt:
- ✅ Tất cả menu và giao diện
- ✅ Tất cả thông báo lỗi
- ✅ Tất cả prompts và hướng dẫn
- ✅ Tất cả comments trong code

---

## 📦 **Cài đặt nhanh**

### **V2Node Manager Pro**
```bash
sudo bash <(curl -Ls https://raw.githubusercontent.com/AZZ-vopp/v2node/main/script/v2node-manager.sh)
```

### **Cài đặt V2Node**
```bash
bash <(curl -Ls https://raw.githubusercontent.com/AZZ-vopp/v2node/main/script/install.sh)
```

### **Script quản lý V2Node**
```bash
v2node
```

---

## 🔄 **Thay đổi so với bản gốc**

1. ✅ **Dịch toàn bộ sang tiếng Việt** - 100% Vietnamese
2. ✅ **Nâng cấp V2Node Manager lên Pro** - Nhiều tính năng mới
3. ✅ **Thêm auto-install dependencies** - jq, v2node
4. ✅ **Thêm backup/restore** - Bảo vệ cấu hình
5. ✅ **Cải thiện giao diện** - Menu đẹp hơn, rõ ràng hơn
6. ✅ **Kiểm tra quyền root** - Tự động yêu cầu sudo
7. ✅ **Repository của AZZ-vopp** - Tất cả URL đã được cập nhật

---

## 📊 **Thống kê**

- **Tổng số dòng code:** ~1,800 dòng
- **Số file script:** 3 files chính
- **Commits:** 10+ commits
- **Tính năng:** 20+ tính năng

---

## 🙏 **Credits**

- **Original V2Node:** [wyx2685/v2node](https://github.com/wyx2685/v2node)
- **Vietnamese Translation & Pro Features:** [AZZ-vopp](https://github.com/AZZ-vopp)

---

## 📝 **Changelog**

### v1.0.0 (2026-01-28)
- 🎉 First official release
- ✅ Complete Vietnamese translation
- ✅ V2Node Manager Pro with auto-install
- ✅ Backup/restore functionality
- ✅ Enhanced UI and menus
- ✅ All repository URLs updated to AZZ-vopp

---

## 📞 **Support**

Nếu gặp vấn đề, vui lòng tạo issue tại: https://github.com/AZZ-vopp/v2node/issues

---

**Enjoy V2Node Manager Pro! 🚀**
