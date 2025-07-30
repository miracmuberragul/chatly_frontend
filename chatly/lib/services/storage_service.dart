import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Pick an image from the gallery
  Future<XFile?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image;
  }

  // Upload image to Firebase Storage and get the download URL
  Future<String?> uploadImage(String chatId, XFile imageFile) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef = _storage.ref().child('chats/$chatId/$fileName');

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(File(imageFile.path));

      // Wait for the upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
