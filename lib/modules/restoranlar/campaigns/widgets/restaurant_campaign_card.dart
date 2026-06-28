import 'package:flutter/material.dart';

import '../models/restaurant_campaign_model.dart';

class RestaurantCampaignCard extends StatelessWidget {
  const RestaurantCampaignCard({
    super.key,
    required this.campaign,
    required this.isBusy,
    required this.onEdit,
    required this.onActiveChanged,
    required this.onArchive,
  });

  final RestaurantCampaignModel campaign;
  final bool isBusy;
  final VoidCallback onEdit;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onArchive;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF141414);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = _statusFor(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: status.color.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (campaign.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        campaign.description,
                        style: const TextStyle(
                          color: Colors.white60,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(
                label: status.label,
                color: status.color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.percent_rounded,
                label: campaign.discountLabel,
                isGold: true,
              ),
              _InfoChip(
                icon: Icons.shopping_basket_outlined,
                label: 'Min. ${_currency(campaign.minimumOrderAmount)}',
              ),
              if (campaign.maximumDiscountAmount > 0)
                _InfoChip(
                  icon: Icons.savings_outlined,
                  label: 'Maks. ${_currency(campaign.maximumDiscountAmount)}',
                ),
              _InfoChip(
                icon: Icons.calendar_month_outlined,
                label: '${_date(campaign.startAt)} – ${_date(campaign.endAt)}',
              ),
              if (campaign.isPickupOnly)
                const _InfoChip(
                  icon: Icons.storefront_outlined,
                  label: 'Sadece Gel-Al',
                  isGold: true,
                ),
              if (campaign.neighborhoods.isNotEmpty)
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  label: '${campaign.neighborhoods.length} mahalle',
                ),
            ],
          ),
          const SizedBox(height: 14),
          _UsageSection(campaign: campaign),
          const SizedBox(height: 14),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: campaign.isActive,
                  activeThumbColor: _gold,
                  activeTrackColor: _gold.withValues(alpha: 0.35),
                  title: const Text(
                    'Kampanya aktif',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    campaign.isActive
                        ? 'Müşterilere gösterilebilir'
                        : 'Kampanya pasif',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  onChanged: isBusy ? null : onActiveChanged,
                ),
              ),
              IconButton(
                tooltip: 'Düzenle',
                onPressed: isBusy ? null : onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: _gold,
                ),
              ),
              IconButton(
                tooltip: 'Arşivle',
                onPressed: isBusy ? null : onArchive,
                icon: const Icon(
                  Icons.archive_outlined,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                color: _gold,
                backgroundColor: Colors.white10,
              ),
            ),
        ],
      ),
    );
  }

  _CampaignStatus _statusFor(DateTime now) {
    if (!campaign.isActive) {
      return const _CampaignStatus(
        label: 'Pasif',
        color: Colors.white54,
      );
    }

    if (now.isBefore(campaign.startAt)) {
      return const _CampaignStatus(
        label: 'Planlandı',
        color: Colors.lightBlueAccent,
      );
    }

    if (!now.isBefore(campaign.endAt)) {
      return const _CampaignStatus(
        label: 'Sona Erdi',
        color: Colors.redAccent,
      );
    }

    if (!campaign.hasUsageCapacity) {
      return const _CampaignStatus(
        label: 'Kota Doldu',
        color: Colors.orangeAccent,
      );
    }

    return const _CampaignStatus(
      label: 'Aktif',
      color: Colors.greenAccent,
    );
  }

  static String _currency(double value) {
    return '${value.toStringAsFixed(0)} TL';
  }

  static String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    return '$day.$month.$year';
  }
}

class _UsageSection extends StatelessWidget {
  const _UsageSection({
    required this.campaign,
  });

  final RestaurantCampaignModel campaign;

  @override
  Widget build(BuildContext context) {
    final totalText = campaign.totalLimit > 0
        ? '${campaign.usedCount} / ${campaign.totalLimit}'
        : '${campaign.usedCount} / Sınırsız';

    final dailyText =
        campaign.dailyLimit > 0 ? campaign.dailyLimit.toString() : 'Sınırsız';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _UsageItem(
              label: 'Toplam kullanım',
              value: totalText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _UsageItem(
              label: 'Günlük limit',
              value: dailyText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _UsageItem(
              label: 'Kişi başı',
              value: campaign.perUserLimit.toString(),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageItem extends StatelessWidget {
  const _UsageItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.isGold = false,
  });

  final IconData icon;
  final String label;
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    final color = isGold ? const Color(0xFFFFB300) : Colors.white70;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CampaignStatus {
  const _CampaignStatus({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
}
