import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service upload ảnh lên Cloudinary (hoạt động trên cả Web & Mobile).
/// Dùng unsigned upload để tránh vấn đề CORS.
class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _apiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get _apiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  /// Upload ảnh lên Cloudinary, trả về URL của ảnh.
  /// [folder] (tùy chọn) – thư mục lưu trữ trên Cloudinary.
  static Future<String> uploadImage(
    Uint8List imageBytes, {
    String folder = 'service_bookings',
  }) async {
    if (_cloudName.isEmpty) {
      throw Exception('CLOUDINARY_CLOUD_NAME chưa được cấu hình trong .env');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    // Tạo timestamp và signature cho signed upload
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final paramsToSign = 'folder=$folder&timestamp=$timestamp$_apiSecret';
    final signature = _generateSha1(paramsToSign);

    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = _apiKey
      ..fields['timestamp'] = timestamp.toString()
      ..fields['signature'] = signature
      ..fields['folder'] = folder
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      debugPrint('Cloudinary error: ${response.body}');
      throw Exception('Upload thất bại (${response.statusCode})');
    }

    final data = json.decode(response.body);
    return data['secure_url'] as String;
  }

  /// Tạo SHA1 hash đơn giản bằng Dart thuần (không cần package crypto).
  static String _generateSha1(String input) {
    // Sử dụng dart:convert SHA1
    final bytes = utf8.encode(input);
    // Dùng thuật toán SHA-1
    int h0 = 0x67452301;
    int h1 = 0xEFCDAB89;
    int h2 = 0x98BADCFE;
    int h3 = 0x10325476;
    int h4 = 0xC3D2E1F0;

    final msgLen = bytes.length;
    final bitLen = msgLen * 8;

    // Pre-processing: adding padding bits
    final padded = <int>[...bytes, 0x80];
    while ((padded.length % 64) != 56) {
      padded.add(0);
    }
    // Append original length in bits as 64-bit big-endian
    for (int i = 56; i >= 0; i -= 8) {
      padded.add((bitLen >> i) & 0xFF);
    }

    // Process each 512-bit chunk
    for (int i = 0; i < padded.length; i += 64) {
      final w = List<int>.filled(80, 0);
      for (int j = 0; j < 16; j++) {
        w[j] = (padded[i + j * 4] << 24) |
            (padded[i + j * 4 + 1] << 16) |
            (padded[i + j * 4 + 2] << 8) |
            padded[i + j * 4 + 3];
      }
      for (int j = 16; j < 80; j++) {
        w[j] = _rotateLeft32(w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16], 1);
      }

      int a = h0, b = h1, c = h2, d = h3, e = h4;

      for (int j = 0; j < 80; j++) {
        int f, k;
        if (j < 20) {
          f = (b & c) | ((~b) & d);
          k = 0x5A827999;
        } else if (j < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (j < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        final temp = (_rotateLeft32(a, 5) + f + e + k + w[j]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = _rotateLeft32(b, 30);
        b = a;
        a = temp;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }

    return _toHex(h0) + _toHex(h1) + _toHex(h2) + _toHex(h3) + _toHex(h4);
  }

  static int _rotateLeft32(int n, int count) {
    return ((n << count) | ((n & 0xFFFFFFFF) >> (32 - count))) & 0xFFFFFFFF;
  }

  static String _toHex(int value) {
    return (value & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
  }
}
