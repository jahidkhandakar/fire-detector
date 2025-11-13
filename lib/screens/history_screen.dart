import 'package:fire_alarm/others/widgets/time_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/modules/orders/order_controller.dart';
import '/modules/orders/order_model.dart';
import '/modules/users/user_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final OrderController _orderCtrl;
  late final UserController _userCtrl;

  // 0 = All, 1 = Paid
  int _filterIndex = 1; // default Paid

  @override
  void initState() {
    super.initState();
    // Reuse if already created; otherwise put
    _orderCtrl =
        Get.isRegistered<OrderController>()
            ? Get.find<OrderController>()
            : Get.put(OrderController(), permanent: true);

    _userCtrl =
        Get.isRegistered<UserController>()
            ? Get.find<UserController>()
            : Get.put(UserController(), permanent: true);

    // Load AFTER first frame to avoid Obx mutation during build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = _userCtrl.getStoredUserId();
      if (userId != null) {
        await _orderCtrl.loadOrders(userId: userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (_orderCtrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_orderCtrl.error.value.isNotEmpty) {
          return Center(child: Text(_orderCtrl.error.value));
        }

        final List<OrderModel> source = _orderCtrl.orders;
        final List<OrderModel> items =
            _filterIndex == 1
                ? source.where((o) => o.orderStatus == 'paid').toList()
                : source;

        if (items.isEmpty) {
          return _emptyState(
            title: _filterIndex == 1 ? 'No paid history yet' : 'No orders yet',
            subtitle:
                _filterIndex == 1
                    ? 'Your successful payments will appear here.'
                    : 'Create an order to see it here.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final userId = _userCtrl.getStoredUserId();
            if (userId != null) {
              debugPrint('↻ Refreshing history for user=$userId');
              await _orderCtrl.loadOrders(userId: userId);
            }
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _HistoryTile(order: items[index]),
          ),
        );
      }),

      // Filter toggler at bottom
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('All')),
              ButtonSegment(value: 1, label: Text('Paid')),
            ],
            selected: {_filterIndex},
            onSelectionChanged: (s) => setState(() => _filterIndex = s.first),
            showSelectedIcon: false,
          ),
        ),
      ),
    );
  }

  //*___________________ Empty State Widget ____________________*//
  Widget _emptyState({required String title, required String subtitle}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _filterIndex == 1
                    ? Icons.receipt_long
                    : Icons.shopping_bag_outlined,
                color: Colors.deepOrange,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _HistoryTile extends StatelessWidget {
  final OrderModel order;

  const _HistoryTile({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isPaid = order.orderStatus?.toLowerCase() == 'paid';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Icon(
          isPaid ? Icons.check_circle : Icons.pending_actions,
          color: isPaid ? Colors.green : Colors.orange,
          size: 30,
        ),
        title: Text(
          'Order #${order.reference}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isPaid ? Colors.green : Colors.orange,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '৳${order.amount} ${order.currency} • ${order.orderStatus.toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            TimeField(
              label: 'Ordered',
              raw: order.orderedAt.toIso8601String(), // or API string
              icon: Icons.schedule,
              localeTag: 'en_US',
              fallback: '—',
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
