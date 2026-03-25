import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../lib/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  const chefId = 'chef_mehmet_usta';
  const dukkanId = 'chef_mehmet_usta';

  print('🚀 SEED BAŞLADI');

  // =========================
  // 1. URUNLER (VİTRİN)
  // =========================
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
    'img': 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f',
    'sehir': 'istanbul',
    'ilce': 'kadikoy',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  print('✅ urunler tamam');

  // =========================
  // 2. CHEF PROFILE
  // =========================
  await firestore.collection('chef_profiles').doc(chefId).set({
    'chefId': chefId,
    'ad': 'Mehmet Usta',
    'uzmanlik': ['Türk Mutfağı', 'Osmanlı Mutfağı'],
    'sehir': 'İstanbul',

    // 🔥 ŞEFİN İMZA MUTFAĞI
    'signatureKitchen': {
      'imzaTabaklar': ['İçli Köfte', 'Ali Nazik', 'Kuzu Tandır'],
      'mutfakTarzi': 'Geleneksel + Modern',
      'oneCikanMenuler': ['Osmanlı Sofrası', 'Anadolu Seçkisi'],
      'gorseller': [
        'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d'
      ]
    },

    // 🎓 AKADEMİ
    'academy': {
      'kategoriler': [
        'Genel Türk Mutfağı',
        'Osmanlı Saray Mutfağı',
        'Pişirme Teknikleri',
        'Hijyen & Sağlık',
        'Sunum Teknikleri'
      ]
    },

    // 🏛️ PORTFOLYO
    'legacyPortfolio': {
      'cateringler': ['500 Kişilik Düğün', 'Kurumsal Lansman']
    },

    // 💼 DANIŞMANLIK
    'consulting': {
      'hizmetler': ['Menü Danışmanlığı', 'Mutfak Kurulumu', 'Personel Eğitimi']
    },

    // 🍽️ ŞEFİN MASASI
    'chefsTable': {
      'deneyim': 'Özel 6 kişilik fine dining deneyimi',
      'fiyat': 2500
    },

    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  print('✅ chef_profiles tamam');

  // =========================
  // 3. COURSES
  // =========================
  await firestore.collection('courses').doc('course_001').set({
    'chefId': chefId,
    'title': 'Genel Türk Mutfağı',
    'description': 'Temel teknikler ve reçete mantığı',
    'price': 299,
    'durationMinutes': 180,
    'videoCount': 12,
    'category': 'Türk Mutfağı',
    'createdAt': FieldValue.serverTimestamp(),
  });

  print('✅ courses tamam');

  print('🔥 SEED TAMAMLANDI');
}
