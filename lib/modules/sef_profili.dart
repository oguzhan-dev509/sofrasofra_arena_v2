import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SefProfili extends StatelessWidget {
  final String chefId;

  const SefProfili({super.key, required this.chefId});

  @override
  Widget build(BuildContext context) {
    final ref =
        FirebaseFirestore.instance.collection('chef_profiles').doc(chefId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ŞEF PROFİLİ'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: ref.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text('Şef bulunamadı'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final ad = data['ad'] ?? 'Şef';
          final aciklama = data['aciklama'] ?? '';
          final profilFoto = data['profilFoto'] ?? '';
          final kapakFoto = data['kapakFoto'] ?? '';

          final signature = data['signatureKitchen'] ?? {};
          final academy = data['academy'] ?? {};
          final consulting = data['consulting'] ?? {};
          final portfolio = data['legacyPortfolio'] ?? {};
          final chefsTable = data['chefsTable'] ?? {};

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kapakFoto.isNotEmpty)
                  Image.network(
                    kapakFoto,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        profilFoto.isNotEmpty ? NetworkImage(profilFoto) : null,
                    radius: 30,
                  ),
                  title: Text(
                    ad,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(aciklama),
                ),
                const SizedBox(height: 16),
                _sectionTitle('ŞEFİN İMZA MUTFAĞI'),
                _chipList(signature['imzaTabaklar']),
                _sectionTitle('ŞEF AKADEMİSİ'),
                _chipList(academy['kategoriler']),
                _sectionTitle('CATERING'),
                _chipList(portfolio['projeler']),
                _sectionTitle('DANIŞMANLIK'),
                _chipList(consulting['hizmetler']),
                _sectionTitle('ŞEFİN MASASI'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(chefsTable['aciklama'] ?? ''),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _chipList(dynamic list) {
    if (list == null || list is! List) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: list.map<Widget>((e) {
          return Chip(label: Text(e.toString()));
        }).toList(),
      ),
    );
  }
}
