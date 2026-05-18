import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/photo_upload_service.dart';
import '../services/sync_service.dart';

enum UploadStatus { idle, picking, uploading, success, error }

class PhotoUploadState {
  final List<XFile> selectedPhotos;
  final UploadStatus status;
  final String? error;

  const PhotoUploadState({
    this.selectedPhotos = const [],
    this.status = UploadStatus.idle,
    this.error,
  });

  PhotoUploadState copyWith({
    List<XFile>? selectedPhotos,
    UploadStatus? status,
    String? error,
  }) {
    return PhotoUploadState(
      selectedPhotos: selectedPhotos ?? this.selectedPhotos,
      status: status ?? this.status,
      error: error,
    );
  }
}

class PhotoUploadNotifier extends StateNotifier<PhotoUploadState> {
  final PhotoUploadService _photoService = PhotoUploadService();
  final SyncService _syncService = SyncService();
  final String? orderId;
  final String? equipmentId;
  final String? context;

  PhotoUploadNotifier({this.orderId, this.equipmentId, this.context})
      : super(const PhotoUploadState());

  Future<void> pickFromCamera() async {
    final photo = await _photoService.pickFromCamera();
    if (photo != null) {
      state = state.copyWith(selectedPhotos: [...state.selectedPhotos, photo]);
    }
  }

  Future<void> pickFromGallery() async {
    final photo = await _photoService.pickFromGallery();
    if (photo != null) {
      state = state.copyWith(selectedPhotos: [...state.selectedPhotos, photo]);
    }
  }

  void removePhoto(int index) {
    final newList = List<XFile>.from(state.selectedPhotos);
    newList.removeAt(index);
    state = state.copyWith(selectedPhotos: newList);
  }

  /// Este es el método clave: Encola las fotos para subida offline-first
  Future<void> saveAndQueueUploads() async {
    if (state.selectedPhotos.isEmpty) return;

    state = state.copyWith(status: UploadStatus.uploading);

    try {
      for (final photo in state.selectedPhotos) {
        // Encolamos la subida en el SyncService
        await _syncService.queueMediaUpload(
          filePath: photo.path,
          orderId: orderId,
          equipmentId: equipmentId,
          context: context,
        );
      }

      state = state.copyWith(
        selectedPhotos: [],
        status: UploadStatus.success,
      );

      // Intentamos sincronizar inmediatamente si hay red
      _syncService.syncAll();
      
    } catch (e) {
      state = state.copyWith(
        status: UploadStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const PhotoUploadState();
  }
}

// Provider dinámico para diferentes contextos (orden, equipo, etc)
final photoUploadProvider = StateNotifierProvider.family<PhotoUploadNotifier, PhotoUploadState, Map<String, String?>>((ref, params) {
  return PhotoUploadNotifier(
    orderId: params['orderId'],
    equipmentId: params['equipmentId'],
    context: params['context'],
  );
});
