# BeeGuard - Ứng Dụng Hỗ Trợ Nuôi Ong

**Đồ án tốt nghiệp** - Ứng dụng di động xây dựng bằng Flutter giúp người nuôi ong theo dõi thông số, quản lý tình trạng tổ ong, nhận cảnh báo bất thường và bảo trì thông qua dữ liệu thu thập theo thời gian thực phân tích trên Firebase.

## Mục lục

- [Giới thiệu](#giới-thiệu)
- [Tính năng](#tính-năng)
- [Kiến trúc hệ thống](#kiến-trúc-hệ-thống)
- [Tech Stack](#tech-stack)
- [Hướng dẫn cài đặt](#hướng-dẫn-cài-đặt)
- [Cấu hình Firebase](#cấu-hình-firebase)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Biến môi trường](#biến-môi-trường)
- [Tham gia đóng góp](#tham-gia-đóng-góp)

## Giới thiệu

**BeeGuard** là một hệ thống trên nền tảng di động (Android & iOS) được thiết kế cho người nuôi ong. Hệ thống kết nối với các cảm biến IoT và phân tích dữ liệu qua nền tảng Firebase, cung cấp các giải pháp:

- Giám sát thông số môi trường (nhiệt độ, độ ẩm, âm thanh) của tổ ong theo thời gian thực.
- Cảnh báo tự động về trường hợp môi trường tại tổ ong vượt ranh giới an toàn.
- Lưu trữ và trực quan hóa dữ liệu theo đồ thị nhằm hỗ trợ đánh giá tình trạng tự nhiên.
- Theo dõi quá trình bảo trì và lên lịch trình cho từng tổ ong.
- Hỗ trợ xây dựng mô hình mở rộng, gồm nhiều tổ ong thuộc nhiều trang trại khác nhau.

## Tính năng

| Khối chức năng | Mô tả |
|---|---|
| Dashboard | Quản lý tổng quan tình trạng của toàn hệ thống tổ ong đang được giám sát. |
| Insights | Phân tích các thông số về nhiệt độ và độ ẩm qua biểu đồ thống kê. |
| Alerts | Cung cấp thông báo khi có các biểu hiện chỉ số dao động bất thường. |
| Maintenance | Quản lý và theo dõi lịch bảo trì cho từng tổ ong cụ thể. |
| Profile | Quản lý thông tin tài khoản người dùng và thông tin trang trại. |
| Authentication | Quản lý truy cập và tài khoản bằng Firebase Auth. |

## Kiến trúc hệ thống

```text
┌─────────────────────────────────────────────────────────────┐
│                     BEEGUARD SYSTEM                         │
└─────────────────────────────────────────────────────────────┘

  Mobile App (Flutter)
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
  │  │ Repositories │ │ DataSources│  │
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

### Luồng xử lý dữ liệu

```text
IoT Sensor ──► Firebase Realtime/Firestore ──► Flutter App ──► User
    │                                                │
    └──── Trigger Cloud Function ────► Alert ───────┘
```

### Kiến trúc dự án (Clean Architecture)

```text
lib/
├── presentation/     ← Giao diện (Screens, Widgets, Providers)
├── domain/           ← Business logic (Use Cases, Entities)
├── data/             ← Xử lý dữ liệu (Repositories, DataSources, Models)
├── config/           ← Cấu hình hệ thống, theme, hằng số
├── routes/           ← Điều hướng GoRouter
└── services/         ← Dịch vụ kết nối ngoài (Firebase, Notifications)
```

## Tech Stack

| Công nghệ/Thư viện | Vai trò |
|---|---|
| Flutter 3.x | Framework xây dựng giao diện người dùng đa nền tảng |
| Riverpod 2.x | Quản lý trạng thái (State Management) |
| GoRouter 14.x | Quản lý điều hướng trong luồng ứng dụng |
| Firebase | Nền tảng Backend (Auth, Firestore, Storage) |
| fl_chart | Thư viện biểu diễn đồ thị/biểu đồ dữ liệu |
| cached_network_image | Quản lý cache ảnh nền mạng |
| image_picker | Truy cập thư viện file và trình camera thiết bị |
| lucide_icons | Bộ biểu tượng giao diện hệ thống |
| intl | Hỗ trợ đa ngôn ngữ và định dạng DateTime |

## Hướng dẫn cài đặt

### Yêu cầu môi trường

- Flutter SDK (>= 3.7.0)
- Dart SDK (>= 3.7.0)
- Android Studio / VS Code
- Firebase CLI (Yêu cầu Node.js npm: `npm install -g firebase-tools`)
- Thuộc quyền sở hữu dự án trên Firebase

### 1. Phục hồi mã nguồn

```bash
git clone https://github.com/<your-username>/do_an_tot_nghiep_ho_tro_nuoi_ong.git
cd do_an_tot_nghiep_ho_tro_nuoi_ong
```

### 2. Tải dependencies

```bash
flutter pub get
```

### 3. Cấu hình Firebase
[Chi tiết tại phần Cấu hình Firebase bên dưới]

### 4. Chạy ứng dụng

```bash
# Debug trên emulator hay thiết bị USB
flutter run

# Chỉ định device cụ thể (danh sách có thể xem qua lệnh: flutter devices)
flutter run -d <device-id>
```

### 5. Triển khai phiên bản phát hành

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

## Cấu hình Firebase

**Lưu ý:** Các file cấu hình `firebase.json` và `google-services.json` cần thiết lập bảo mật và không đưa lên hệ thống quản lý git mở.

### Bước 1: Khởi tạo project
1. Khởi tạo dự án thông qua nền tảng [Firebase Console](https://console.firebase.google.com).
2. Kích hoạt dịch vụ Authentication qua Email/Password.
3. Thiết lập kết nối cơ sở dữ liệu trên Firestore Database.
4. Kích hoạt Firebase Storage cho việc sao lưu tập tin của người dùng.

### Bước 2: Đồng bộ Firebase resources

```bash
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=<your-firebase-project-id>
```
Quy trình này sẽ tự động sinh module lưu cấu hình tại tệp mã nguồn `lib/firebase_options.dart`.

### Bước 3: Cấu hình trên Client
- **Android:** Tải file `google-services.json` từ console xuống, sau đó chép vào `android/app/`.
- **iOS:** Tải file `GoogleService-Info.plist` từ console xuống, sau đó chép vào `ios/Runner/`.

## Cấu trúc thư mục chi tiết

```text
do_an_tot_nghiep_ho_tro_nuoi_ong/
├── android/                    
├── ios/                        
├── assets/
│   └── images/                 
├── lib/
│   ├── config/                 
│   ├── core/                   
│   ├── data/
│   │   ├── datasources/        
│   │   ├── models/             
│   │   └── repositories/       
│   ├── domain/                 
│   ├── models/                 
│   ├── presentation/           
│   ├── routes/                 
│   ├── screens/
│   │   ├── auth/               
│   │   ├── hive/               
│   │   └── main/               
│   ├── services/               
│   ├── widgets/                
│   ├── firebase_options.dart   
│   └── main.dart               
├── test/                       
├── pubspec.yaml                
├── CHANGELOG.md                
└── README.md                   
```

## Biến môi trường

Hệ thống kết nối với máy chủ qua cấu hình tĩnh `firebase_options.dart` tạo ra nhờ công cụ CLI. Việc lưu chuỗi API key bằng văn bản thuần túy trong mã nguồn (hardcode) là hành vi bỏ qua nguyên tắc bảo mật.

| Trường cấu hình | Vị trí lưu | Ghi chú cập nhật |
|---|---|---|
| Firebase Project ID | `firebase_options.dart` | Cập nhật với lệnh `flutterfire configure` |
| Android App ID | `google-services.json` | Cấu hình qua Firebase Console cho app Android |
| iOS App ID | `GoogleService-Info.plist` | Cấu hình qua Firebase Console cho app iOS |
| Web App ID | `firebase_options.dart` | Cấu hình qua Firebase Console cho app Web |

## Tham gia đóng góp

Toàn bộ quy trình tham gia thay đổi mã nguồn được mô tả như sau:

1. Fork repository tại nhánh chính.
2. Tạo mới một nhánh độc lập (`git checkout -b feature/tinh-nang-moi`).
3. Đóng gói các thay đổi (`git commit -m "feat: mo ta tinh nang dang trien khai"`).
4. Đẩy nhánh vừa tạo lên remote (`git push origin feature/tinh-nang-moi`).
5. Gửi yêu cầu gộp mã (Pull Request).

### Quy ước Commit

```text
feat:     Bổ sung hoặc triển khai tính năng
fix:      Khắc phục lỗi phần mềm
docs:     Bổ sung tài liệu hoặc văn bản cấu trúc
style:    Chỉnh sửa định dạng hiển thị file, không làm thay đổi logic source code
refactor: Cấu trúc hóa lại đoạn hoặc khối source code
test:     Khởi tạo hoặc tinh chỉnh cấu trúc cho các module test
chore:    Tùy biến cho hạ tầng hệ thống và tool quản trị
```


