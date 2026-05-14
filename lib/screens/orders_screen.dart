import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import 'order_details_screen.dart';
import '../providers/auth_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<OrderProvider>().fetchOrders(token: auth.token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_AR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos de Clientes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final auth = context.read<AuthProvider>();
              orderProvider.fetchOrders(token: auth.token);
            },
          ),
        ],
      ),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderProvider.orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () {
                    final auth = context.read<AuthProvider>();
                    return orderProvider.fetchOrders(token: auth.token);
                  },
                  child: ListView.builder(
                    itemCount: orderProvider.orders.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final order = orderProvider.orders[index];
                      return _buildOrderCard(context, order, currencyFormat);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Aún no tienes pedidos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Aparecerán aquí cuando un cliente compre', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, order, NumberFormat format) {
    Color statusColor;
    String statusText;
    switch (order.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        break;
      case 'shipped':
        statusColor = Colors.blue;
        statusText = 'Enviado';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Completado';
        break;
      default:
        statusColor = Colors.grey;
        statusText = order.status;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
        ),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pedido #${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('Cliente: ${order.customerName}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
            Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(format.format(order.totalAmount).replaceAll(',', '.'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFD35400))),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
