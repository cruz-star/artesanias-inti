import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _isVideo = widget.product.imageFileName?.toLowerCase().endsWith('.mp4') ?? false ||
              widget.product.imageFileName?.toLowerCase().endsWith('.mov') ?? false;
    
    if (_isVideo && widget.product.imageBytes != null) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${widget.product.imageFileName}');
      await tempFile.writeAsBytes(widget.product.imageBytes!);
      
      _videoController = VideoPlayerController.file(tempFile)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
          _videoController?.setLooping(true);
        });
    } catch (e) {
      print('Error al inicializar video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$ ',
      decimalDigits: 0,
      locale: 'en_US',
    );
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Producto'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMedia(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(widget.product.price),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(widget.product.category),
                    backgroundColor: colorScheme.secondaryContainer,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Descripción',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description.isNotEmpty
                        ? widget.product.description
                        : 'Sin descripción disponible.',
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (productProvider.contacto.isNotEmpty ||
                      productProvider.email.isNotEmpty ||
                      productProvider.telefono.isNotEmpty) ...[
                    const Text(
                      'Contacto del vendedor',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (productProvider.contacto.isNotEmpty)
                      _contactRow(context, Icons.store, productProvider.contacto, null),
                    if (productProvider.email.isNotEmpty)
                      _contactRow(context, Icons.email, productProvider.email, () => _launchEmail(context, productProvider.email)),
                    if (productProvider.telefono.isNotEmpty)
                      _contactRow(context, Icons.phone, productProvider.telefono, () => _showPhoneOptions(context, productProvider.telefono)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: auth.isClient
          ? Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<CartProvider>().addToCart(widget.product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.product.name} agregado al carrito'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(
                  'Agregar al carrito - ${currencyFormat.format(widget.product.price)}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMedia(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (widget.product.imageBytes != null && widget.product.imageBytes!.isNotEmpty) {
      if (_isVideo) {
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Container(
            height: 300,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        } else {
          return Container(
            height: 300,
            width: double.infinity,
            color: cs.onSurface.withValues(alpha: 0.1),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
      }
      return SizedBox(
        height: 300,
        width: double.infinity,
        child: Image.memory(widget.product.imageBytes!, fit: BoxFit.cover),
      );
    }
    return Container(
      height: 300,
      width: double.infinity,
      color: cs.onSurface.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.image_outlined, size: 80, color: cs.onSurface.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _contactRow(BuildContext context, IconData icon, String text, VoidCallback? onTap) {
    final cs = Theme.of(context).colorScheme;
    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
    if (onTap == null) return tile;
    return GestureDetector(onTap: onTap, child: tile);
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
