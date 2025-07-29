import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friendship_model.dart'; // FriendshipModel dosyanızın yolu
import '../models/user_model.dart'; // UserModel dosyanızın yolu (arkadaşları getirirken gerekebilir)

class FriendshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _friendshipCollection =
      'friendships'; // Arkadaşlık koleksiyonu adı
  final String _userCollection =
      'users'; // Kullanıcı koleksiyonu adı (arkadaş bilgisi için)

  // Arkadaşlık isteği gönder
  Future<void> sendFriendRequest(String requesterId, String receiverId) async {
    try {
      // Kendine istek göndermeyi engelle
      if (requesterId == receiverId) {
        throw Exception('Cannot send friend request to yourself.');
      }

      // Zaten bir istek var mı kontrol et (iki yönde de)
      final existingRequest = await _firestore
          .collection(_friendshipCollection)
          .where('requesterId', isEqualTo: requesterId)
          .where('receiverId', isEqualTo: receiverId)
          .limit(1)
          .get();

      final existingRequestReverse = await _firestore
          .collection(_friendshipCollection)
          .where('requesterId', isEqualTo: receiverId)
          .where('receiverId', isEqualTo: requesterId)
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty ||
          existingRequestReverse.docs.isNotEmpty) {
        throw Exception(
          'Friend request already exists or you are already friends.',
        );
      }

      // Yeni istek oluştur
      final docRef = _firestore.collection(_friendshipCollection).doc();
      final friendship = FriendshipModel(
        id: docRef.id,
        requesterId: requesterId,
        receiverId: receiverId,
        status: 'pending',
        createdAt: Timestamp.now(),
      );
      await docRef.set(friendship.toJson());
    } catch (e) {
      print('Error sending friend request: $e');
      rethrow;
    }
  }

  // Arkadaşlık isteğini kabul et
  Future<void> acceptFriendRequest(String friendshipId) async {
    try {
      await _firestore
          .collection(_friendshipCollection)
          .doc(friendshipId)
          .update({'status': 'accepted', 'updatedAt': Timestamp.now()});
      // Not: Bu noktada her iki kullanıcının da UserModel'lerindeki `friends`
      // listesini güncellemeniz gerekebilir, eğer Firestore'da iki farklı belgeyi
      // bağlamak istiyorsanız. Veya sadece FriendshipModel'e güvenebilirsiniz.
      // Basitlik için sadece FriendshipModel'i güncelliyorum.
    } catch (e) {
      print('Error accepting friend request: $e');
      rethrow;
    }
  }

  // Arkadaşlık isteğini reddet
  Future<void> rejectFriendRequest(String friendshipId) async {
    try {
      await _firestore
          .collection(_friendshipCollection)
          .doc(friendshipId)
          .update({'status': 'rejected', 'updatedAt': Timestamp.now()});
    } catch (e) {
      print('Error rejecting friend request: $e');
      rethrow;
    }
  }

  // Arkadaşlığı sil/iptal et
  Future<void> deleteFriendship(String friendshipId) async {
    try {
      await _firestore
          .collection(_friendshipCollection)
          .doc(friendshipId)
          .delete();
    } catch (e) {
      print('Error deleting friendship: $e');
      rethrow;
    }
  }

  // Bir kullanıcının bekleyen arkadaşlık isteklerini alıcı olarak getir
  Stream<List<FriendshipModel>> getPendingRequestsForUser(String userId) {
    return _firestore
        .collection(_friendshipCollection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendshipModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // Bir kullanıcının gönderdiği bekleyen arkadaşlık isteklerini getir
  Stream<List<FriendshipModel>> getSentPendingRequestsByUser(String userId) {
    return _firestore
        .collection(_friendshipCollection)
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendshipModel.fromJson(doc.data()))
              .toList(),
        );
  }

  // Bir kullanıcının kabul edilmiş arkadaşlarını getir
  Stream<List<UserModel>> getAcceptedFriendsOfUser(String userId) {
    return _firestore
        .collection(_friendshipCollection)
        .where('status', isEqualTo: 'accepted')
        .where(
          Filter.or(
            Filter('requesterId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: userId),
          ),
        )
        .snapshots()
        .asyncMap((snapshot) async {
          final friendUids =
              <String>{}; // Tekrar eden UID'leri önlemek için Set
          for (var doc in snapshot.docs) {
            final friendship = FriendshipModel.fromJson(doc.data());
            if (friendship.requesterId == userId) {
              friendUids.add(friendship.receiverId);
            } else {
              friendUids.add(friendship.requesterId);
            }
          }

          if (friendUids.isEmpty) {
            return [];
          }

          // Arkadaş UID'lerine göre kullanıcıları getir
          final friendsQuerySnapshot = await _firestore
              .collection(_userCollection)
              .where(FieldPath.documentId, whereIn: friendUids.toList())
              .get();

          return friendsQuerySnapshot.docs
              .map((doc) => UserModel.fromJson(doc.data()!))
              .toList();
        });
  }

  // Tüm arkadaşlıkları listele (filtre yok)
  Stream<List<FriendshipModel>> getAllFriendships() {
    return _firestore
        .collection(_friendshipCollection)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendshipModel.fromJson(doc.data()))
              .toList(),
        );
  }
}
