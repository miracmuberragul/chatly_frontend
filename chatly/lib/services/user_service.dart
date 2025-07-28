import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatly/models/user_model.dart';

class UserService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  //create a new user
  Future<void> createUser(UserModel user) async {
    try {
      final docRef = firestore.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        //cheks if there is a user with this uid
        await docRef.set(user.toJson());
      } else {
        print("User already exists in Firestore.");
      }
    } catch (e) {
      print("Error checking/creating user: $e");
    }
  }
}
