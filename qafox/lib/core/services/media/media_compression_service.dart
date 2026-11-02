import 'package:image_picker/image_picker.dart';

class MediaCompressionService {
  const MediaCompressionService();

  Future<XFile> compressImage(XFile file) async {
    // Return file as is (compressed by image_picker quality parameter)
    return file;
  }
}
