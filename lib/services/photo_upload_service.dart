import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';

class PhotoUploadService {
  static final PhotoUploadService _instance = PhotoUploadService._internal();
  factory PhotoUploadService() => _instance;
  PhotoUploadService._internal();

  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();

  static const String _cloudinaryBaseUrl = 'https://api.cloudinary.com/v1_1';
  String? _cloudName;
  String? _uploadPreset;

  void configure({required String cloudName, required String uploadPreset}) {
    _cloudName = cloudName;
    _uploadPreset = uploadPreset;
  }

  Future<XFile?> pickFromCamera({int maxWidth = 1920, int maxHeight = 1080, int quality = 85}) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );
    } catch (e) {
      if (kDebugMode) print('Error picking image from camera: $e');
      return null;
    }
  }

  Future<XFile?> pickFromGallery({int maxWidth = 1920, int maxHeight = 1080, int quality = 85}) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );
    } catch (e) {
      if (kDebugMode) print('Error picking image from gallery: $e');
      return null;
    }
  }

  Future<List<XFile>> pickMultipleFromGallery({int maxImages = 10}) async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 85,
        limit: maxImages,
      );
      return images;
    } catch (e) {
      if (kDebugMode) print('Error picking multiple images: $e');
      return [];
    }
  }

  Future<UploadResult> uploadPhoto(String filePath, {String? folder}) async {
    if (_cloudName == null || _uploadPreset == null) {
      return UploadResult(
        success: false,
        error: 'Cloudinary not configured',
      );
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return UploadResult(success: false, error: 'File not found');
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'upload_preset': _uploadPreset,
        if (folder != null) 'folder': folder,
      });

      final response = await _dio.post(
        '$_cloudinaryBaseUrl/$_cloudName/image/upload',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return UploadResult(
          success: true,
          url: data['secure_url'],
          publicId: data['public_id'],
        );
      } else {
        return UploadResult(success: false, error: 'Upload failed');
      }
    } on DioException catch (e) {
      if (kDebugMode) print('Upload error: ${e.message}');
      return UploadResult(success: false, error: e.message ?? 'Upload failed');
    } catch (e) {
      if (kDebugMode) print('Error uploading photo: $e');
      return UploadResult(success: false, error: e.toString());
    }
  }

  Future<List<UploadResult>> uploadMultiplePhotos(List<String> filePaths, {String? folder}) async {
    final results = <UploadResult>[];
    
    for (final path in filePaths) {
      final result = await uploadPhoto(path, folder: folder);
      results.add(result);
      
      if (!result.success && kDebugMode) {
        print('Failed to upload: $path');
      }
    }
    
    return results;
  }

  Future<void> deletePhoto(String publicId) async {
    // Note: Deletion requires server-side API or admin panel
    // This is just a placeholder for the functionality
    if (kDebugMode) print('Delete photo not implemented - publicId: $publicId');
  }
}

class UploadResult {
  final bool success;
  final String? url;
  final String? publicId;
  final String? error;

  UploadResult({
    required this.success,
    this.url,
    this.publicId,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'url': url,
    'publicId': publicId,
    'error': error,
  };
}