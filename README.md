# 🚀 IoT electricity and water management & Monitoring System

Hệ thống thu thập, nhận diện dữ liệu cảm biến qua giao thức **Bluetooth Low Energy (BLE)**, đồng bộ hóa thời gian thực lên **Firebase** và hiển thị trên ứng dụng di động **Flutter**.

---

## ✨ Tính năng chính
* **Kết nối BLE:** Tự động quét và kết nối với các thiết bị IoT (ESP32/nRF52).
* **Xử lý dữ liệu:** Tạo dữ liệu thô mô phỏng cảm biến
* **Đồng bộ Firebase:** Tự động đẩy dữ liệu lên Realtime Database.
* **Giao diện trực quan:** Hiển thị biểu đồ theo dõi và thông số tức thời trên ứng dụng di động.
* **Quản lý lịch sử:** Lưu trữ và xem lại dữ liệu đã thu thập từ đám mây.

---

## 🏗 Kiến trúc hệ thống
1.  **Lớp Thiết bị (Peripheral):** Các Node cảm biến sử dụng ESP32 đọc dữ liệu qua giao thức BLE.
2.  **Lớp Cổng (Central/Mobile App):** Điện thoại đóng vai trò là Gateway nhận dữ liệu BLE và truyền lên Cloud.
3.  **Lớp Lưu trữ (Cloud):** Firebase quản lý dữ liệu, xác thực người dùng và gửi thông báo.

---

## 🛠 Công nghệ sử dụng

| Thành phần | Công nghệ / Linh kiện |
| :--- | :--- |
| **Vi điều khiển** | ESP32 (Hỗ trợ Dual-mode Bluetooth) |
| **Ứng dụng di động** | Flutter (Dart) |
| **Cơ sở dữ liệu** | Firebase (Realtime Database) |
| **Giao thức** | BLE (Bluetooth Low Energy 4.2/5.0) |

---

## 🚀 Cài đặt & Sử dụng

### 1. Đối với phần cứng (Firmware)
* Mở mã nguồn trong thư mục `firmware/` bằng Arduino IDE.
* Cài đặt thư viện `ESP32 BLE Arduino`.
* Nạp code vào kit ESP32.

### 2. Đối với ứng dụng di động (Mobile App)
* Yêu cầu: Đã cài đặt **Flutter SDK** và cấu hình **Android Studio**.
* Tải các thư viện cần thiết:
    ```bash
    flutter pub get
    ```
* Cấu hình file `google-services.json` từ Firebase Console vào thư mục `android/app/`.
* Chạy ứng dụng trên thiết bị thật (yêu cầu bật Bluetooth và Định vị):
    ```bash
    flutter run
    ```
