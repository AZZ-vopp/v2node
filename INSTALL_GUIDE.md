# Hướng dẫn cài đặt V2Node Manager Pro

## 🚀 **Cách 1: Download và chạy (Khuyên dùng)**

```bash
# Download script
curl -o /tmp/v2node-manager.sh https://raw.githubusercontent.com/AZZ-vopp/v2node/main/script/v2node-manager.sh

# Cấp quyền thực thi
chmod +x /tmp/v2node-manager.sh

# Chạy script
sudo /tmp/v2node-manager.sh
```

## 🔧 **Cách 2: Sử dụng wget**

```bash
# Download
wget -O /tmp/v2node-manager.sh https://raw.githubusercontent.com/AZZ-vopp/v2node/main/script/v2node-manager.sh

# Cấp quyền và chạy
chmod +x /tmp/v2node-manager.sh
sudo /tmp/v2node-manager.sh
```

## ⚡ **Cách 3: One-liner với bash -c**

```bash
curl -Ls https://raw.githubusercontent.com/AZZ-vopp/v2node/main/script/v2node-manager.sh | sudo bash
```

## 🐧 **Cách 4: Clone repository**

```bash
git clone https://github.com/AZZ-vopp/v2node.git
cd v2node/script
sudo bash v2node-manager.sh
```

---

## ❓ **Giải quyết lỗi hostname**

Nếu gặp lỗi `unable to resolve host`, thêm hostname vào /etc/hosts:

```bash
echo "127.0.0.1 $(hostname)" | sudo tee -a /etc/hosts
```

---

## 📋 **Yêu cầu hệ thống**

- **OS:** Debian, Ubuntu, CentOS, Alpine, Arch Linux
- **Quyền:** Root hoặc sudo
- **Packages:** curl hoặc wget, bash
- **Kiến trúc:** x86_64, ARM64, s390x

---

## 🔍 **Kiểm tra trước khi cài**

```bash
# Kiểm tra bash version
bash --version

# Kiểm tra có curl/wget không
which curl || which wget

# Kiểm tra quyền root
id -u  # Phải trả về 0 hoặc dùng sudo
```

---

## 💡 **Lưu ý**

- Luôn dùng `sudo` nếu không phải user root
- Script sẽ tự động cài đặt các dependencies cần thiết (jq)
- Có thể tự động đề xuất cài đặt V2Node nếu chưa có

---

## 📞 **Cần hỗ trợ?**

Tạo issue tại: https://github.com/AZZ-vopp/v2node/issues
