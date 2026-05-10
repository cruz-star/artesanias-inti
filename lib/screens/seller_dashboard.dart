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
import 'seller_product_form.dart';
import 'seller_contact_screen.dart';

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
      locale: 'en_US',
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Vendedor'),
        backgroundColor: colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: productProvider.isPublishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload),
            tooltip: 'Publicar cambios en la Web',
            onPressed: productProvider.isPublishing
                ? null
                : () async {
                    final success = await productProvider.publishToWeb();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '¡Publicado con éxito!'
                                : 'Error al publicar',
                          ),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.contact_mail),
            tooltip: 'Información de contacto',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SellerContactScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isDownloading)
            LinearProgressIndicator(value: _downloadProgress),
          if (productProvider.newVersionAvailable != null && !_isDownloading)
            MaterialBanner(
              content: Text(
                'Nueva versión disponible (${productProvider.newVersionAvailable})',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange.shade800,
              leading: const Icon(Icons.update, color: Colors.white),
              actions: [
                TextButton(
                  onPressed: () => _downloadAndInstall(productProvider.updateUrl),
                  child: const Text('ACTUALIZAR AHORA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  '${productProvider.products.length} productos',
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Text(
                  'Contacto: ${productProvider.contacto}',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Expanded(
            child: productProvider.products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay productos',
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega tu primer producto',
                          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: productProvider.products.length,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (context, index) {
                      final product = productProvider.products[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 60,
                              height: 60,
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
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currencyFormat.format(product.price),
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    product.category,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: product.isAvailable
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      product.isAvailable
                                          ? 'Disponible'
                                          : 'No disponible',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: product.isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SellerProductForm(product: product),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, product),
                              ),
                            ],
                          ),
                        ),
                      );
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
        label: const Text('Agregar producto'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
      // Nota: Para progreso real se necesitaría una implementación más compleja con http.Client
      // Para este ejemplo usaremos un stream básico o simplemente el download directo
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
