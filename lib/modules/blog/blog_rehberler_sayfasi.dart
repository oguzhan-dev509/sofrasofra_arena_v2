import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/blog/blog_detay_sayfasi.dart';

class BlogRehberlerSayfasi extends StatefulWidget {
  const BlogRehberlerSayfasi({super.key});

  @override
  State<BlogRehberlerSayfasi> createState() => _BlogRehberlerSayfasiState();
}

class _BlogRehberlerSayfasiState extends State<BlogRehberlerSayfasi> {
  static const Color _bg = Color(0xFF090909);
  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  String _selectedCategory = 'tum';

  static const List<_BlogCategory> _categories = [
    _BlogCategory(label: 'Tümü', value: 'tum'),
    _BlogCategory(label: 'Genel', value: 'genel'),
    _BlogCategory(label: 'Ev Lezzetleri', value: 'ev_lezzetleri'),
    _BlogCategory(label: 'Usta Şefler', value: 'usta_sefler'),
    _BlogCategory(label: 'Restoranlar', value: 'restoranlar'),
    _BlogCategory(label: 'Kurye', value: 'kurye'),
    _BlogCategory(label: 'Teknik Rehber', value: 'teknik_rehber'),
  ];

  String _normalizeCategory(String raw) {
    final value = raw
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    if (value == 'ev' || value == 'ev_lezzeti' || value == 'ev_lezzetleri') {
      return 'ev_lezzetleri';
    }

    if (value == 'usta_sef' ||
        value == 'usta_sefler' ||
        value == 'sef' ||
        value == 'sefler') {
      return 'usta_sefler';
    }

    if (value == 'restoran' ||
        value == 'restoranlar' ||
        value == 'restaurant' ||
        value == 'restaurants') {
      return 'restoranlar';
    }

    if (value == 'kurye' || value == 'kuryeler' || value == 'kurye_agi') {
      return 'kurye';
    }

    if (value == 'teknik' || value == 'teknik_rehber' || value == 'rehber') {
      return 'teknik_rehber';
    }

    return value.isEmpty ? 'genel' : value;
  }

  String _categoryLabel(String value) {
    final normalized = _normalizeCategory(value);

    for (final category in _categories) {
      if (category.value == normalized) {
        return category.label;
      }
    }

    return 'Genel';
  }

  List<_BlogPost> _filteredPosts(List<_BlogPost> all) {
    if (_selectedCategory == 'tum') return all;

    return all
        .where((post) => _normalizeCategory(post.kategori) == _selectedCategory)
        .toList();
  }

  List<_BlogPost> _postsFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final posts = docs
        .map((doc) => _BlogPost.fromDoc(doc.id, doc.data()))
        .where((post) => post.aktifMi)
        .toList();

    posts.sort((a, b) {
      final orderCompare = a.order.compareTo(b.order);
      if (orderCompare != 0) return orderCompare;
      return a.title.compareTo(b.title);
    });

