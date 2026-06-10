import 'package:cloud_firestore/cloud_firestore.dart';

class RestoranModel {
  const RestoranModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.cuisine,
    required this.city,
    required this.district,
    required this.preparationText,
    required this.ratingText,
    this.membershipType = 'free',
    this.isFounder = true,
    this.isOpen = false,
    this.isLaunchReady = false,
    this.supportsGelAl = true,
    this.supportsGotur = true,
    this.temporarilyClosed = false,
    this.temporaryClosedUntil,
    this.temporaryClosedReason = '',
    this.workingHours = const <String, dynamic>{},
    this.timezone = 'Europe/Istanbul',
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String cuisine;
  final String city;
  final String district;
  final String preparationText;
  final String ratingText;
  final String membershipType;
  final bool isFounder;
  final bool isOpen;
  final bool isLaunchReady;
  final bool supportsGelAl;
  final bool supportsGotur;
  final bool temporarilyClosed;
  final DateTime? temporaryClosedUntil;
  final String temporaryClosedReason;
  final Map<String, dynamic> workingHours;
  final String timezone;
  DateTime get _istanbulNow {
    return DateTime.now().toUtc().add(const Duration(hours: 3));
  }

  String get _todayKey {
    switch (_istanbulNow.weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return '';
    }
  }

  Map<String, dynamic> get _todayWorkingHours {
    final raw = workingHours[_todayKey];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return const <String, dynamic>{};
  }

  int? _timeTextToMinutes(dynamic rawValue) {
    final value = (rawValue ?? '').toString().trim();
    final parts = value.split(':');

    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return (hour * 60) + minute;
  }

  bool get isTemporaryClosureActive {
    if (!temporarilyClosed) return false;

    final until = temporaryClosedUntil;

    // Süresiz geçici kapatma
    if (until == null) return true;

    return until.isAfter(DateTime.now());
  }

  bool get isTodayEnabled {
    // Eski restoranlarda workingHours yoksa mevcut davranışı korur.
    if (workingHours.isEmpty) return true;

    return _todayWorkingHours['enabled'] != false;
  }

  bool get isInsideWorkingHours {
    // Eski restoranlarda saat bilgisi yoksa mevcut davranışı korur.
    if (workingHours.isEmpty) return true;

    final today = _todayWorkingHours;

    if (today.isEmpty || today['enabled'] == false) {
      return false;
    }

    final openMinutes = _timeTextToMinutes(today['open']);
    final closeMinutes = _timeTextToMinutes(today['close']);

    if (openMinutes == null || closeMinutes == null) {
      return true;
    }

    final now = _istanbulNow;
    final currentMinutes = (now.hour * 60) + now.minute;

    // Gece yarısını aşmayan normal çalışma aralığı
    if (closeMinutes > openMinutes) {
      return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
    }

    // Örneğin 18:00–02:00 gibi gece yarısını aşan çalışma aralığı
    if (closeMinutes < openMinutes) {
      return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
    }

    // Açılış ve kapanış aynıysa kapalı kabul edilir.
    return false;
  }

  bool get isEffectivelyOpen {
    return isOpen &&
        !isTemporaryClosureActive &&
        isTodayEnabled &&
        isInsideWorkingHours;
  }

  String get effectiveStatusText {
    if (!isOpen) {
      return 'Restoran kapalı';
    }

    if (isTemporaryClosureActive) {
      final reason = temporaryClosedReason.trim();

      if (reason.isNotEmpty) {
        return reason;
      }

      return 'Geçici olarak siparişe kapalı';
    }

    if (!isTodayEnabled) {
      return 'Bugün kapalı';
    }

    final today = _todayWorkingHours;
    final openText = (today['open'] ?? '').toString().trim();
    final closeText = (today['close'] ?? '').toString().trim();

    if (!isInsideWorkingHours) {
      final openMinutes = _timeTextToMinutes(openText);
      final now = _istanbulNow;
      final currentMinutes = (now.hour * 60) + now.minute;

      if (openMinutes != null && currentMinutes < openMinutes) {
        return openText.isEmpty ? 'Henüz açılmadı' : '$openText’da açılıyor';
      }

      return 'Çalışma saatleri dışında';
    }

    if (closeText.isNotEmpty) {
      return 'Açık • $closeText’da kapanıyor';
    }

    return 'Açık';
  }

  String get locationText {
    if (city.trim().isEmpty) return district;
    return '$district / $city';
  }

  String get serviceText {
    final services = <String>[];

    if (supportsGelAl) {
      services.add('Gel-Al');
    }

    if (supportsGotur) {
      services.add('Götür');
    }

    if (services.isEmpty) {
      return 'Servis hazırlanıyor';
    }

    return services.join(' • ');
  }

  String get launchStatusText {
    if (isEffectivelyOpen) {
      return effectiveStatusText;
    }

    if (isOpen || temporarilyClosed || workingHours.isNotEmpty) {
      return effectiveStatusText;
    }

    if (isLaunchReady) {
      return 'Lansmana Hazır';
    }

    return 'Lansmana Hazırlanıyor';
  }

  int get galleryPhotoLimit {
    final type = membershipType.toLowerCase().trim();

    if (type == 'pro' ||
        type == 'kurumsal' ||
        type == 'corporate' ||
        type == 'enterprise') {
      return 24;
    }

    if (type == 'premium') {
      return 12;
    }

    return 6;
  }

  String get membershipLabel {
    final type = membershipType.toLowerCase().trim();

    if (type == 'pro' ||
        type == 'kurumsal' ||
        type == 'corporate' ||
        type == 'enterprise') {
      return 'Pro / Kurumsal Restoran';
    }

    if (type == 'premium') {
      return 'Premium Restoran';
    }

    return 'Free Restoran';
  }

  static RestoranModel fromMap(String id, Map<String, dynamic> data) {
    return RestoranModel(
      id: id,
      name: (data['name'] ?? data['restaurantName'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? data['img'] ?? '').toString(),
      cuisine: (data['cuisine'] ?? data['cuisineType'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      district: (data['district'] ?? '').toString(),
      preparationText:
          (data['preparationText'] ?? data['averagePreparationText'] ?? '')
              .toString(),
      ratingText: (data['ratingText'] ?? data['rating'] ?? '').toString(),
      membershipType: (data['membershipType'] ??
              data['packageType'] ??
              data['plan'] ??
              data['subscriptionTier'] ??
              'free')
          .toString()
          .toLowerCase()
          .trim(),
      isFounder: data['isFounder'] == true,
      isOpen: data['isOpen'] == true,
      isLaunchReady: data['isLaunchReady'] == true,
      supportsGelAl: data['supportsGelAl'] != false,
      supportsGotur: data['supportsGotur'] != false,
      temporarilyClosed: data['temporarilyClosed'] == true,
      temporaryClosedUntil: data['temporaryClosedUntil'] is Timestamp
          ? (data['temporaryClosedUntil'] as Timestamp).toDate()
          : null,
      temporaryClosedReason: (data['temporaryClosedReason'] ?? '').toString(),
      workingHours: data['workingHours'] is Map
          ? Map<String, dynamic>.from(data['workingHours'] as Map)
          : const <String, dynamic>{},
      timezone: (data['timezone'] ?? 'Europe/Istanbul').toString(),
    );
  }
}
