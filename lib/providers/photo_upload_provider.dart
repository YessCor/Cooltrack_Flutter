import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/photo_upload_service.dart';

enum UploadStatus { idle, picking, uploading, success, error }

class PhotoUploadState {
  final List<XFile> selectedPhotos;
  final List<UploadResult> uploadedPhotos;
  final UploadStatus status;
  final String? error;
  final double uploadProgress;

  const PhotoUploadState({
    this.selectedPhotos = const [],
    this.uploadedPhotos = const [],
    this.status = UploadStatus.idle,
    this.error,
    this.uploadProgress = 0,
  });

  PhotoUploadState copyWith({
    List<XFile>? selectedPhotos,
    List<UploadResult>? uploadedPhotos,
    UploadStatus? status,
    String? error,
    double? uploadProgress,
  }) {
    return PhotoUploadState(
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      uploadedPhotos: uploadedPhotos ?? this.uploadedPhotos,
      status: status ?? this.status,
      error: error,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

class PhotoUploadNotifier extends StateNotifier<PhotoUploadState> {
  final PhotoUploadService _photoService = PhotoUploadService();
  final String? _folder;

  PhotoUploadNotifier({String? folder})
      : _folder = folder,
        super(const PhotoUploadState());

  Future<void> pickFromCamera() async {
    state = state.copyWith(status: UploadStatus.picking);
    
    final photo = await _photoService.pickFromCamera();
    if (photo != null) {
      state = state.copyWith(
        selectedPhotos: [...state.selectedPhotos, photo],
        status: UploadStatus.idle,
      );
    } else {
      state = state.copyWith(status: UploadStatus.idle);
    }
  }

  Future<void> pickFromGallery() async {
    state = state.copyWith(status: UploadStatus.picking);
    
    final photos = await _photoService.pickFromGallery();
    if (photos != null) {
      state = state.copyWith(
        selectedPhotos: [...state.selectedPhotos, photos],
        status: UploadStatus.idle,
      );
    } else {
      state = state.copyWith(status: UploadStatus.idle);
    }
  }

  Future<void> pickMultiple() async {
    state = state.copyWith(status: UploadStatus.picking);
    
    final photos = await _photoService.pickMultipleFromGallery();
    if (photos.isNotEmpty) {
      state = state.copyWith(
        selectedPhotos: [...state.selectedPhotos, ...photos],
        status: UploadStatus.idle,
      );
    } else {
      state = state.copyWith(status: UploadStatus.idle);
    }
  }

  void removePhoto(int index) {
    if (index >= 0 && index < state.selectedPhotos.length) {
      final newList = List<XFile>.from(state.selectedPhotos);
      newList.removeAt(index);
      state = state.copyWith(selectedPhotos: newList);
    }
  }

  void clearSelection() {
    state = state.copyWith(selectedPhotos: []);
  }

  Future<void> uploadSelected() async {
    if (state.selectedPhotos.isEmpty) return;

    state = state.copyWith(
      status: UploadStatus.uploading,
      uploadProgress: 0,
    );

    final results = <UploadResult>[];
    final total = state.selectedPhotos.length;

    for (int i = 0; i < state.selectedPhotos.length; i++) {
      final photo = state.selectedPhotos[i];
      final result = await _photoService.uploadPhoto(
        photo.path,
        folder: _folder,
      );
      results.add(result);

      state = state.copyWith(
        uploadProgress: (i + 1) / total,
      );
    }

    final successfulUploads = results.where((r) => r.success).toList();
    
    state = state.copyWith(
      uploadedPhotos: [...state.uploadedPhotos, ...successfulUploads],
      selectedPhotos: [],
      status: results.any((r) => r.success) ? UploadStatus.success : UploadStatus.error,
      error: results.every((r) => !r.success) ? 'Failed to upload photos' : null,
    );
  }

  void clearUploads() {
    state = state.copyWith(
      uploadedPhotos: [],
      status: UploadStatus.idle,
      uploadProgress: 0,
    );
  }
}

final photoUploadProvider = StateNotifierProvider<PhotoUploadNotifier, PhotoUploadState>((ref) {
  return PhotoUploadNotifier();
});