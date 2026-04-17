# 🐝 BeeGuard — Ứng Dụng Hỗ Trợ Nuôi Ong Thông Minh

> **Đồ án tốt nghiệp** — Ứng dụng di động Flutter giúp người nuôi ong theo dõi tổ ong, nhận cảnh báo bất thường, quản lý lịch bảo trì và phân tích dữ liệu theo thời gian thực thông qua Firebase.

---

## 📋 Mục Lục

- [Giới thiệu](#-giới-thiệu)
- [Tính năng](#-tính-năng)
- [Kiến trúc hệ thống](#-kiến-trúc-hệ-thống)
- [Tech Stack](#-tech-stack)
- [Cài đặt & Chạy dự án](#-cài-đặt--chạy-dự-án)
- [Cấu hình Firebase](#-cấu-hình-firebase)
- [Cấu trúc thư mục](#-cấu-trúc-thư-mục)
- [Biến môi trường](#-biến-môi-trường)
- [Đóng góp](#-đóng-góp)

---

## 🎯 Giới Thiệu

**BeeGuard** là ứng dụng di động (Android & iOS) hỗ trợ người nuôi ong quản lý đàn ong một cách thông minh. Thông qua kết nối với cảm biến IoT gắn tại tổ ong và nền tảng Firebase, ứng dụng cung cấp:

- Giám sát nhiệt độ, độ ẩm, âm thanh tổ ong theo thời gian thực
- Cảnh báo tự động khi phát hiện dấu hiệu bất thường (bầy ong bỏ tổ, dịch bệnh...)
- Lịch sử và phân tích dữ liệu theo biểu đồ
- Quản lý lịch bảo trì tổ ong
- Hỗ trợ đa tổ ong, đa trang trại

---

## ✨ Tính Năng

| Tính năng | Mô tả |
|---|---|
| 🏠 Dashboard | Tổng quan tình trạng tất cả các tổ ong |
| 📊 Insights | Biểu đồ nhiệt độ, độ ẩm theo thời gian |
| 🔔 Alerts | Nhận cảnh báo bất thường theo thời gian thực |
| 🔧 Maintenance | Lên lịch và theo dõi lịch bảo trì tổ ong |
| 👤 Profile | Quản lý thông tin người dùng & trang trại |
| 🔐 Auth | Đăng nhập / Đăng ký qua Firebase Auth |

---

## 🏛️ Kiến Trúc Hệ Thống

```
┌─────────────────────────────────────────────────────────────┐
│                     BEEGUARD SYSTEM                         │
└─────────────────────────────────────────────────────────────┘

  📱 Mobile App (Flutter)
  ┌────────────────────────────────────┐
  │  Presentation Layer                │
  │  ┌──────────┐  ┌───────────────┐  │
  │  │  Screens │  │   Widgets     │  │
  │  │ - Home   │  │ - Charts      │  │
  │  │ - Alerts │  │ - Cards       │  │
  │  │ - Insight│  │ - Forms       │  │
  │  │ - Maint. │  └───────────────┘  │
  │  │ - Profile│                      │
  │  └──────────┘                      │
  │         │  (Riverpod Providers)    │
  │  Domain Layer                      │
  │  ┌─────────────────────────────┐  │
  │  │  Use Cases / Business Logic │  │
  │  └─────────────────────────────┘  │
  │         │                          │
  │  Data Layer                        │
  │  ┌──────────────┐ ┌────────────┐  │
  │  │ Repositories  │ │ DataSources│  │
  │  └──────────────┘ └────────────┘  │
  └────────────────────────────────────┘
          │                     │
          ▼                     ▼
  ┌──────────────┐     ┌──────────────────┐
  │  Firebase    │     │   IoT Sensors    │
  │ ┌──────────┐ │     │  (ESP32/Arduino) │
  │ │   Auth   │ │     │  - Nhiệt độ      │
  │ ├──────────┤ │     │  - Độ ẩm         │
  │ │Firestore │ │     │  - Âm thanh      │
  │ ├──────────┤ │◄────│  - Cân nặng      │
  │ │ Storage  │ │     └──────────────────┘
  │ └──────────┘ │
  └──────────────┘
```

### Luồng dữ liệu (Data Flow)

```
IoT Sensor ──► Firebase Realtime/Firestore ──► Flutter App ──► User
    │                                                │
    └──── Trigger Cloud Function ────► Alert ───────┘
```

### Kiến trúc Flutter (Clean Architecture)

```
lib/
├── presentation/     ← UI: Screens, Widgets
│       └── providers (Riverpod) ← State
├── domain/           ← Business logic: Use Cases, Entities
├── data/             ← Data: Repositories, DataSources, Models
├── config/           ← App config, themes, constants
├── routes/           ← GoRouter navigation
└── services/         ← Firebase, notification services
```

---

## 🛠️ Tech Stack

| Thành phần | Công nghệ |
|---|---|
| **Framework** | Flutter 3.x (Dart 3.7+) |
| **State Management** | Riverpod 2.x |
| **Navigation** | GoRouter 14.x |
| **Backend** | Firebase (Auth, Firestore, Storage) |
| **Charts** | fl_chart |
| **Image** | cached_network_image, image_picker |
| **Icons** | lucide_icons |
| **I18n** | intl |

---

## 🚀 Cài Đặt & Chạy Dự Án

### Yêu cầu hệ thống

- Flutter SDK `>=3.7.0`
- Dart SDK `>=3.7.0`
- Android Studio / VS Code
- Firebase CLI (`npm install -g firebase-tools`)
- Tài khoản Firebase

### 1. Clone dự án

```bash
git clone https://github.com/<your-username>/do_an_tot_nghiep_ho_tro_nuoi_ong.git
cd do_an_tot_nghiep_ho_tro_nuoi_ong
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Cấu hình Firebase (xem phần dưới)

### 4. Chạy ứng dụng

```bash
# Chạy trên thiết bị/emulator (debug mode)
flutter run

# Chạy trên Android cụ thể
flutter run -d <device-id>

# Xem danh sách thiết bị đang kết nối
flutter devices
```

### 5. Build release

```bash
# Build APK Android
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release

# Build iOS (macOS bắt buộc)
flutter build ios --release
```

---

## 🔥 Cấu Hình Firebase

> ⚠️ **QUAN TRỌNG:** File `firebase.json` và `google-services.json` chứa thông tin nhạy cảm và **KHÔNG được commit lên Git**. Xem `.gitignore`.

### Bước 1: Tạo Firebase Project

1. Truy cập [Firebase Console](https://console.firebase.google.com)
2. Tạo project mới hoặc dùng project có sẵn
3. Bật **Authentication** (Email/Password)
4. Tạo **Firestore Database**
5. Bật **Firebase Storage**

### Bước 2: Thêm ứng dụng vào Firebase

```bash
# Cài FlutterFire CLI
dart pub global activate flutterfire_cli

# Đăng nhập Firebase
firebase login

# Cấu hình tự động (tạo lib/firebase_options.dart)
flutterfire configure --project=<your-firebase-project-id>
```

Lệnh trên sẽ tự tạo file `lib/firebase_options.dart` với các thông tin cấu hình.

### Bước 3: Tải google-services.json

- **Android:** Tải `google-services.json` từ Firebase Console → đặt vào `android/app/`
- **iOS:** Tải `GoogleService-Info.plist` → đặt vào `ios/Runner/`

> 💡 Hai file này đã được thêm vào `.gitignore`. Mỗi developer cần tải về và đặt thủ công.

---

## 📁 Cấu Trúc Thư Mục

```
do_an_tot_nghiep_ho_tro_nuoi_ong/
├── android/                    # Android native project
├── ios/                        # iOS native project
├── assets/
│   └── images/                 # Hình ảnh tĩnh
├── lib/
│   ├── config/                 # Cấu hình app (theme, constants)
│   ├── core/                   # Core utilities, extensions
│   ├── data/
│   │   ├── datasources/        # Firebase datasources
│   │   ├── models/             # Data models (JSON serialization)
│   │   └── repositories/       # Repository implementations
│   ├── domain/                 # Business logic, entities
│   ├── models/                 # Shared models
│   ├── presentation/           # Riverpod providers
│   ├── routes/                 # GoRouter config
│   ├── screens/
│   │   ├── auth/               # Màn hình đăng nhập, đăng ký
│   │   ├── hive/               # Quản lý tổ ong
│   │   └── main/               # Màn hình chính
│   │       ├── home_screen.dart
│   │       ├── alerts_screen.dart
│   │       ├── insights_screen.dart
│   │       ├── maintenance_screen.dart
│   │       └── profile_screen.dart
│   ├── services/               # Firebase services, notifications
│   ├── widgets/                # Reusable widgets
│   ├── firebase_options.dart   # Auto-generated by FlutterFire CLI
│   └── main.dart               # Entry point
├── test/                       # Unit & Widget tests
├── pubspec.yaml                # Dependencies
├── CHANGELOG.md                # Lịch sử thay đổi
└── README.md                   # File này
```

---

## 🔐 Biến Môi Trường

Dự án sử dụng `lib/firebase_options.dart` (auto-generated bởi FlutterFire CLI) thay vì lưu trực tiếp credentials vào code.

| Config | Nơi lưu | Cách lấy |
|---|---|---|
| Firebase Project ID | `firebase_options.dart` | `flutterfire configure` |
| Android App ID | `google-services.json` | Firebase Console → Android App |
| iOS App ID | `GoogleService-Info.plist` | Firebase Console → iOS App |
| Web App ID | `firebase_options.dart` | Firebase Console → Web App |

> **Không bao giờ hardcode API keys hay credentials trực tiếp vào source code.**

---

## 🤝 Đóng Góp

1. Fork repository này
2. Tạo branch mới: `git checkout -b feature/ten-tinh-nang`
3. Commit thay đổi: `git commit -m "feat: thêm tính năng X"`
4. Push branch: `git push origin feature/ten-tinh-nang`
5. Tạo Pull Request

### Commit Convention

```
feat:     Thêm tính năng mới
fix:      Sửa lỗi
docs:     Cập nhật tài liệu
style:    Thay đổi format, không ảnh hưởng logic
refactor: Tái cấu trúc code
test:     Thêm/cập nhật test
chore:    Cập nhật build, dependencies
```

---

## 📄 License

Đồ án tốt nghiệp — Không sử dụng cho mục đích thương mại.

---

*Được xây dựng với ❤️ bằng Flutter & Firebase*


hello