import 'enums.dart';

class EventInsert {
  String customerName;
  String? customerPhone;
  String? customerEmail;
  DateTime eventDate;
  String? venue;

  EventInsert({
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.eventDate,
    this.venue,
  });
}

class EventCateringInsert {
  int eventId;
  Category category;
  String? title;
  String? notes;

  EventCateringInsert({
    required this.eventId,
    required this.category,
    this.title,
    this.notes,
  });
}

class CateringOrderInsert {
  int cateringId;
  PricingType pricingType;
  PricingMode pricingMode;
  double qty;
  double unitPrice;
  String currency;
  String? notes;

  CateringOrderInsert({
    required this.cateringId,
    required this.pricingType,
    required this.pricingMode,
    required this.qty,
    required this.unitPrice,
    required this.currency,
    this.notes,
  });
}

class CateringMenuItemInsert {
  int orderId;
  String menuItemName;
  String? size;
  double qtyPerUnit;
  double? menuItemPrice;
  String? notes;

  CateringMenuItemInsert({
    required this.orderId,
    required this.menuItemName,
    this.size,
    required this.qtyPerUnit,
    this.menuItemPrice,
    this.notes,
  });
}