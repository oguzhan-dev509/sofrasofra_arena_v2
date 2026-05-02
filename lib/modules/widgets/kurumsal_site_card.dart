import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class KurumsalSiteCard extends StatelessWidget {
  const KurumsalSiteCard({super.key});

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF090909);
  static const Color _panel = Color(0xFF151515);
  static const String _siteUrl = 'https://sofrasofra.com';
  static const bool _siteReady = false;
  Future<void> _openSite(BuildContext context) async {
    if (!_siteReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kurumsal site çok yakında yayında olacak.'),
        ),
      );
      return;
    }

    final uri = Uri.parse(_siteUrl);

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kurumsal site açılamadı.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _gold.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => _openSite(context),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.38),
                  ),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: _gold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kurumsal Site',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Hakkımızda, iş ortaklığı, mahalle mutfak ağı, blog ve hukuki bilgiler.',
                      style: TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Evde pişen emek, mahallede değer bulur.',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.open_in_new_rounded,
                  color: _gold,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
