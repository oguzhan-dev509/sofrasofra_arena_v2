import 'package:flutter/material.dart';

import '../models/restaurant_campaign_model.dart';
import '../services/restaurant_campaign_service.dart';
import '../widgets/restaurant_campaign_card.dart';

class RestaurantCampaignManagementPage extends StatefulWidget {
  const RestaurantCampaignManagementPage({
    super.key,
    required this.restaurantId,
    this.restaurantName = '',
  });

  final String restaurantId;
  final String restaurantName;

  @override
  State<RestaurantCampaignManagementPage> createState() =>
      _RestaurantCampaignManagementPageState();
}

class _RestaurantCampaignManagementPageState
    extends State<RestaurantCampaignManagementPage> {
  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF070707);

  String? _busyCampaignId;

  bool _isBusy(String campaignId) {
    return _busyCampaignId == campaignId || _busyCampaignId == '__create__';
  }

  Future<void> _openCampaignForm({
    RestaurantCampaignModel? campaign,
  }) async {
    final result = await showDialog<RestaurantCampaignModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CampaignFormDialog(
        restaurantId: widget.restaurantId,
        campaign: campaign,
      ),
    );

    if (result == null || !mounted) return;

    final busyId = result.id.trim().isEmpty ? '__create__' : result.id;

    setState(() => _busyCampaignId = busyId);

    try {
      if (result.id.trim().isEmpty) {
        await RestaurantCampaignService.createCampaign(
          campaign: result,
        );
      } else {
        await RestaurantCampaignService.updateCampaign(
          campaign: result,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              result.id.trim().isEmpty
                  ? 'Kampanya oluşturuldu.'
                  : 'Kampanya güncellendi.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Kampanya kaydedilemedi: $error',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _busyCampaignId = null);
      }
    }
  }

  Future<void> _setCampaignActive({
    required RestaurantCampaignModel campaign,
    required bool isActive,
  }) async {
    setState(() => _busyCampaignId = campaign.id);

    try {
      await RestaurantCampaignService.setCampaignActive(
        restaurantId: widget.restaurantId,
        campaignId: campaign.id,
        isActive: isActive,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'Kampanya etkinleştirildi.'
                  : 'Kampanya pasif duruma alındı.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Kampanya durumu değiştirilemedi: $error',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _busyCampaignId = null);
      }
    }
  }

  Future<void> _archiveCampaign(
    RestaurantCampaignModel campaign,
  ) async {
    final shouldArchive = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141414),
          title: const Text(
            'Kampanyayı Arşivle',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '"${campaign.title}" kampanyası arşivlenecek. '
            'Kampanya müşterilere gösterilmeyecek ancak geçmiş kaydı korunacak.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Arşivle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (shouldArchive != true || !mounted) return;

    setState(() => _busyCampaignId = campaign.id);

    try {
      await RestaurantCampaignService.archiveCampaign(
        restaurantId: widget.restaurantId,
        campaignId: campaign.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Kampanya arşivlendi.'),
          ),
        );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Kampanya arşivlenemedi: $error',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _busyCampaignId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantLabel = widget.restaurantName.trim().isEmpty
        ? 'Restoran'
        : widget.restaurantName.trim();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'KAMPANYA YÖNETİMİ',
          style: TextStyle(
            color: _gold,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _gold,
        foregroundColor: Colors.black,
        onPressed: _busyCampaignId == null ? () => _openCampaignForm() : null,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Yeni Kampanya',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: StreamBuilder<List<RestaurantCampaignModel>>(
        stream: RestaurantCampaignService.streamCampaigns(
          widget.restaurantId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageBox(
              icon: Icons.error_outline_rounded,
              title: 'Kampanyalar okunamadı',
              message: '${snapshot.error}',
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: _gold,
              ),
            );
          }

          final campaigns = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            children: [
              _HeaderCard(
                restaurantLabel: restaurantLabel,
                campaignCount: campaigns.length,
                onCreate:
                    _busyCampaignId == null ? () => _openCampaignForm() : null,
              ),
              const SizedBox(height: 16),
              if (campaigns.isEmpty)
                const _MessageBox(
                  icon: Icons.campaign_outlined,
                  title: 'Henüz kampanya yok',
                  message:
                      'Mahallenize özel indirim oluşturarak yeni müşteri kazanabilir ve Gel-Al siparişlerini artırabilirsiniz.',
                )
              else
                ...campaigns.map(
                  (campaign) => RestaurantCampaignCard(
                    campaign: campaign,
                    isBusy: _isBusy(campaign.id),
                    onEdit: () => _openCampaignForm(
                      campaign: campaign,
                    ),
                    onActiveChanged: (value) => _setCampaignActive(
                      campaign: campaign,
                      isActive: value,
                    ),
                    onArchive: () => _archiveCampaign(campaign),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CampaignFormDialog extends StatefulWidget {
  const _CampaignFormDialog({
    required this.restaurantId,
    this.campaign,
  });

  final String restaurantId;
  final RestaurantCampaignModel? campaign;

  @override
  State<_CampaignFormDialog> createState() => _CampaignFormDialogState();
}

class _CampaignFormDialogState extends State<_CampaignFormDialog> {
  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF141414);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountController;
  late final TextEditingController _minimumOrderController;
  late final TextEditingController _maximumDiscountController;
  late final TextEditingController _dailyLimitController;
  late final TextEditingController _totalLimitController;
  late final TextEditingController _perUserLimitController;
  late final TextEditingController _neighborhoodsController;

  late RestaurantCampaignType _type;
  late String _deliveryScope;
  late DateTime _startAt;
  late DateTime _endAt;
  late bool _isActive;

  bool get _isEditing => widget.campaign != null;

  @override
  void initState() {
    super.initState();

    final campaign = widget.campaign;
    final now = DateTime.now();

    _titleController = TextEditingController(
      text: campaign?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: campaign?.description ?? '',
    );
    _discountController = TextEditingController(
      text: campaign == null ? '' : _numberText(campaign.discountValue),
    );
    _minimumOrderController = TextEditingController(
      text: campaign == null ? '' : _numberText(campaign.minimumOrderAmount),
    );
    _maximumDiscountController = TextEditingController(
      text: campaign == null || campaign.maximumDiscountAmount <= 0
          ? ''
          : _numberText(
              campaign.maximumDiscountAmount,
            ),
    );
    _dailyLimitController = TextEditingController(
      text: campaign == null || campaign.dailyLimit <= 0
          ? ''
          : campaign.dailyLimit.toString(),
    );
    _totalLimitController = TextEditingController(
      text: campaign == null || campaign.totalLimit <= 0
          ? ''
          : campaign.totalLimit.toString(),
    );
    _perUserLimitController = TextEditingController(
      text: (campaign?.perUserLimit ?? 1).toString(),
    );
    _neighborhoodsController = TextEditingController(
      text: campaign?.neighborhoods.join(', ') ?? '',
    );

    _type = campaign?.type ?? RestaurantCampaignType.percentage;
    _deliveryScope = _initialDeliveryScope(campaign);
    _startAt = campaign?.startAt ?? now;
    _endAt = campaign?.endAt ?? now.add(const Duration(days: 7));
    _isActive = campaign?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _minimumOrderController.dispose();
    _maximumDiscountController.dispose();
    _dailyLimitController.dispose();
    _totalLimitController.dispose();
    _perUserLimitController.dispose();
    _neighborhoodsController.dispose();
    super.dispose();
  }

  String _initialDeliveryScope(
    RestaurantCampaignModel? campaign,
  ) {
    if (campaign == null) return 'all';

    if (campaign.isPickupOnly) return 'gel_al';

    if (campaign.deliveryModes.length == 1) {
      final mode = campaign.deliveryModes.first;

      if (mode == 'gel_al' || mode == 'gotur') {
        return mode;
      }
    }

    return 'all';
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime.now().subtract(
        const Duration(days: 1),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 730),
      ),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _startAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
      );

      if (!_endAt.isAfter(_startAt)) {
        _endAt = _startAt.add(
          const Duration(days: 7),
        );
      }
    });
  }

  Future<void> _selectEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endAt.isAfter(_startAt)
          ? _endAt
          : _startAt.add(const Duration(days: 1)),
      firstDate: _startAt.add(
        const Duration(days: 1),
      ),
      lastDate: _startAt.add(
        const Duration(days: 730),
      ),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _endAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        23,
        59,
        59,
      );
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final discountValue = _parseDouble(_discountController.text);
    final minimumOrderAmount = _parseDouble(_minimumOrderController.text);
    final maximumDiscountAmount = _parseDouble(_maximumDiscountController.text);
    final dailyLimit = _parseInt(_dailyLimitController.text);
    final totalLimit = _parseInt(_totalLimitController.text);
    final perUserLimit = _parseInt(_perUserLimitController.text);

    if (!_endAt.isAfter(_startAt)) {
      _showError(
        'Kampanya bitiş tarihi başlangıç tarihinden sonra olmalıdır.',
      );
      return;
    }

    if (_type != RestaurantCampaignType.fixedAmount && discountValue > 20) {
      _showError(
        'Yüzde indirimi en fazla %20 olabilir.',
      );
      return;
    }

    if (_type == RestaurantCampaignType.fixedAmount &&
        discountValue >= minimumOrderAmount) {
      _showError(
        'Sabit indirim tutarı minimum sepet tutarından düşük olmalıdır.',
      );
      return;
    }

    if (totalLimit > 0 && dailyLimit > totalLimit) {
      _showError(
        'Günlük limit toplam kullanım limitinden büyük olamaz.',
      );
      return;
    }

    if (totalLimit > 0 && perUserLimit > totalLimit) {
      _showError(
        'Kişi başı limit toplam kullanım limitinden büyük olamaz.',
      );
      return;
    }

    final deliveryModes = _type == RestaurantCampaignType.pickupOnly
        ? const <String>['gel_al']
        : switch (_deliveryScope) {
            'gel_al' => const <String>['gel_al'],
            'gotur' => const <String>['gotur'],
            _ => const <String>['gel_al', 'gotur'],
          };

    final neighborhoods = _neighborhoodsController.text
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final existing = widget.campaign;

    final campaign = RestaurantCampaignModel(
      id: existing?.id ?? '',
      restaurantId: widget.restaurantId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _type,
      discountValue: discountValue,
      minimumOrderAmount: minimumOrderAmount,
      maximumDiscountAmount: maximumDiscountAmount,
      startAt: _startAt,
      endAt: _endAt,
      isActive: _isActive,
      dailyLimit: dailyLimit,
      totalLimit: totalLimit,
      perUserLimit: perUserLimit,
      usedCount: existing?.usedCount ?? 0,
      neighborhoods: neighborhoods,
      deliveryModes: deliveryModes,
      productIds: existing?.productIds ?? const <String>[],
      fundedBy: 'restaurant',
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
      createdBy: existing?.createdBy ?? '',
      updatedBy: existing?.updatedBy ?? '',
    );

    Navigator.pop(context, campaign);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final discountLabel = _type == RestaurantCampaignType.fixedAmount
        ? 'İndirim tutarı (TL)'
        : 'İndirim oranı (%)';

    return AlertDialog(
      backgroundColor: _card,
      insetPadding: const EdgeInsets.all(16),
      title: Text(
        _isEditing ? 'Kampanyayı Düzenle' : 'Yeni Mahalle Kampanyası',
        style: const TextStyle(
          color: _gold,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(
                  controller: _titleController,
                  label: 'Kampanya başlığı',
                  hint: 'Merter Mahallesi’ne Özel %10',
                  validator: _requiredTextValidator,
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _descriptionController,
                  label: 'Açıklama',
                  hint: 'Mahalle müşterilerine özel avantaj',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RestaurantCampaignType>(
                  key: ValueKey(_type),
                  initialValue: _type,
                  dropdownColor: _card,
                  decoration: _inputDecoration('Kampanya türü'),
                  items: RestaurantCampaignType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.label,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _type = value;

                      if (_type == RestaurantCampaignType.pickupOnly) {
                        _deliveryScope = 'gel_al';
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _discountController,
                        label: discountLabel,
                        hint: _type == RestaurantCampaignType.fixedAmount
                            ? '50'
                            : '10',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _positiveNumberValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        controller: _minimumOrderController,
                        label: 'Minimum sepet (TL)',
                        hint: '300',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _positiveNumberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _textField(
                  controller: _maximumDiscountController,
                  label: 'Maksimum indirim (TL)',
                  hint: 'Boş bırakılırsa sınır yok',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _nonNegativeNumberValidator,
                ),
                const SizedBox(height: 12),
                if (_type != RestaurantCampaignType.pickupOnly)
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      '${_type.value}-$_deliveryScope',
                    ),
                    initialValue: _deliveryScope,
                    dropdownColor: _card,
                    decoration: _inputDecoration(
                      'Geçerli sipariş türü',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(
                          'Gel-Al ve Götür',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'gel_al',
                        child: Text(
                          'Yalnızca Gel-Al',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'gotur',
                        child: Text(
                          'Yalnızca Götür',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(
                        () => _deliveryScope = value,
                      );
                    },
                  )
                else
                  const _NoticeBox(
                    text:
                        'Gel-Al kampanyası yalnızca gel_al siparişlerinde geçerlidir.',
                  ),
                const SizedBox(height: 12),
                _textField(
                  controller: _neighborhoodsController,
                  label: 'Geçerli mahalleler',
                  hint: 'Merter, Tozkoparan, Haznedar',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Başlangıç',
                        value: _dateText(_startAt),
                        onPressed: _selectStartDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateButton(
                        label: 'Bitiş',
                        value: _dateText(_endAt),
                        onPressed: _selectEndDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _dailyLimitController,
                        label: 'Günlük limit',
                        hint: 'Boş = sınırsız',
                        keyboardType: TextInputType.number,
                        validator: _nonNegativeIntegerValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        controller: _totalLimitController,
                        label: 'Toplam limit',
                        hint: 'Boş = sınırsız',
                        keyboardType: TextInputType.number,
                        validator: _nonNegativeIntegerValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(
                        controller: _perUserLimitController,
                        label: 'Kişi başı',
                        hint: '1',
                        keyboardType: TextInputType.number,
                        validator: _positiveIntegerValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  activeThumbColor: _gold,
                  activeTrackColor: _gold.withValues(alpha: 0.35),
                  title: const Text(
                    'Kampanya aktif olsun',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: const Text(
                    'Tarih ve diğer koşullar uygunsa müşterilere gösterilebilir.',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                ),
                const _NoticeBox(
                  text:
                      'İndirim maliyeti restoran tarafından karşılanır. Teslimat ve kurye tutarı indirime dahil edilmez.',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(
            _isEditing ? 'Güncelle' : 'Oluştur',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(
        label,
        hint: hint,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: Colors.white60,
      ),
      hintStyle: const TextStyle(
        color: Colors.white30,
      ),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.26),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.white12,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _gold,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
    );
  }

  String? _requiredTextValidator(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Bu alan zorunludur.';
    }

    return null;
  }

  String? _positiveNumberValidator(String? value) {
    final number = _parseDouble(value ?? '');

    if (!number.isFinite || number <= 0) {
      return 'Sıfırdan büyük değer girin.';
    }

    return null;
  }

  String? _nonNegativeNumberValidator(String? value) {
    if ((value ?? '').trim().isEmpty) return null;

    final number = _parseDouble(value ?? '');

    if (!number.isFinite || number < 0) {
      return 'Geçerli bir tutar girin.';
    }

    return null;
  }

  String? _nonNegativeIntegerValidator(String? value) {
    if ((value ?? '').trim().isEmpty) return null;

    final number = int.tryParse((value ?? '').trim());

    if (number == null || number < 0) {
      return '0 veya üzeri girin.';
    }

    return null;
  }

  String? _positiveIntegerValidator(String? value) {
    final number = int.tryParse((value ?? '').trim());

    if (number == null || number < 1) {
      return 'En az 1 olmalı.';
    }

    return null;
  }

  static double _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  static int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  static String _numberText(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  static String _dateText(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');

    return '$day.$month.${value.year}';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.restaurantLabel,
    required this.campaignCount,
    required this.onCreate,
  });

  final String restaurantLabel;
  final int campaignCount;
  final VoidCallback? onCreate;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF201A08),
            Color(0xFF111111),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.campaign_rounded,
            color: _gold,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            restaurantLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$campaignCount aktif veya planlı kampanya kaydı',
            style: const TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yeni Kampanya Oluştur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_month_outlined),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('$label\n$value'),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(
          color: Colors.white24,
        ),
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(
          maxWidth: 620,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white12,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFFFFB300),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
