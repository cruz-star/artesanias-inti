import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';

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
    final currencyFormat = NumberFormat.currency(
      symbol: '\$ ',
      decimalDigits: 0,
      locale: 'en_US',
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
                    currencyFormat.format(product.price),
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
    if (product.imageBytes != null && product.imageBytes!.isNotEmpty) {
      final isVideo = product.imageFileName?.toLowerCase().endsWith('.mp4') ?? false ||
                     product.imageFileName?.toLowerCase().endsWith('.mov') ?? false ||
                     product.imageFileName?.toLowerCase().endsWith('.avi') ?? false;

      if (isVideo) {
        return Container(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          width: double.infinity,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_outline, size: 48, color: colorScheme.primary),
                const SizedBox(height: 4),
                Text('Video', style: TextStyle(fontSize: 10, color: colorScheme.primary)),
              ],
            ),
          ),
        );
      }

      return Image.memory(
        product.imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    return Container(
      color: colorScheme.onSurface.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.image_outlined, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.4)),
      ),
    );
  }
}
