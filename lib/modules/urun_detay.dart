import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrunDetaySayfasi extends StatefulWidget {
  final String urunAdi;
  final String urunFiyat;
  final String urunGorsel;
  final String aciklama;
  final String dukkanAdi;
  final String konum;
  final String youtubeUrl;

  const UrunDetaySayfasi({
    super.key,
    required this.urunAdi,
    required this.urunFiyat,
    required this.urunGorsel,
    required this.aciklama,
    required this.dukkanAdi,
    required this.konum,
    required this.youtubeUrl,
  });

  @override
  State<UrunDetaySayfasi> createState() => _UrunDetaySayfasiState();
}

class _UrunDetaySayfasiState extends State<UrunDetaySayfasi> {
  int adet = 1;

  static const Color _bg = Color(0xFFF8F3EA);
  static const Color _card = Colors.white;
  static const Color _gold = Color(0xFFFFB300);
  static const Color _goldDark = Color(0xFF8A5A00);
  static const Color _textDark = Color(0xFF2D2215);
  static const Color _textMuted = Color(0xFF7A6A58);
  static const Color _border = Color(0xFFE7D6B8);
  static const Color _chipBg = Color(0xFFFFF8EC);

  bool _isHttp(String s) {
    return s.startsWith('http://') || s.startsWith('https://');
  }

  Future<void> _youtubeAc() async {
    final raw = widget.youtubeUrl.trim();
    if (raw.isEmpty) return;

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir YouTube linki bulunamadı.'),
        ),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('YouTube bağlantısı açılamadı.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            elevation: 0,
            backgroundColor: _bg,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: _textDark),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFFF2DFC0),
                    child: _buildHeroImage(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.08),
                          Colors.black.withOpacity(0.18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -18, 0),
              decoration: const BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 14),
                    _buildMetaCard(),
                    const SizedBox(height: 14),
                    _buildDescriptionCard(),
                    const SizedBox(height: 14),
                    _buildQuantityCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildHeroImage() {
    if (_isHttp(widget.urunGorsel)) {
      return Image.network(
        widget.urunGorsel,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildPlaceholder(isLoading: true);
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7E7BF),
            Color(0xFFE7C784),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLoading
                  ? Icons.hourglass_top_rounded
                  : Icons.restaurant_menu_rounded,
              size: 46,
              color: _textDark,
            ),
            const SizedBox(height: 10),
            Text(
              isLoading ? 'Görsel yükleniyor' : 'Ev Lezzeti',
              style: const TextStyle(
                color: _textDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.urunAdi.trim().isEmpty
                      ? 'İsimsiz ürün'
                      : widget.urunAdi,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  widget.urunFiyat.trim().isEmpty
                      ? 'Fiyat yok'
                      : widget.urunFiyat,
                  style: const TextStyle(
                    color: _goldDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniChip(Icons.schedule, 'Bugün hazırlandı'),
              _miniChip(Icons.home_work_outlined, 'Mahalle mutfağı'),
              _miniChip(Icons.local_fire_department_outlined, 'Sınırlı adet'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          if (widget.dukkanAdi.trim().isNotEmpty)
            _infoRow(Icons.storefront_outlined, 'Mutfak', widget.dukkanAdi),
          if (widget.dukkanAdi.trim().isNotEmpty &&
              widget.konum.trim().isNotEmpty)
            const SizedBox(height: 12),
          if (widget.konum.trim().isNotEmpty)
            _infoRow(Icons.location_on_outlined, 'Konum', widget.konum),
          if (widget.dukkanAdi.trim().isNotEmpty ||
              widget.konum.trim().isNotEmpty)
            const SizedBox(height: 12),
          _infoRow(Icons.star_rounded, 'Puan', '4.9 (120+ değerlendirme)'),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÜRÜN AÇIKLAMASI',
            style: TextStyle(
              color: _goldDark,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.aciklama.trim().isEmpty
                ? 'Bu ürün için henüz açıklama girilmedi.'
                : widget.aciklama,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.youtubeUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _youtubeAc,
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text("YouTube'da İzle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF4D9),
                  foregroundColor: _goldDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'ADET',
              style: TextStyle(
                color: _textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _adetButon(Icons.remove, () {
            if (adet > 1) {
              setState(() {
                adet--;
              });
            }
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              adet.toString(),
              style: const TextStyle(
                color: _textDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _adetButon(Icons.add, () {
            setState(() {
              adet++;
            });
          }),
        ],
      ),
    );
  }

  Widget _adetButon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Icon(
          icon,
          color: _goldDark,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$adet adet seçildi',
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: _gold,
                      content: Text(
                        '${widget.urunAdi} sepete eklendi!',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'SEPETE EKLE',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: _goldDark,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: _textDark,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _chipBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Icon(
            icon,
            color: _goldDark,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}
