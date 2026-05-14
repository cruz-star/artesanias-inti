import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$ ', decimalDigits: 0, locale: 'es_AR');
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Pedido'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Datos del Cliente'),
            _buildInfoCard([
              _buildInfoRow(Icons.person_outline, 'Nombre', order.customerName),
              _buildInfoRow(Icons.phone_outlined, 'Teléfono', order.customerPhone, onTap: () => _launchWhatsApp(order.customerPhone)),
              _buildInfoRow(Icons.email_outlined, 'Email', order.customerEmail),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('Ubicación de Envío'),
            _buildInfoCard([
              _buildInfoRow(Icons.location_on_outlined, 'Dirección', order.shippingAddress),
              _buildInfoRow(Icons.location_city_outlined, 'Ciudad', order.shippingCity),
              _buildInfoRow(Icons.local_post_office_outlined, 'Código Postal', order.shippingZip),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('Productos'),
            _buildInfoCard(
              order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text('${item.quantity}x', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(currencyFormat.format(item.price).replaceAll(',', '.'), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text(currencyFormat.format(item.price * item.quantity).replaceAll(',', '.'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total del Pedido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  currencyFormat.format(order.totalAmount).replaceAll(',', '.'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildStatusButtons(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
            if (onTap != null) ...[
              const Spacer(),
              const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButtons(BuildContext context) {
    if (order.status == 'completed') return const Center(child: Text('Pedido Completado', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)));

    return Column(
      children: [
        if (order.status == 'pending')
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                context.read<OrderProvider>().updateOrderStatus(order.id, 'shipped', token: auth.token);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text('Marcar como Enviado'),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              final auth = context.read<AuthProvider>();
              context.read<OrderProvider>().updateOrderStatus(order.id, 'completed', token: auth.token);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Completar Pedido'),
          ),
        ),
      ],
    );
  }

  Future<void> _launchWhatsApp(String phone) async {
    final number = phone.replaceAll(RegExp(r'\s+'), '').replaceAll('+', '');
    final url = 'https://wa.me/$number';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
