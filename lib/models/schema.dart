class EventModel {
  final int id;
  String customerName;
  String? customerPhone;
  String? customerEmail;
  DateTime eventDate;
  String? venue;
  double totalAmount;

  EventModel({
    required this.id,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.eventDate,
    this.venue,
    this.totalAmount = 0,
  });

  EventModel copyWith({
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? venue,
    DateTime? eventDate,
    double? totalAmount,
  }) {
    return EventModel(
      id: id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      venue: venue ?? this.venue,
      eventDate: eventDate ?? this.eventDate,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

}

class EventCateringModel {
  final int id;
  final int eventId;
  String category; // matches table: free text; we’ll store Category.label
  String? title;
  String? notes;

  EventCateringModel({
    required this.id,
    required this.eventId,
    required this.category,
    this.title,
    this.notes,
  });
}

class CateringOrderModel {
  final int id;
  final int cateringId;
  String pricingTypeCode; // per_thaal / per_size / per_tray / per_person
  String pricingModeCode; // manual / from_menu_items
  double qty;
  double unitPrice;
  double subtotal;
  String currency;
  String? notes;

  CateringOrderModel({
    required this.id,
    required this.cateringId,
    required this.pricingTypeCode,
    required this.pricingModeCode,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
    required this.currency,
    this.notes,
  });
}

class CateringMenuItemModel {
  final int id;
  final int orderId;
  String menuItemName;
  String? size; // Small/Large/Full/Half
  double qtyPerUnit;
  double? menuItemPrice; // used if pricing_mode = from_menu_items
  String? notes;

  CateringMenuItemModel({
    required this.id,
    required this.orderId,
    required this.menuItemName,
    this.size,
    required this.qtyPerUnit,
    this.menuItemPrice,
    this.notes,
  });
}