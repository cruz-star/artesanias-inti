import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import 'seller_product_form.dart';
import 'seller_contact_screen.dart';
import '../config/secrets.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  double _downloadProgress = 0;
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final currencyFormat = NumberFormat.currency(
      symbol: '\$ ',
      decimalDigits: 0,
      locale: 'es_AR',
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF2E9),
      appBar: AppBar(
        title: const Text(
          'Inventario',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: productProvider.isPublishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFD35400),
                    ),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Publicar a la Web',
            onPressed: productProvider.isPublishing
                ? null
                : () async {
                    final auth = context.read<AuthProvider>();
                    final success = await productProvider.publishToWeb(token: auth.token);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '¡Tienda web actualizada!'
                                : 'Error al actualizar web',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isDownloading)
            LinearProgressIndicator(value: _downloadProgress),
          if (productProvider.newVersionAvailable != null && !_isDownloading)
            _buildUpdateBanner(productProvider),
          Expanded(
            child: productProvider.products.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    itemCount: productProvider.products.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final product = productProvider.products[index];
                      return _buildProductCard(product, currencyFormat, colorScheme);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SellerProductForm()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
        backgroundColor: const Color(0xFFD35400),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildUpdateBanner(ProductProvider provider) {
    return Container(
      color: Colors.orange.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Versión ${provider.newVersionAvailable} lista',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => _downloadAndInstall(provider.updateUrl),
            child: const Text('ACTUALIZAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Aún no tienes productos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('Toca el botón amarillo para empezar', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProductCard(product, NumberFormat format, ColorScheme colorScheme) {
    final isVideo = product.imageFileName?.toLowerCase().endsWith('.mp4') ?? false;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SellerProductForm(product: product)),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: product.imageBytes != null
                          ? Image.memory(product.imageBytes!, fit: BoxFit.cover)
                          : (product.imageUrl != null
                              ? Image.network(
                                  '${Secrets.serverUrl}/${product.imageUrl}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined)),
                                )
                              : Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined))),
                    ),
                  ),
                  if (isVideo)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      format.format(product.price).replaceAll(',', '.'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category} • ${product.isAvailable ? 'Publicado' : 'Pausado'}',
                      style: TextStyle(fontSize: 12, color: product.isAvailable ? Colors.green : Colors.orange),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                onPressed: () => _confirmDelete(context, product),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _downloadAndInstall(String? url) async {
    if (url == null) return;
    
    // 1. Solicitar permisos de instalación
    final status = await Permission.requestInstallPackages.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se requiere permiso para instalar la actualización')),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      // 2. Descargar el APK
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/update.apk';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // 3. Instalar
        await OpenFilex.open(filePath, type: 'application/vnd.android.package-archive');
      } else {
        throw Exception('Fallo al descargar: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _confirmDelete(BuildContext context, product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(product.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
