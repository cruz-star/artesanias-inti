import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final productProvider = context.watch<ProductProvider>();
    final currencyFormat = NumberFormat.currency(
      symbol: '\$ ',
      decimalDigits: 0,
      locale: 'en_US',
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: colorScheme.inversePrimary,
        actions: [
          if (cart.itemCount > 0)
            TextButton(
              onPressed: () => _confirmClearCart(context),
              child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: cart.itemCount == 0
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'El carrito está vacío',
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Seguir comprando'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final product = item.product;
                      return Dismissible(
                        key: ValueKey(product.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: colorScheme.error,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => context
                            .read<CartProvider>()
                            .removeFromCart(product.id),
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(product: product),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: product.imageBytes != null
                                    ? Image.memory(
                                        product.imageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: colorScheme.onSurface.withValues(alpha: 0.1),
                                        child: Icon(
                                          Icons.image_outlined,
                                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          title: Text(product.name, maxLines: 1),
                          subtitle: Text(currencyFormat.format(product.price)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: item.quantity > 1
                                    ? () => context
                                          .read<CartProvider>()
                                          .updateQuantity(
                                            product.id,
                                            item.quantity - 1,
                                          )
                                    : null,
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () =>
                                    context.read<CartProvider>().updateQuantity(
                                      product.id,
                                      item.quantity + 1,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18)),
                          Text(
                            currencyFormat.format(cart.total),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCheckoutDialog(
                            context,
                            cart,
                            productProvider,
                          ),
                          icon: const Icon(Icons.payment),
                          label: const Text(
                            'Proceder al pago',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los productos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<CartProvider>().clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(
    BuildContext context,
    CartProvider cart,
    ProductProvider productProvider,
  ) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$ ',
      decimalDigits: 0,
      locale: 'en_US',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resumen de compra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Productos:'),
            const SizedBox(height: 8),
            ...cart.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${item.product.name} x${item.quantity} - ${currencyFormat.format(item.totalPrice)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const Divider(),
            Text(
              'Total: ${currencyFormat.format(cart.total)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text('Contacto del vendedor:'),
            const SizedBox(height: 4),
            if (productProvider.contacto.isNotEmpty)
              Text(productProvider.contacto, style: const TextStyle(fontSize: 13)),
            if (productProvider.email.isNotEmpty)
              GestureDetector(
                onTap: () => _launchEmail(context, productProvider.email),
                child: Row(
                  children: [
                    const Icon(Icons.email, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      productProvider.email,
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            if (productProvider.telefono.isNotEmpty)
              GestureDetector(
                onTap: () => _showPhoneOptions(context, productProvider.telefono),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      productProvider.telefono,
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Seguir comprando'),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡Compra realizada con éxito!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Confirmar compra'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el cliente de correo')),
        );
      }
    }
  }

  Future<void> _showPhoneOptions(BuildContext context, String phone) async {
    final number = phone.replaceAll(RegExp(r'\s+'), '');
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Llamar'),
              subtitle: Text(number),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('tel:$number');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('WhatsApp'),
              subtitle: Text(number),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('https://wa.me/$number');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
