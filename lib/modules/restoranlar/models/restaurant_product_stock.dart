class RestaurantProductStockStatus {
  static const String inStock = 'in_stock';
  static const String soldOut = 'sold_out';
  static const String temporarilyOff = 'temporarily_off';

  static const Set<String> values = {
    inStock,
    soldOut,
    temporarilyOff,
  };

  static bool isValid(String? value) {
    return value != null && values.contains(value);
  }

  static bool isOrderable(String? value) {
    return value == null || value == inStock;
  }

  static String label(String? value) {
    switch (value) {
      case soldOut:
        return 'Stok tükendi';
      case temporarilyOff:
        return 'Geçici pasif';
      case inStock:
      default:
        return 'Stokta';
    }
  }
}
