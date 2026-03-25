import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UstaSefSeedPaneli extends StatefulWidget {
  const UstaSefSeedPaneli({super.key});

  @override
  State<UstaSefSeedPaneli> createState() => _UstaSefSeedPaneliState();
}

class _UstaSefSeedPaneliState extends State<UstaSefSeedPaneli> {
  bool _loading = false;
  String _durum = 'Hazır';

  Future<void> _ornekUstaSefOlustur() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _durum = 'Seed başlatıldı...';
    });

    final firestore = FirebaseFirestore.instance;

    const chefId = 'chef_mehmet_usta';
    const dukkanId = 'chef_mehmet_usta';

    try {
      // 1) urunler → vitrin kartı
      await firestore.collection('urunler').doc('urun_sef_01').set({
        'dukkanId': dukkanId,
        'ownerId': chefId,
        'tip': 'Usta Sefler',
        'onayDurumu': 'onaylandi',
        'isActive': true,
        'ad': 'Mehmet Usta - Gastronomi Akademisi',
        'aciklama': 'Usta şef ile profesyonel mutfak deneyimi',
        'fiyat': 0,
        'kategori': 'Şef Deneyimi',
        'img':
            'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?auto=format&fit=crop&w=1200&q=80',
        'sehir': 'istanbul',
        'ilce': 'kadikoy',
        'hazirlamaSuresiDakika': 60,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2) chef_profiles → profil detay verisi
      await firestore.collection('chef_profiles').doc(chefId).set({
        'chefId': chefId,
        'dukkanId': dukkanId,
        'ad': 'Mehmet Usta',
        'aciklama':
            'Geleneksel Türk mutfağını modern sunumla birleştiren usta şef.',
        'uzmanlik': [
          'Türk Mutfağı',
          'Osmanlı Mutfağı',
          'Yöresel Lezzetler',
        ],
        'sehir': 'İstanbul',
        'ilce': 'Kadıköy',
        'profilFoto':
            'https://images.unsplash.com/photo-1583394293214-28ded15ee548?auto=format&fit=crop&w=1200&q=80',
        'kapakFoto':
            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
        'signatureKitchen': {
          'baslik': 'Şefin İmza Mutfağı',
          'mutfakTarzi': 'Geleneksel + Modern Anadolu',
          'imzaTabaklar': [
            'İçli Köfte',
            'Ali Nazik',
            'Kuzu Tandır',
            'Perde Pilavı',
          ],
          'oneCikanMenuler': [
            'Osmanlı Sofrası',
            'Anadolu Seçkisi',
            'Mevsimsel Tadım Menüsü',
          ],
          'mevsimselSeckiler': [
            'Bahar Otları Menüsü',
            'Kış Güveçleri',
          ],
          'gorseller': [
            'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=1200&q=80',
            'https://images.unsplash.com/photo-1600891964092-4316c288032e?auto=format&fit=crop&w=1200&q=80',
          ],
        },
        'academy': {
          'baslik': 'Şef Akademisi',
          'kategoriler': [
            'Genel Türk Mutfağı',
            'Yöresel Mutfaklar',
            'Osmanlı Saray Mutfağı',
            'Dünya Mutfaklarından Örnekler',
            'Pişirme Teknikleri',
            'Hijyen & Sağlık',
            'Tabak Dizaynı ve Sunum',
            'Müşteri Servisi',
            'Pastacılık Temelleri',
            'Çikolata ve Tatlı Teknikleri',
            'Kafe / İşletme Yönetimi',
          ],
        },
        'legacyPortfolio': {
          'baslik': 'Özel Davet & Catering Arşivi',
          'projeler': [
            '500 Kişilik Düğün Organizasyonu',
            'Kurumsal Lansman Yemeği',
            'VIP Tadım Daveti',
          ],
        },
        'consulting': {
          'baslik': 'Mutfak Danışmanlığı & Kurumsal Çözümler',
          'hizmetler': [
            'Menü Danışmanlığı',
            'Reçete Standardizasyonu',
            'Mutfak Kurulumu',
            'Ekip Eğitimi',
            'Operasyon Akışı Planlama',
          ],
        },
        'chefsTable': {
          'baslik': 'Şefin Masası',
          'aciklama': 'Özel 6 kişilik butik gastronomi deneyimi.',
          'kisiSayisi': 6,
          'fiyat': 2500,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3) courses → örnek akademi içerikleri
      final batch = firestore.batch();

      final c1 = firestore.collection('courses').doc('course_001');
      batch.set(c1, {
        'chefId': chefId,
        'title': 'Genel Türk Mutfağı',
        'description': 'Temel teknikler, reçete mantığı ve mutfak akışı',
        'price': 299,
        'durationMinutes': 180,
        'videoCount': 12,
        'category': 'Türk Mutfağı',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final c2 = firestore.collection('courses').doc('course_002');
      batch.set(c2, {
        'chefId': chefId,
        'title': 'Osmanlı Saray Mutfağı',
        'description': 'Klasik saray reçeteleri ve tarihsel sunum yaklaşımı',
        'price': 449,
        'durationMinutes': 220,
        'videoCount': 18,
        'category': 'Osmanlı Mutfağı',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final c3 = firestore.collection('courses').doc('course_003');
      batch.set(c3, {
        'chefId': chefId,
        'title': 'Pişirme Teknikleri',
        'description': 'Isı kontrolü, mühürleme, fırın ve ocak teknikleri',
        'price': 349,
        'durationMinutes': 160,
        'videoCount': 10,
        'category': 'Teknik',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      setState(() {
        _durum = 'Seed başarıyla tamamlandı.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Örnek Usta Şef verileri Firestore’a yazıldı.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _durum = 'Hata: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seed sırasında hata oluştu: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _seedSil() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _durum = 'Temizlik başlatıldı...';
    });

    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('urunler').doc('urun_sef_01').delete();
      await firestore
          .collection('chef_profiles')
          .doc('chef_mehmet_usta')
          .delete();
      await firestore.collection('courses').doc('course_001').delete();
      await firestore.collection('courses').doc('course_002').delete();
      await firestore.collection('courses').doc('course_003').delete();

      setState(() {
        _durum = 'Seed verileri silindi.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Örnek seed verileri silindi.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _durum = 'Silme hatası: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme sırasında hata oluştu: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USTA ŞEF SEED PANELİ'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Örnek Usta Şef Verisi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bu ekran tek tıkla urunler, chef_profiles ve courses koleksiyonlarına örnek veri yazar.',
                    ),
                    const SizedBox(height: 16),
                    Text('Durum: $_durum'),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _loading ? null : _ornekUstaSefOlustur,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_circle_outline),
                          label: const Text('Örnek Şef Oluştur'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _seedSil,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Seed Verisini Sil'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
