import 'package:image_picker/image_picker.dart';

class VideoPickerService {
  final ImagePicker _picker;

  VideoPickerService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  Future<XFile?> pickVideoFromGallery({Duration? maxDuration}) async {
    return await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxDuration ?? const Duration(minutes: 5),
    );
  }

  Future<XFile?> recordVideo({Duration? maxDuration}) async {
    return await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maxDuration ?? const Duration(minutes: 2),
    );
  }
}
