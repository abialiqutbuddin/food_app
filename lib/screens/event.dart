import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import '../../models/enums.dart';
import '../state/controllers/event.dart';
import '../widgets/category_picker.dart';
import '../widgets/textfield.dart';
import 'forms/bbq.dart';
import 'forms/buffet.dart';
import 'forms/thaal.dart';
import 'forms/thaali.dart';
import 'forms/tray.dart';
import 'layout.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});
  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final c = Get.find<EventController>();

  // extra charges (UI-only for now; wire to backend later)
  final deliveryCtrl = TextEditingController();
  final serviceCtrl  = TextEditingController();
  final notesCtrl    = TextEditingController();

  @override
  void dispose() {
    deliveryCtrl.dispose();
    serviceCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCatering() async {
    final cat = await showCategoryPicker(context);
    if (cat == null) return;
    final created = c.addCatering(cat);
    await showCateringDialog(context, category: cat, cateringId: created.id);
    setState(() {}); // refresh
  }

  Future<void> _editCatering(int cateringId, Category category) async {
    await showCateringDialog(context, category: category, cateringId: cateringId);
    setState(() {}); // refresh
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final e = c.currentEvent.value;
      if (e == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final left = _LeftColumn(
        onAddCatering: _addCatering,
        onEditCatering: _editCatering,
      );

      final right = _CheckoutSummary(
        deliveryCtrl: deliveryCtrl,
        serviceCtrl: serviceCtrl,
        notesCtrl: notesCtrl,
      );

      return WebShell(
        header: const Text('Catering Checkout'),
        left: left,
        right: right,
      );
    });
  }
}

/// LEFT: Event details + quick list of catering blocks (edit via dialog)
class _LeftColumn extends StatelessWidget {
  final Future<void> Function() onAddCatering;
  final Future<void> Function(int cateringId, Category category) onEditCatering;

  const _LeftColumn({
    required this.onAddCatering,
    required this.onEditCatering,
  });

  @override
  Widget build(BuildContext context) {
    final c = Get.find<EventController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event / Customer details (like shipping block)
        EventDetailsForm(),
        const SizedBox(height: 12),

        // Actions + items subtotal preview
        Row(
          children: [
            FilledButton.icon(
              onPressed: onAddCatering,
              icon: const Icon(Icons.add),
              label: const Text('Add Catering'),
            ),
            const SizedBox(width: 12),
            Obx(() {
              final itemsSubtotal = c.currentEvent.value?.totalAmount ?? 0;
              return Text('Items Subtotal: ${_money(itemsSubtotal)}',
                  style: Theme.of(context).textTheme.titleMedium);
            }),
          ],
        ),
        const SizedBox(height: 12),

        // Compact list of caterings (like sections in a cart)
        Obx(() {
          final list = c.eventCaterings;
          if (list.isEmpty) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No catering added yet. Click "Add Catering" to start.'),
              ),
            );
          }

          return Column(
            children: list.map((cat) {
              final catEnum = Category.values.firstWhere(
                    (x) => x.label == cat.category,
                orElse: () => Category.buffet,
              );
              final catOrders = c.orders.where((o) => o.cateringId == cat.id).toList();
              final subtotal = catOrders.fold<double>(0, (s, o) => s + o.subtotal);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(cat.category),
                  subtitle: Text('${catOrders.length} entries • Subtotal: ${_money(subtotal)}'),
                  trailing: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onEditCatering(cat.id, catEnum),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error),
                      ),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete catering?'),
                            content: Text(
                              'This will remove "${cat.category}" and all its entries for this event.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                                ),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          Get.find<EventController>().deleteCatering(cat.id);
                          toastification.show(
                           // context: context,
                            title: const Text('Success'),
                            description: Text('Deleted ${cat.category}'),
                            type: ToastificationType.success,
                            style: ToastificationStyle.fillColored,
                            alignment: Alignment.topRight,
                            autoCloseDuration: const Duration(seconds: 4),
                            dragToClose: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            borderRadius: BorderRadius.circular(12),
                          );
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(content: Text('Deleted ${cat.category}')),
                          // );
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
                ),
              );
            }).toList(),
          );
        }),

        const SizedBox(height: 80),
      ],
    );
  }
}

