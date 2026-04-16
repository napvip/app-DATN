# Changelog

Tất cả các thay đổi đáng chú ý của dự án **BeeGuard** sẽ được ghi lại ở đây.

Định dạng theo [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), phiên bản theo [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Tích hợp thông báo push (Firebase Cloud Messaging)
- Hỗ trợ đa ngôn ngữ (Tiếng Anh / Tiếng Việt)
- Xuất báo cáo dữ liệu dạng PDF
- Offline mode với local caching

---

## [1.0.0] — 2026-04-15

### Added
- 🎉 Khởi tạo dự án Flutter với cấu trúc Clean Architecture
- 🔐 Xác thực người dùng qua Firebase Authentication (Email/Password)
- 🏠 Màn hình Dashboard (`home_screen.dart`) — tổng quan tình trạng tổ ong
- 📊 Màn hình Insights (`insights_screen.dart`) — biểu đồ nhiệt độ & độ ẩm bằng fl_chart
- 🔔 Màn hình Alerts (`alerts_screen.dart`) — danh sách cảnh báo bất thường theo thời gian thực
- 🔧 Màn hình Maintenance (`maintenance_screen.dart`) — lịch bảo trì tổ ong
- 👤 Màn hình Profile (`profile_screen.dart`) — quản lý thông tin người dùng, ảnh đại diện
- 🗺️ Navigation với GoRouter 14.x
- ⚡ State management với Flutter Riverpod 2.x
- ☁️ Kết nối Firebase Firestore để lưu trữ dữ liệu tổ ong
- 🗄️ Firebase Storage tích hợp upload ảnh (image_picker)
- 🧩 Hệ thống widgets tái sử dụng (charts, cards, shimmer loading)
- 📁 Cấu trúc Data Layer: Repositories, DataSources, Models
- 🛠️ Cấu hình lint với flutter_lints 5.x
- 📝 `README.md` đầy đủ thông tin, hướng dẫn cài đặt và kiến trúc hệ thống
- 📋 `CHANGELOG.md` — file theo dõi thay đổi (file này)
- 🚫 `.gitignore` cập nhật: loại bỏ `firebase.json`, `google-services.json`, `.free-claude/`

### Changed
- Cập nhật `.gitignore`: thêm `firebase.json` và `.free-claude/` để bảo vệ thông tin nhạy cảm

### Security
- `firebase.json` (chứa project ID, app ID) đã được đưa vào `.gitignore`, không push lên remote
- `google-services.json` và `GoogleService-Info.plist` đã được đưa vào `.gitignore`
- Khuyến nghị sử dụng `flutterfire configure` để tạo `firebase_options.dart` thay vì hardcode credentials

---

## [0.1.0] — 2026-04-10

### Added
- Khởi tạo project Flutter cơ bản
- Tích hợp Firebase vào project (firebase_core, firebase_auth, cloud_firestore, firebase_storage)
- Thiết lập pubspec.yaml với các dependencies ban đầu
- Push source code lên GitHub lần đầu

---

*Format: `[version] — YYYY-MM-DD`*
*Loại thay đổi: `Added` | `Changed` | `Deprecated` | `Removed` | `Fixed` | `Security`*
