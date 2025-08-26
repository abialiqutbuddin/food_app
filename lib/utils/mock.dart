import '../models/insert.dart';
import '../models/schema.dart';
import '../models/enums.dart';

class MockRepo {
  int _id = 1000;
  int nextId() => ++_id;

  final events = <EventModel>[];
  final caterings = <EventCateringModel>[];
  final orders = <CateringOrderModel>[];
  final menuItems = <CateringMenuItemModel>[];

  // Demo lookups (replace with API later)
  final demoSizes = const ['Small', 'Large', 'Full', 'Half'];
  final demoMenuItems = const [
    'Chicken Korma', 'Thai Soup', 'Green Salad',
    'Biryani', 'Kofta Tarkari', 'Chicken Sticks', 'Custard', 'Popcorn'
  ];

  EventModel createEvent(EventInsert dto) {
    final e = EventModel(
      id: nextId(),
      customerName: dto.customerName,
      customerPhone: dto.customerPhone,
      customerEmail: dto.customerEmail,
      eventDate: dto.eventDate,
      venue: dto.venue,
    );
    events.add(e);
    return e;
  }

  EventCateringModel createCatering(EventCateringInsert dto) {
    final c = EventCateringModel(
      id: nextId(),
      eventId: dto.eventId,
      category: dto.category.label,
      title: dto.title,
      notes: dto.notes,
    );
    caterings.add(c);
    return c;
  }

  CateringOrderModel createOrder(CateringOrderInsert dto) {
    final subtotal = dto.qty * dto.unitPrice;
    final o = CateringOrderModel(
      id: nextId(),
      cateringId: dto.cateringId,
      pricingTypeCode: dto.pricingType.code,
      pricingModeCode: dto.pricingMode.code,
      qty: dto.qty,
      unitPrice: dto.unitPrice,
      subtotal: subtotal,
      currency: dto.currency,
      notes: dto.notes,
    );
    orders.add(o);
    _recomputeEventTotal(o.cateringId);
    return o;
  }

  CateringMenuItemModel addMenuItem(CateringMenuItemInsert dto) {
    final m = CateringMenuItemModel(
      id: nextId(),
      orderId: dto.orderId,
      menuItemName: dto.menuItemName,
      size: dto.size,
      qtyPerUnit: dto.qtyPerUnit,
      menuItemPrice: dto.menuItemPrice,
      notes: dto.notes,
    );
    menuItems.add(m);
    return m;
  }

  void updateOrderUnitPrice(int orderId, double newUnitPrice) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    final o = orders[idx];
    final updated = CateringOrderModel(
      id: o.id,
      cateringId: o.cateringId,
      pricingTypeCode: o.pricingTypeCode,
      pricingModeCode: o.pricingModeCode,
      qty: o.qty,
      unitPrice: newUnitPrice,
      subtotal: newUnitPrice * o.qty,
      currency: o.currency,
      notes: o.notes,
    );
    orders[idx] = updated;
    _recomputeEventTotal(updated.cateringId);
  }

  void _recomputeEventTotal(int cateringId) {
    final cat = caterings.firstWhere((c) => c.id == cateringId);
    final event = events.firstWhere((e) => e.id == cat.eventId);
    final eventOrders = orders.where((o) => caterings.any((c) => c.id == o.cateringId && c.eventId == event.id));
    event.totalAmount = eventOrders.fold(0.0, (sum, o) => sum + o.subtotal);
  }
}