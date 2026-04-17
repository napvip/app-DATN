# Changelog

Tất cả các thay đổi đáng chú ý của dự án **BeeGuard** sẽ được ghi nhận tại đây.

Định dạng theo [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), và phiên bản tuân thủ theo [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Tích hợp thông báo push notifications (Firebase Cloud Messaging).
- Hỗ trợ đa ngôn ngữ (Tiếng Anh / Tiếng Việt).
- Xuất báo cáo dữ liệu định dạng PDF.
- Offline mode với cơ chế local caching.

---

## [1.0.0] - 2026-04-15

### Added
- Khởi tạo dự án Flutter theo cấu trúc Clean Architecture.
- Xác thực người dùng qua Firebase Authentication (Email/Password).
- Màn hình Dashboard (`home_screen.dart`): Cung cấp tổng quan tình trạng tổ ong.
- Màn hình Insights (`insights_screen.dart`): Phân tích biểu đồ nhiệt độ và độ ẩm sử dụng fl_chart.
- Màn hình Alerts (`alerts_screen.dart`): Theo dõi danh sách cảnh báo bất thường trong thời gian thực.
- Màn hình Maintenance (`maintenance_screen.dart`): Quản lý lịch bảo trì.
- Màn hình Profile (`profile_screen.dart`): Quản lý thông tin người dùng và ảnh đại diện.
- Tích hợp điều hướng Navigation với GoRouter 14.x.
- Tích hợp quản lý trạng thái bằng Flutter Riverpod 2.x.
- Kết nối Firebase Firestore cho dữ liệu lớn của hệ thống tổ ong.
- Tích hợp tính năng tải ảnh qua Firebase Storage và thư viện image_picker.
- Xây dựng hệ thống UI widgets dùng chung (charts, cards, shimmer loading).
- Triển khai Data Layer hoàn chỉnh: Repositories, DataSources, Models.
- Phân tích mã nguồn qua flutter_lints phiên bản 5.x.
- Bổ sung `README.md` theo chuẩn, cung cấp hướng dẫn thiết lập dự án.
- Thiết lập `.gitignore`: Ngăn chặn đẩy `firebase.json`, `google-services.json` và `.free-claude/` lên mã nguồn.

### Changed
- Cập nhật `.gitignore` nhằm nâng cao mức độ bảo vệ các file cấu hình.

### Security
- Loại bỏ `firebase.json` khỏi tracking do chứa project ID và app ID.
- Không lưu version control với `google-services.json` và `GoogleService-Info.plist`.
- Sử dụng công cụ `flutterfire configure` sinh tệp cấu hình thay vì hardcode trực tiếp vào source.

---

## [0.1.0] - 2026-04-10

### Added
- Khởi chạy cấu trúc dự án cơ bản của Flutter.
- Nạp các packages từ Firebase (firebase_core, firebase_auth, cloud_firestore, firebase_storage).
- Quản lý dependencies trên tệp pubspec.yaml.
- Khởi tạo Git repository và push mã lên server.

---

*Format: `[version] - YYYY-MM-DD`*
*Loại thay đổi: `Added` | `Changed` | `Deprecated` | `Removed` | `Fixed` | `Security`*