/// RIGHT: Cart-like summary with charges and grand total
class _CheckoutSummary extends StatefulWidget {
  final TextEditingController deliveryCtrl;
  final TextEditingController serviceCtrl;
  final TextEditingController notesCtrl;

  const _CheckoutSummary({
    required this.deliveryCtrl,
    required this.serviceCtrl,
    required this.notesCtrl,
  });

  @override
  State<_CheckoutSummary> createState() => _CheckoutSummaryState();
}

class _CheckoutSummaryState extends State<_CheckoutSummary> {
  @override
  Widget build(BuildContext context) {
    final c = Get.find<EventController>();

    return Obx(() {
      final cats = c.eventCaterings;
      final orders = c.orders;
      final itemsSubtotal = c.currentEvent.value?.totalAmount ?? 0;

      final delivery = double.tryParse(widget.deliveryCtrl.text) ?? 0;
      final service  = double.tryParse(widget.serviceCtrl.text) ?? 0;
      final grand    = itemsSubtotal + delivery + service;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header + place order
          Row(
            children: [
              Text('Order Summary', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  // submit to API here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order submitted (demo)')),
                  );
                },
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('Place Order'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // grouped line items
          if (cats.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No entries yet.'),
              ),
            )
          else
            Column(
              children: cats.map((cat) {
                final catOrders = orders.where((o) => o.cateringId == cat.id).toList();
                if (catOrders.isEmpty) return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.category, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...catOrders.map((o) {
                          final items = c.itemsForOrder(o.id);

                          // Thaali: size is an attribute of the order, not each item.
                          // Party Tray: if items have size, show once alongside the line.
                          String orderSizeLabel = '';
                          if (o.pricingTypeCode == 'per_size') {
                            orderSizeLabel = ' • (Size)';
                            // If you store size at order-level later, replace above with the actual size.
                          } else if (items.isNotEmpty && (items.first.size != null && items.first.size!.isNotEmpty)) {
                            orderSizeLabel = ' • ${items.first.size}';
                          }

                          final qtyStr   = _qty(o.qty);
                          final unitStr  = _money(o.unitPrice);
                          final lineStr  = '$qtyStr × $unitStr$orderSizeLabel';
                          final itemsStr = items.isEmpty
                              ? '—'
                              : items.map((m) => m.menuItemName).join(', ');

                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(lineStr),
                            subtitle: Text(itemsStr),
                            trailing: Text(_money(o.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          // charges + note + totals
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _totalRow('Items Subtotal', itemsSubtotal),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: RoundedTextField(
                          controller: widget.deliveryCtrl,
                          label: 'Delivery charges',
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}), // keep totals live
                        )
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RoundedTextField(
                          controller: widget.serviceCtrl,
                          label: 'Service charges',
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RoundedTextField(
                    controller: widget.notesCtrl,
                    label: 'Order Notes (optional)',
                    hint: 'Order Notes',
                    maxLines: 2,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const Divider(height: 20),
                  _totalRow('Grand Total', grand, isBold: true),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _totalRow(String label, double amount, {bool isBold = false}) {
    final style = TextStyle(fontWeight: isBold ? FontWeight.w700 : FontWeight.w500);
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(_money(amount), style: style),
      ],
    );
  }

  String _qty(double q) {
    // avoid .0 for integers
    return (q == q.roundToDouble()) ? q.toStringAsFixed(0) : q.toStringAsFixed(2);
    // ex: 3 or 3.50
  }
}

// =========================
// C A T E R I N G  D I A L O G
// =========================

Future<void> showCateringDialog(
    BuildContext context, {
      required Category category,
      required int cateringId,
    }) async {

  Widget formByCategory() {
    switch (category) {
      case Category.thaal:
        return ThaalForm(cateringId: cateringId);
      case Category.thaali:
        return ThaaliForm(cateringId: cateringId);
      case Category.partyTray:
        return TrayForm(cateringId: cateringId);
      case Category.liveBbq:
        return BbqForm(cateringId: cateringId);
      case Category.buffet:
        return BuffetForm(cateringId: cateringId);
    }
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final isWide = MediaQuery.of(ctx).size.width > 900;
      final dialogWidth = isWide ? 760.0 : MediaQuery.of(ctx).size.width * 0.95;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: MediaQuery.of(ctx).size.height * 0.9,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add ${category.label}',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                formByCategory(),
              ],
            )),
          ),

          ),
      );
    },
  );
}

// =========================
// U T I L S
// =========================

String _money(double v) => v.toStringAsFixed(2);

class EventDetailsForm extends StatefulWidget {
  const EventDetailsForm({super.key});

  @override
  State<EventDetailsForm> createState() => _EventDetailsFormState();
}

class _EventDetailsFormState extends State<EventDetailsForm> {
  final c = Get.find<EventController>();

  late final TextEditingController nameCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController venueCtrl;

  @override
  void initState() {
    super.initState();
    final e = c.currentEvent.value!;
    nameCtrl  = TextEditingController(text: e.customerName);
    phoneCtrl = TextEditingController(text: e.customerPhone ?? '');
    emailCtrl = TextEditingController(text: e.customerEmail ?? '');
    venueCtrl = TextEditingController(text: e.venue ?? '');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    venueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final e = c.currentEvent.value!;
    final ctx = context;

    final date = await showDatePicker(
      context: ctx,
      initialDate: e.eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(e.eventDate),
    );
    if (time == null) {
      c.updateEventDate(DateTime(date.year, date.month, date.day, e.eventDate.hour, e.eventDate.minute));
      return;
    }

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    c.updateEventDate(dt);
    setState(() {}); // refresh button label
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final e = c.currentEvent.value!;
      final dateLabel = '${e.eventDate.toLocal()}'.split('.').first;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event Details', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              LayoutBuilder(builder: (context, cns) {
                final isWide = cns.maxWidth > 700;
                Widget col(Widget w) => isWide ? Expanded(child: w) : w;
                final rowGap = isWide ? const SizedBox(width: 12) : const SizedBox(height: 12);

                return Column(
                  children: [
                    isWide
                        ? Row(
                      children: [
                        col(RoundedTextField(
                          controller: nameCtrl,
                          label: 'Customer Name',
                          hint: 'Enter Name',
                          prefixIcon: const Icon(Icons.person),
                          onChanged: c.updateCustomerName,
                        )),
                        rowGap,
                        col(RoundedTextField(
                          controller: phoneCtrl,
                          label: 'Phone',
                          hint: '03xx-xxxxxxx',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone),
                          onChanged: c.updateCustomerPhone,
                        )),
                      ],
                    )
                        : Column(
                      children: [
                        RoundedTextField(
                          controller: nameCtrl,
                          label: 'Customer Name',
                          hint: 'Enter Name',
                          prefixIcon: const Icon(Icons.person),
                          onChanged: c.updateCustomerName,
                        ),
                        rowGap,
                        RoundedTextField(
                          controller: phoneCtrl,
                          label: 'Phone',
                          hint: '03xx-xxxxxxx',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone),
                          onChanged: c.updateCustomerPhone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    isWide
                        ? Row(
                      children: [
                        col(RoundedTextField(
                          controller: emailCtrl,
                          label: 'Email',
                          hint: 'Enter Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email),
                          onChanged: c.updateCustomerEmail,
                        )),
                        rowGap,
                        col(RoundedTextField(
                          controller: venueCtrl,
                          label: 'Venue / Address',
                          hint: 'Banquet Hall, Street...',
                          prefixIcon: const Icon(Icons.place),
                          onChanged: c.updateVenue,
                        )),
                      ],
                    )
                        : Column(
                      children: [
                        RoundedTextField(
                          controller: emailCtrl,
                          label: 'Email',
                          hint: 'Enter Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email),
                          onChanged: c.updateCustomerEmail,
                        ),
                        rowGap,
                        RoundedTextField(
                          controller: venueCtrl,
                          label: 'Venue / Address',
                          hint: 'Banquet Hall, Street...',
                          prefixIcon: const Icon(Icons.place),
                          onChanged: c.updateVenue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event),
                        label: Text('Event: $dateLabel'),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: _pickDateTime,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    });
  }
}