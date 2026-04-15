import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SignatureDishesWidget extends StatelessWidget {
  final String chefId;

  const SignatureDishesWidget({super.key, required this.chefId});

  static const _gold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chef_signature_dishes')
          .where('chefId', isEqualTo: chefId)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return _EmptyState(chefId: chefId);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "İmza Mutfağı",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (_, i) {
                final data = docs[i].data() as Map<String, dynamic>;

                return _DishCard(
                  docId: docs[i].id,
                  data: data,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _DishCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _DishCard({
    required this.docId,
    required this.data,
  });

  static const _gold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    final image = data['imageUrl'] ?? '';
    final title = data['title'] ?? '';
    final price = data['price'] ?? 0;

    return GestureDetector(
      onTap: () => _openFullscreen(context, image),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              image,
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white)),
                  Text("$price ₺", style: const TextStyle(color: _gold)),
                ],
              ),
            ),
          ),

          // delete
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () async {
                await FirebaseFirestore.instance
                    .collection('chef_signature_dishes')
                    .doc(docId)
                    .update({'isActive': false});
              },
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.black54,
                child: Icon(Icons.delete, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreen(BuildContext context, String image) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          child: Center(
            child: Image.network(image),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String chefId;

  const _EmptyState({required this.chefId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Henüz imza yemek eklenmedi"),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _addDish(context, chefId),
          child: const Text("İlk Yemeğini Ekle"),
        )
      ],
    );
  }

  Future<void> _addDish(BuildContext context, String chefId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final file = File(picked.path);

    final ref = FirebaseStorage.instance.ref(
        'signature_dishes/$chefId/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(file);

    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('chef_signature_dishes').add({
      'chefId': chefId,
      'title': 'Yeni Yemek',
      'description': '',
      'imageUrl': url,
      'price': 0,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