    return posts.isEmpty ? _fallbackPosts : posts;
  }

  void _openPost(_BlogPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlogDetaySayfasi(
          title: post.title,
          summary: post.summary,
          content: post.content,
          kategoriLabel: _categoryLabel(post.kategori),
          coverImage: post.coverImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Blog ve Rehberler',
          style: TextStyle(color: _gold, fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('blog_yazilari')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          final posts = snapshot.hasData
              ? _postsFromDocs(snapshot.data!.docs)
              : _fallbackPosts;

          final filtered = _filteredPosts(posts);

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const _BlogHeroCard(),
              const SizedBox(height: 16),
              _CategoryBar(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onSelected: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                const _EmptyBlogCard()
              else
                ...filtered.map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BlogPostCard(
                      post: post,
                      categoryLabel: _categoryLabel(post.kategori),
                      onTap: () => _openPost(post),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BlogHeroCard extends StatelessWidget {
  const _BlogHeroCard();

  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOFRASOFRA BİLGİ MERKEZİ',
            style: TextStyle(
              color: _gold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Blog ve Rehberler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Ev Lezzetleri, Usta Şefler, Restoranlar ve Kurye Ağı için '
            'radyo metinleri, operasyon rehberleri ve teknik bilgilendirmeler burada arşivlenir.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<_BlogCategory> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.value == selectedCategory;

          return ChoiceChip(
            label: Text(category.label),
            selected: selected,
            onSelected: (_) => onSelected(category.value),
            selectedColor: _gold,
            backgroundColor: const Color(0xFF151515),
            labelStyle: TextStyle(
              color: selected ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: selected ? _gold : Colors.white12,
            ),
          );
        },
      ),
    );
  }
}

class _BlogPostCard extends StatelessWidget {
  final _BlogPost post;
  final String categoryLabel;
  final VoidCallback onTap;

  const _BlogPostCard({
    required this.post,
    required this.categoryLabel,
    required this.onTap,
  });

  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final hasImage = post.coverImage.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
                child: Image.network(
                  post.coverImage,
                  width: 112,
                  height: 126,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 0),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryLabel,
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      post.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Devamını Oku',
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBlogCard extends StatelessWidget {
  const _EmptyBlogCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Text(
        'Bu kategoride henüz yayınlanmış blog yazısı yok.',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}

class _BlogPost {
  final String id;
  final String title;
  final String slug;
  final String summary;
  final String content;
  final String kategori;
  final String coverImage;
  final bool aktifMi;
  final bool featured;
  final int order;

  const _BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    required this.summary,
    required this.content,
    required this.kategori,
    required this.coverImage,
    required this.aktifMi,
    required this.featured,
    required this.order,
  });

  factory _BlogPost.fromDoc(String id, Map<String, dynamic> data) {
    return _BlogPost(
      id: id,
      title: (data['title'] ?? '').toString().trim(),
      slug: (data['slug'] ?? id).toString().trim(),
      summary: (data['summary'] ?? '').toString().trim(),
      content: (data['content'] ?? '').toString().trim(),
      kategori: (data['kategori'] ?? 'genel').toString().trim(),
      coverImage: (data['coverImage'] ?? '').toString().trim(),
      aktifMi: data['aktifMi'] != false,
      featured: data['featured'] == true,
      order: data['order'] is int ? data['order'] as int : 999,
    );
  }
}

class _BlogCategory {
  final String label;
  final String value;

  const _BlogCategory({
    required this.label,
    required this.value,
  });
}

const List<_BlogPost> _fallbackPosts = [
  _BlogPost(
    id: 'sofrasofra-radyo-nedir',
    title: 'Sofrasofra Radyo Nedir?',
    slug: 'sofrasofra-radyo-nedir',
    summary:
        'Sofrasofra Radyo; Ev Lezzetleri, Usta Şefler, Restoranlar ve Kurye Ağı için sesli rehber yayınları sunan bilgi kanalıdır.',
    content:
        'Sofrasofra Radyo, platformun sesli bilgilendirme ve rehberlik alanıdır.\n\n'
        'Ev Lezzetleri üreticileri için başvuru, hijyen, ürün sunumu ve mahalle üretim kültürü anlatılır. '
        'Usta Şefler için şef profili, imza tabakları, akademi içerikleri ve görünürlük modeli açıklanır. '
        'Restoranlar için Gel-Al, Götür, menü vitrini ve fotoğraf bazlı satış yapısı tanıtılır. '
        'Kurye kategorisinde ise mahalle teslimat modeli, kurucu kurye avantajları ve operasyon akışı paylaşılır.\n\n'
        'Blog ve Rehberler alanı, bu radyo yayınlarının yazılı arşivi olarak çalışır. Böylece dinlenen içerikler kalıcı makalelere dönüşür.',
    kategori: 'genel',
    coverImage: '',
    aktifMi: true,
    featured: true,
    order: 1,
  ),
  _BlogPost(
    id: 'ev-lezzetleri-basvuru-rehberi',
    title: 'Ev Lezzetleri Başvuru Rehberi',
    slug: 'ev-lezzetleri-basvuru-rehberi',
    summary:
        'Evde üretim yapan kullanıcılar için Sofrasofra’ya başvuru süreci, temel bilgiler ve hazırlık adımları.',
    content:
        'Ev Lezzetleri, evde pişen emeğin mahallede görünür hale gelmesini hedefler.\n\n'
        'Başvuru sürecinde üreticinin temel iletişim bilgileri, üretim türü, fatura bilgileri ve ürün hazırlık kapasitesi değerlendirilir. '
        'Amaç, ev üreticisinin güvenli, düzenli ve takip edilebilir bir dijital vitrine sahip olmasıdır.\n\n'
        'Sofrasofra, başvuru sonrasında üretici profili, ürün görselleri, fiyatlandırma ve sipariş akışı gibi alanları kademeli olarak güçlendirir.',
    kategori: 'ev_lezzetleri',
    coverImage: '',
    aktifMi: true,
    featured: false,
    order: 2,
  ),
  _BlogPost(
    id: 'usta-sefler-icin-dijital-vitrin',
    title: 'Usta Şefler İçin Dijital Vitrin',
    slug: 'usta-sefler-icin-dijital-vitrin',
    summary:
        'Usta Şefler alanı, şeflerin imza mutfağını, eğitimlerini ve özel hizmetlerini görünür kılmak için tasarlanır.',
    content:
        'Usta Şefler modülü, şefin sadece bir profil sahibi olmasını değil, kendi marka değerini dijital olarak sunmasını hedefler.\n\n'
        'Şefin İmza Tabağı, Şef Akademisi, Şefin Masası ve özel davet hizmetleri bu vitrinin temel parçalarıdır. '
        'Blog içerikleri ise şefin uzmanlığını, hikâyesini ve hizmet modelini daha açıklayıcı bir dille anlatır.',
    kategori: 'usta_sefler',
    coverImage: '',
    aktifMi: true,
    featured: false,
    order: 3,
  ),
  _BlogPost(
    id: 'kurye-agi-nasil-calisir',
    title: 'Sofrasofra Kurye Ağı Nasıl Çalışır?',
    slug: 'kurye-agi-nasil-calisir',
    summary:
        'Kurye Ağı, mahalle teslimatlarını takip edilebilir ve operasyonel olarak düzenli hale getirmek için kurgulanır.',
    content:
        'Sofrasofra Kurye Ağı, sipariş teslimatının mahalle ölçeğinde daha düzenli yönetilmesini amaçlar.\n\n'
        'Kurye süreci siparişin hazırlanması, hazır durumuna geçmesi, uygun kurye adayının belirlenmesi ve teslimat adımlarının izlenmesi mantığıyla ilerler. '
        'Bu yapı hem müşteri hem üretici hem de kurye tarafında daha şeffaf bir operasyon sağlar.',
    kategori: 'kurye',
    coverImage: '',
    aktifMi: true,
    featured: false,
    order: 4,
  ),
];
