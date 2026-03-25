import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/admin/usta_sef_gorsel_yonetimi.dart';

class UstaSefProfilSayfasi extends StatelessWidget {
  final String chefId;
  final bool isAdmin;

  const UstaSefProfilSayfasi({
    super.key,
    required this.chefId,
    this.isAdmin = false,
  });

  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Colors.black;
  static const Color card = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('USTA ŞEF PROFİLİ',
            style: TextStyle(
                color: gold, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: gold),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chefs')
            .doc(chefId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
                child:
                    Text('Hata oluştu', style: TextStyle(color: Colors.white)));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator(color: gold));

          final data = snapshot.data?.data();
          if (data == null)
            return const Center(
                child: Text('Veri bulunamadı',
                    style: TextStyle(color: Colors.white)));

          final media = Map<String, dynamic>.from(data['media'] ?? {});
          final String profileImage = (media['profileImage'] ?? '').toString();
          final List<String> gallery =
              List<String>.from(media['gallery'] ?? []);

          final String name =
              (data['name'] ?? data['ad'] ?? 'Usta Şef').toString();
          final String title =
              (data['title'] ?? data['unvan'] ?? 'Özel Lezzetler').toString();
          final String city = (data['city'] ?? data['sehir'] ?? '').toString();
          final String district =
              (data['district'] ?? data['ilce'] ?? '').toString();
          final String about =
              (data['about'] ?? data['bio'] ?? data['aciklama'] ?? '')
                  .toString();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(
                profileImage: profileImage,
                name: name,
                title: title,
                city: city,
                district: district,
              ),
              const SizedBox(height: 16),

              // Admin Paneli Butonu
              if (isAdmin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: card,
                      foregroundColor: gold,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: gold, width: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                UstaSefGorselYonetimi(chefId: chefId))),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('GÖRSELLERİ YÖNET'),
                  ),
                ),

              if (about.trim().isNotEmpty)
                _InfoCard(
                  title: 'Hakkında',
                  child: Text(about,
                      style:
                          const TextStyle(color: Colors.white70, height: 1.5)),
                ),

              _GalleryCard(gallery: gallery),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String profileImage;
  final String name;
  final String title;
  final String city;
  final String district;

  const _HeaderCard({
    required this.profileImage,
    required this.name,
    required this.title,
    required this.city,
    required this.district,
  });

  @override
  Widget build(BuildContext context) {
    final locationText =
        [district.trim(), city.trim()].where((e) => e.isNotEmpty).join(' / ');
    final bool hasImage =
        profileImage.isNotEmpty && profileImage.startsWith('http');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: const Color(0xFFFFB300).withOpacity(0.1),
            backgroundImage: hasImage ? NetworkImage(profileImage) : null,
            child: !hasImage
                ? const Icon(Icons.person, color: Color(0xFFFFB300), size: 48)
                : null,
          ),
          const SizedBox(height: 16),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          if (locationText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFFFFB300), size: 16),
                const SizedBox(width: 4),
                Text(locationText,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final List<String> gallery;
  const _GalleryCard({required this.gallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Galeri',
              style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 16),
          if (gallery.isEmpty)
            const Center(
                child:
                    Text('Görsel yok', style: TextStyle(color: Colors.white38)))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gallery.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(gallery[index], fit: BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }
}
