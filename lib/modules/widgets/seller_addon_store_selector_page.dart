import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/seller_addon_management_page.dart';

class SellerAddonStoreSelectorPage extends StatelessWidget {
  const SellerAddonStoreSelectorPage({
    super.key,
  });

  static const Color _background = Color(0xFF090909);
  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  Query<Map<String, dynamic>> get _sellerQuery {
    return FirebaseFirestore.instance.collection('sellers');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ev Lezzetleri Dükkânı Seç'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _sellerQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageBox(
              icon: Icons.error_outline_rounded,
              title: 'Dükkânlar yüklenemedi',
              message: snapshot.error.toString(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: _gold,
              ),
            );
          }

          final sellers = snapshot.data!.docs.where((doc) {
            final data = doc.data();

            final type = [
              data['type'],
              data['sellerType'],
              data['category'],
              data['kategori'],
              data['isletmeTipi'],
            ].map((value) => (value ?? '').toString().trim().toLowerCase());

            return type.any(
              (value) =>
                  value == 'ev_lezzetleri' ||
                  value == 'ev lezzetleri' ||
                  value == 'ev_lezzeti' ||
                  value.contains('ev lezzet'),
            );
          }).toList();

          sellers.sort((a, b) {
            final aName = _sellerName(a).toLowerCase();
            final bName = _sellerName(b).toLowerCase();
            return aName.compareTo(bName);
          });

          if (sellers.isEmpty) {
            return const _MessageBox(
              icon: Icons.storefront_outlined,
              title: 'Ev Lezzetleri dükkânı bulunamadı',
              message:
                  'Sellers koleksiyonunda Ev Lezzetleri türünde kayıt bulunmuyor.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yan ürünlerini yöneteceğiniz dükkânı seçin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Her dükkânın içecek, tatlı ve ekstra ürünleri birbirinden bağımsız tutulur.',
                      style: TextStyle(
                        color: Colors.white60,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...sellers.map(
                (doc) => _SellerCard(
                  sellerId: doc.id,
                  sellerName: _sellerName(doc),
                  subtitle: _sellerSubtitle(doc),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerAddonManagementPage(
                          sellerId: doc.id,
                          title: '${_sellerName(doc)} Yan Ürünleri',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _sellerName(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    for (final key in [
      'shopName',
      'storeName',
      'businessName',
      'sellerName',
      'name',
      'title',
      'dukkanAdi',
      'isletmeAdi',
    ]) {
      final value = (data[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }

    return doc.id;
  }

  static String _sellerSubtitle(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final city = (data['city'] ?? data['il'] ?? '').toString().trim();
    final district = (data['district'] ?? data['ilce'] ?? '').toString().trim();

    final location = [
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
    ].join(' / ');

    if (location.isNotEmpty) {
      return '${doc.id} • $location';
    }

    return doc.id;
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({
    required this.sellerId,
    required this.sellerName,
    required this.subtitle,
    required this.onTap,
  });

  final String sellerId;
  final String sellerName;
  final String subtitle;
  final VoidCallback onTap;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: _gold,
          ),
        ),
        title: Text(
          sellerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.white54,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: 560,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: const Color(0xFFFFB300),
                size: 42,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
