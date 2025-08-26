  import 'package:get/get.dart';
  import '../../models/enums.dart';
  import '../../models/insert.dart';
  import '../../models/schema.dart';
  import '../../utils/mock.dart';

  class EventController extends GetxController {
    final repo = MockRepo();

    // Reactive state
    final currentEvent = Rxn<EventModel>();
    final eventCaterings = <EventCateringModel>[].obs;
    final orders = <CateringOrderModel>[].obs;
    final menuItems = <CateringMenuItemModel>[].obs;

    // Lookups
    List<String> get sizes => repo.demoSizes;
    List<String> get menuItemNames => repo.demoMenuItems;

// New explicit size sets (use these in UI)
    List<String> get traySizes   => const ['Full', 'Half'];
    List<String> get thaaliSizes => const ['Small', 'Medium', 'Large'];

    // Init demo event
    @override
    void onInit() {
      super.onInit();
      final evt = repo.createEvent(EventInsert(
        customerName: 'Ali Raza',
        eventDate: DateTime.now(),
        venue: 'Banquet A',
      ));
      currentEvent.value = evt;
      _refresh();
    }

    // ADD near the top of the class
    final pendingMenu = <int, List<String>>{}.obs; // cateringId -> list of names

    void pendingMenuAdd(int cateringId, String name) {
      final list = (pendingMenu[cateringId] ?? <String>[]);
      list.add(name);
      pendingMenu[cateringId] = List.from(list);
    }

    void pendingMenuRemove(int cateringId, int index) {
      final list = (pendingMenu[cateringId] ?? <String>[]);
      if (index >= 0 && index < list.length) {
        list.removeAt(index);
        pendingMenu[cateringId] = List.from(list);
      }
    }

    void pendingMenuClear(int cateringId) {
      pendingMenu[cateringId] = <String>[];
    }

    // add near other methods
    List<CateringMenuItemModel> itemsForOrder(int orderId) {
      return menuItems.where((m) => m.orderId == orderId).toList();
    }


    void updateCustomerName(String v) => _patchEvent(customerName: v);
    void updateCustomerPhone(String v) => _patchEvent(customerPhone: v);
    void updateCustomerEmail(String v) => _patchEvent(customerEmail: v);
    void updateVenue(String v) => _patchEvent(venue: v);
    void updateEventDate(DateTime v) => _patchEvent(eventDate: v);

    void _patchEvent({
      String? customerName,
      String? customerPhone,
      String? customerEmail,
      String? venue,
      DateTime? eventDate,
    }) {
      final cur = currentEvent.value;
      if (cur == null) return;

      // Prefer copyWith if your EventModel supports it
      final updated = cur.copyWith(
        customerName: customerName ?? cur.customerName,
        customerPhone: customerPhone ?? cur.customerPhone,
        customerEmail: customerEmail ?? cur.customerEmail,
        venue: venue ?? cur.venue,
        eventDate: eventDate ?? cur.eventDate,
      );

      // Try to persist in repo if such a method exists; otherwise just update state.
      try {
        // If your MockRepo has something like repo.updateEvent(updated)
        // repo.updateEvent(updated);
        currentEvent.value = updated;
      } catch (_) {
        currentEvent.value = updated;
      }

      // Recompute totals/derived state
      _refresh();
    }

    void _refresh() {
      final e = currentEvent.value;
      if (e == null) return;
      eventCaterings.value = repo.caterings.where((c) => c.eventId == e.id).toList();
      final relatedOrders = repo.orders.where((o) => eventCaterings.any((c) => c.id == o.cateringId)).toList();
      orders.value = relatedOrders;
      final relatedMenu = repo.menuItems.where((m) => relatedOrders.any((o) => o.id == m.orderId)).toList();
      menuItems.value = relatedMenu;

      _recalcEventTotals();
    }

    // Actions
    EventCateringModel addCatering(Category category, {String? title}) {
      final e = currentEvent.value!;
      final c = repo.createCatering(EventCateringInsert(eventId: e.id, category: category, title: title));
      _refresh();
      return c;
    }

    CateringOrderModel addOrder({
      required int cateringId,
      required PricingType pricingType,
      required PricingMode pricingMode,
      required double qty,
      required double unitPrice,
      required String currency,
      String? notes,
    }) {
      final o = repo.createOrder(CateringOrderInsert(
        cateringId: cateringId,
        pricingType: pricingType,
        pricingMode: pricingMode,
        qty: qty,
        unitPrice: unitPrice,
        currency: currency,
        notes: notes,
      ));
      _refresh();
      return o;
    }

    void deleteCatering(int cateringId) {
      // find all orders under this catering
      final orderIds = repo.orders
          .where((o) => o.cateringId == cateringId)
          .map((o) => o.id)
          .toList();

      // remove menu items for those orders
      repo.menuItems.removeWhere((m) => orderIds.contains(m.orderId));

      // remove orders
      repo.orders.removeWhere((o) => o.cateringId == cateringId);

      // remove the catering itself
      repo.caterings.removeWhere((c) => c.id == cateringId);

      _refresh();
    }

// Optional: delete a single order (handy if you add per-line delete later)
    void deleteOrder(int orderId) {
      repo.menuItems.removeWhere((m) => m.orderId == orderId);
      repo.orders.removeWhere((o) => o.id == orderId);
      _refresh();
    }

    void _recalcEventTotals() {
      final e = currentEvent.value;
      if (e == null) return;

      // all caterings under this event
      final cateringIds = repo.caterings
          .where((c) => c.eventId == e.id)
          .map((c) => c.id)
          .toSet();

      // sum up all orders qty * unitPrice
      final itemsSubtotal = repo.orders
          .where((o) => cateringIds.contains(o.cateringId))
          .fold<double>(0, (sum, o) => sum + (o.qty * o.unitPrice));

      // update event using copyWith
      currentEvent.value = e.copyWith(totalAmount: itemsSubtotal);
    }

    void addOrderMenuItem({
      required int orderId,
      required String menuItemName,
      String? size,
      double qtyPerUnit = 1,
      double? menuItemPrice,
    }) {
      repo.addMenuItem(CateringMenuItemInsert(
        orderId: orderId,
        menuItemName: menuItemName,
        size: size,
        qtyPerUnit: qtyPerUnit,
        menuItemPrice: menuItemPrice,
      ));
      _refresh();
    }

    // Helper for per-item pricing: sum menu item prices -> update order unit price
    void recomputeOrderUnitPriceFromMenuItems(int orderId) {
      final items = menuItems.where((m) => m.orderId == orderId && (m.menuItemPrice ?? 0) > 0).toList();
      final sum = items.fold<double>(0, (acc, m) => acc + (m.menuItemPrice ?? 0));
      repo.updateOrderUnitPrice(orderId, sum);
      _refresh();
    }
  }