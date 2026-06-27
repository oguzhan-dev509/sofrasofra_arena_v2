import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavorilerimSayfasi extends StatefulWidget {
  const FavorilerimSayfasi({super.key});

  @override
  State<FavorilerimSayfasi> createState() => _FavorilerimSayfasiState();
}

class _FavorilerimSayfasiState extends State<FavorilerimSayfasi> {
  static const Color _background = Color(0xFF111111);
  static const Color _card = Color(0xFF1A1A1A);
  static const Color _gold = Color(0xFFFFB300);

  late Future<QuerySnapshot<Map<String, dynamic>>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _loadFavorites();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _loadFavorites() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Future<QuerySnapshot<Map<String, dynamic>>>.error(
        StateError('Kullanıcı oturumu bulunamadı.'),
      );
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
  }

  void _refreshFavorites() {
    setState(() {
      _favoritesFuture = _loadFavorites();
    });
  }

  Future<void> _removeFavorite({
    required String favoriteId,
    required String favoriteName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Kullanıcı oturumu bulunamadı.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(favoriteId)
          .delete();

      if (!mounted) {
        return;
      }

      _showMessage(
        '$favoriteName favorilerden çıkarıldı.',
      );

      _refreshFavorites();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Favori kaldırılamadı. Lütfen tekrar deneyin.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  String _safeText(dynamic value) {
    return (value ?? '').toString().trim();
  }

  String _favoriteTypeLabel(String sellerType) {
    switch (sellerType.trim().toLowerCase()) {
      case 'ev_lezzetleri_mutfak':
        return 'Mahalle Mutfağı';
      case 'ev_lezzetleri':
        return 'Ev Lezzeti';
      case 'restaurant':
        return 'Restoran';
      case 'usta_sef':
      case 'chef_signature':
        return 'Usta Şef';
      default:
        return 'Favori';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'FAVORİLERİM',
          style: TextStyle(
            color: _gold,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        backgroundColor: _background,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: _gold,
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _refreshFavorites,
            icon: const Icon(
              Icons.refresh_rounded,
              color: _gold,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _gold,
                ),
              );
            }

            if (snapshot.hasError) {
              return _FavoriteInfoState(
                icon: Icons.error_outline_rounded,
                title: 'Favoriler yüklenemedi',
                subtitle: 'Bağlantınızı kontrol edip yeniden deneyebilirsiniz.',
                buttonLabel: 'Yeniden Dene',
                onPressed: _refreshFavorites,
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const _FavoriteInfoState(
                icon: Icons.favorite_border_rounded,
                title: 'Henüz favoriniz yok',
                subtitle:
                    'Beğendiğiniz Mahalle Mutfağının kalbine dokunarak buraya kaydedebilirsiniz.',
              );
            }

            return RefreshIndicator(
              color: _gold,
              backgroundColor: _card,
              onRefresh: () async {
                _refreshFavorites();
                await _favoritesFuture;
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  final crossAxisCount = width >= 1100
                      ? 4
                      : width >= 760
                          ? 3
                          : width >= 520
                              ? 2
                              : 1;

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      16,
                      18,
                      80,
                    ),
                    itemCount: docs.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: crossAxisCount == 1 ? 1.55 : 0.86,
                    ),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();

                      return _FavoriteCard(
                        favoriteId: doc.id,
                        name: _safeText(
                          data['productName'] ??
                              data['sellerName'] ??
                              'Mahalle Mutfağı',
                        ),
                        sellerName: _safeText(
                          data['sellerName'],
                        ),
                        imageUrl: _safeText(
                          data['imageUrl'],
                        ),
                        category: _safeText(
                          data['category'],
                        ),
                        typeLabel: _favoriteTypeLabel(
                          _safeText(data['sellerType']),
                        ),
                        onRemove: () {
                          _removeFavorite(
                            favoriteId: doc.id,
                            favoriteName: _safeText(
                              data['productName'] ??
                                  data['sellerName'] ??
                                  'Favori',
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final String favoriteId;
  final String name;
  final String sellerName;
  final String imageUrl;
  final String category;
  final String typeLabel;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.favoriteId,
    required this.name,
    required this.sellerName,
    required this.imageUrl,
    required this.category,
    required this.typeLabel,
    required this.onRemove,
  });

  static const Color _card = Color(0xFF1A1A1A);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _favoriteRed = Color(0xFFFF3B5C);

  bool get _hasImage {
    final value = imageUrl.trim();

    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(favoriteId),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _gold.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_hasImage)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const _FavoriteImagePlaceholder();
                    },
                  )
                else
                  const _FavoriteImagePlaceholder(),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onRemove,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _favoriteRed.withValues(alpha: 0.22),
                          border: Border.all(
                            color: _favoriteRed.withValues(alpha: 0.95),
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: _favoriteRed,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Mahalle Mutfağı' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (sellerName.isNotEmpty && sellerName != name) ...[
                  const SizedBox(height: 5),
                  Text(
                    sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _FavoriteTag(
                        label: typeLabel,
                      ),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FavoriteTag(
                          label: category,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteTag extends StatelessWidget {
  final String label;

  const _FavoriteTag({
    required this.label,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _gold,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FavoriteImagePlaceholder extends StatelessWidget {
  const _FavoriteImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF202020),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          color: Colors.white38,
          size: 44,
        ),
      ),
    );
  }
}

class _FavoriteInfoState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  const _FavoriteInfoState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onPressed,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _gold,
              size: 54,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: Text(buttonLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
