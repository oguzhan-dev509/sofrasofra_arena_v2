import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  FavoriteService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  static bool get hasSignedInUser => currentUserId != null;

  static CollectionReference<Map<String, dynamic>> _favoritesCollection(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  static String favoriteDocumentId({
    required String sellerType,
    required String productId,
  }) {
    final safeSellerType =
        sellerType.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');

    final safeProductId =
        productId.trim().replaceAll('/', '_').replaceAll('\\', '_');

    return '${safeSellerType}_$safeProductId';
  }

  /// Kullanıcının tüm favori doküman kimliklerini tek okumada getirir.
  ///
  /// Ürün kartı başına ayrı Firestore dinleyicisi açmadığı için
  /// okuma maliyetini düşük tutar.
  static Future<Set<String>> loadFavoriteIds() async {
    final uid = currentUserId;

    if (uid == null) {
      return <String>{};
    }

    final snapshot = await _favoritesCollection(uid).get();

    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  /// Favoriyi ekler veya kaldırır.
  ///
  /// [shouldBeFavorite] true ise kayıt oluşturulur,
  /// false ise ilgili kayıt silinir.
  static Future<void> setFavorite({
    required bool shouldBeFavorite,
    required String productId,
    required String sellerId,
    required String sellerType,
    required String productName,
    required String imageUrl,
    required double price,
    required String category,
    String sellerName = '',
  }) async {
    final uid = currentUserId;

    if (uid == null) {
      throw StateError(
        'Favori işlemi için kullanıcı oturumu bulunamadı.',
      );
    }

    final trimmedProductId = productId.trim();
    final trimmedSellerType = sellerType.trim();

    if (trimmedProductId.isEmpty) {
      throw ArgumentError('productId boş olamaz.');
    }

    if (trimmedSellerType.isEmpty) {
      throw ArgumentError('sellerType boş olamaz.');
    }

    final favoriteId = favoriteDocumentId(
      sellerType: trimmedSellerType,
      productId: trimmedProductId,
    );

    final favoriteRef = _favoritesCollection(uid).doc(favoriteId);

    if (!shouldBeFavorite) {
      await favoriteRef.delete();
      return;
    }

    await favoriteRef.set(
      {
        'favoriteId': favoriteId,
        'userId': uid,
        'productId': trimmedProductId,
        'sellerId': sellerId.trim(),
        'sellerType': trimmedSellerType,
        'productName': productName.trim(),
        'sellerName': sellerName.trim(),
        'imageUrl': imageUrl.trim(),
        'price': price,
        'category': category.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Belirli bir ürünün favori olup olmadığını kontrollü tek okumayla denetler.
  static Future<bool> isFavorite({
    required String sellerType,
    required String productId,
  }) async {
    final uid = currentUserId;

    if (uid == null) {
      return false;
    }

    final favoriteId = favoriteDocumentId(
      sellerType: sellerType,
      productId: productId,
    );

    final snapshot = await _favoritesCollection(uid).doc(favoriteId).get();

    return snapshot.exists;
  }
}
