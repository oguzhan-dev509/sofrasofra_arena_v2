import 'package:cloud_firestore/cloud_firestore.dart';

import '../modules/restoranlar/models/restoran_menu_item_model.dart';
import '../modules/restoranlar/models/restoran_model.dart';

class RestoranService {
  RestoranService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<List<RestoranModel>> streamRestaurantsForShowcase() {
    return _db.collection('restaurants').snapshots().map((snapshot) {
      final restaurants = snapshot.docs
          .map((doc) => RestoranModel.fromMap(doc.id, doc.data()))
          .where((restaurant) {
        final name = restaurant.name.trim();

        return name.isNotEmpty &&
            name != 'Mahallenin Pidecisi' &&
            name != 'Mahalle Kebapçısı' &&
            name != 'Mahallenin Kebapçısı';
      }).toList();

      restaurants.sort((a, b) {
        if (a.isFounder != b.isFounder) {
          return a.isFounder ? -1 : 1;
        }

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return restaurants;
    });
  }

  static Stream<List<RestoranMenuItemModel>> streamMenuItems({
    required String restaurantId,
  }) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu_items')
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) {
            final data = doc.data();

            return RestoranMenuItemModel.fromMap(
              doc.id,
              {
                ...data,
                'restaurantId': data['restaurantId'] ?? restaurantId,
              },
            );
          })
          .where((item) => item.name.trim().isNotEmpty)
          .toList();

      items.sort((a, b) {
        if (a.isFeatured != b.isFeatured) {
          return a.isFeatured ? -1 : 1;
        }

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return items;
    });
  }

  static Future<RestoranModel?> getRestaurantById(String restaurantId) async {
    final id = restaurantId.trim();

    if (id.isEmpty) {
      return null;
    }

    final doc = await _db.collection('restaurants').doc(id).get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();

    if (data == null) {
      return null;
    }

    return RestoranModel.fromMap(doc.id, data);
  }
}
