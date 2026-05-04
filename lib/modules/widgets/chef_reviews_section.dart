import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChefReviewsSection extends StatefulWidget {
  final String chefId;

  const ChefReviewsSection({
    super.key,
    required this.chefId,
  });

  @override
  State<ChefReviewsSection> createState() => _ChefReviewsSectionState();
}

class _ChefReviewsSectionState extends State<ChefReviewsSection> {
  static const Color _gold = Color(0xFFFFB300);
  static const Color _panel = Color(0xFF151515);

  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> get _reviewsRef {
    return FirebaseFirestore.instance
        .collection('chef_profiles')
        .doc(widget.chefId)
        .collection('reviews');
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();

    if (widget.chefId.trim().isEmpty) return;

    if (comment.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kısa bir yorum yazın.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum için giriş yapılmalı.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _reviewsRef.add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Sofrasofra Müşterisi',
        'rating': _rating,
        'comment': comment,
        'isApproved': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('chef_profiles')
          .doc(widget.chefId)
          .set({
        'yorumSayisi': FieldValue.increment(1),
        'sonYorumPuani': _rating,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      _commentController.clear();
      setState(() => _rating = 5);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorumunuz eklendi.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yorum eklenemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _stars({
    required int rating,
    bool editable = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;
        final selected = value <= rating;

        return GestureDetector(
          onTap: editable ? () => setState(() => _rating = value) : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              selected ? Icons.star_rounded : Icons.star_border_rounded,
              color: _gold,
              size: editable ? 24 : 18,
            ),
          ),
        );
      }),
    );
  }

  Widget _reviewCard(Map<String, dynamic> data) {
    final comment = (data['comment'] ?? '').toString().trim();
    final name = (data['userName'] ?? 'Sofrasofra Müşterisi').toString().trim();
    final ratingRaw = data['rating'];
    final rating = ratingRaw is num ? ratingRaw.toInt().clamp(1, 5) : 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stars(rating: rating),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.isNotEmpty ? name : 'Sofrasofra Müşterisi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chefId.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ŞEF YORUMLARI',
            style: TextStyle(
              color: _gold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _reviewsRef
                .where('isApproved', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .limit(8)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(color: _gold),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'Yorumlar yüklenemedi: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Text(
                  'Henüz şef yorumu yok. İlk değerlendirmeyi siz bırakabilirsiniz.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.35,
                  ),
                );
              }

              return Column(
                children: docs.map((doc) => _reviewCard(doc.data())).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _gold.withValues(alpha: 0.20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Şef için yorum bırak',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _stars(rating: _rating, editable: true),
                const SizedBox(height: 10),
                TextField(
                  controller: _commentController,
                  minLines: 2,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        'Şefin lezzet, sunum, eğitim veya deneyimi hakkında yorum yazın...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _gold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submitReview,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.rate_review_rounded),
                    label: Text(_saving ? 'Kaydediliyor...' : 'Yorumu Gönder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
