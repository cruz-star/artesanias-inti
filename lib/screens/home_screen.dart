import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'seller_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final products = productProvider.availableProducts;

    return Scaffold(
      appBar: AppBar(
        title: Text('Artesanías Inti', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          if (auth.isClient)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          if (auth.isSeller)
            IconButton(
              icon: const Icon(Icons.dashboard),
              tooltip: 'Panel de vendedor',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerDashboard()),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') {
                auth.logout();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'info',
                enabled: false,
                child: Text(
                  auth.isSeller ? 'Vendedor' : 'Cliente',
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Salir'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay productos disponibles',
                    style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 18),
                  ),
                  if (auth.isSeller)
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SellerDashboard(),
                        ),
                      ),
                      child: const Text('Ir al panel de vendedor'),
                    ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    ),
                    trailing: auth.isClient
                        ? Builder(
                            builder: (context) {
                              final cartItem = cart.items
                                  .where((i) => i.product.id == product.id)
                                  .firstOrNull;
                              return Row(
                                children: [
                                  if (cartItem != null) ...[
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${cartItem.quantity}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_shopping_cart,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        context.read<CartProvider>().addToCart(
                                          product,
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${product.name} agregado al carrito',
                                            ),
                                            duration: const Duration(
                                              seconds: 1,
                                            ),
                                          ),
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ] else
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_shopping_cart,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        context.read<CartProvider>().addToCart(
                                          product,
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${product.name} agregado al carrito',
                                            ),
                                            duration: const Duration(
                                              seconds: 1,
                                            ),
                                          ),
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              );
                            },
                          )
                        : null,
                  );
                },
              ),
            ),
    );
  }
}
