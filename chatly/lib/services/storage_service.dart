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
      // Ensure path is safe: remove slashes from chatId
      final safeChatId = chatId.replaceAll('/', '_');
      // Preserve file extension if any so that Android/iOS know type
      final ext = imageFile.name.contains('.') ? imageFile.name.split('.').last : 'jpg';
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}.$ext";
      final Reference storageRef = _storage.ref().child('chats/$safeChatId/$fileName');

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
