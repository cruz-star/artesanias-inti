import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../config/secrets.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    // Formato estilo Mercado Libre: $ 15.000
    final currencyFormat = NumberFormat.currency(
      symbol: '\$ ',
      decimalDigits: 0, // Sin decimales si es redondo
      locale: 'es_AR',
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildImage(colorScheme)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(product.price).replaceAll(',', '.'), // Asegurar punto para miles
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(ColorScheme colorScheme) {
    // Prioridad 1: Imagen local (recién seleccionada)
    if (product.imageBytes != null && product.imageBytes!.isNotEmpty) {
      return Image.memory(
        product.imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    
    // Prioridad 2: Imagen remota del servidor
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      final fullUrl = '${Secrets.serverUrl}/${product.imageUrl}';
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colorScheme),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
        },
      );
    }

    return _buildPlaceholder(colorScheme);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.onSurface.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.image_outlined, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.4)),
      ),
    );
  }
}
