import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final Widget child;

  const SectionCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: child,
    );
  }
}

class ChipLabel extends StatelessWidget {
  final String text;

  const ChipLabel(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFFB300), size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  final String puan;
  final String mezun;
  final String muhur;

  const StatsRow({
    super.key,
    required this.puan,
    required this.mezun,
    required this.muhur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.star_rounded,
            value: puan,
            label: 'İTİBAR',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.school_rounded,
            value: mezun,
            label: 'MEZUN',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.workspace_premium_rounded,
            value: muhur,
            label: 'MÜHÜR',
          ),
        ),
      ],
    );
  }
}

class NetworkImageWidget extends StatelessWidget {
  final String url;

  const NetworkImageWidget({
    super.key,
    required this.url,
  });

  String _safeHttpUrlOrEmpty(String? value) {
    final safe = (value ?? '').trim();
    if (safe.startsWith('http://') || safe.startsWith('https://')) {
      return safe;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final safe = _safeHttpUrlOrEmpty(url);

    if (safe.isEmpty) {
      return Container(
        color: Colors.white10,
        child: const Center(
          child: Icon(Icons.image, color: Colors.white24),
        ),
      );
    }

    return Image.network(
      safe,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.white10,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white24),
          ),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFFFB300),
            ),
          ),
        );
      },
    );
  }
}
