import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:video_player/video_player.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class SellerProductForm extends StatefulWidget {
  final Product? product;

  const SellerProductForm({super.key, this.product});

  @override
  State<SellerProductForm> createState() => _SellerProductFormState();
}

class _SellerProductFormState extends State<SellerProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _categoryCtrl;
  late bool _isAvailable;

  Uint8List? _imageBytes;
  String? _imageFileName;
  VideoPlayerController? _videoController;

  bool get isEditing => widget.product != null;
  bool get isVideo => _imageFileName?.toLowerCase().endsWith('.mp4') ?? false || (_imageFileName?.toLowerCase().endsWith('.mov') ?? false);

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(2) : '',
    );
    _categoryCtrl = TextEditingController(text: p?.category ?? 'General');
    _isAvailable = p?.isAvailable ?? true;
    _imageBytes = p?.imageBytes;
    _imageFileName = p?.imageFileName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Seleccionar imagen'),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Seleccionar video'),
              onTap: () => Navigator.pop(ctx, 'video'),
            ),
          ],
        ),
      ),
    );
    if (type == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: type == 'video' 
          ? ['mp4', 'mov', 'avi', 'mkv', 'webm'] 
          : ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Limpiar anterior controlador si existe
        await _videoController?.dispose();
        _videoController = null;

        if (type == 'video' && file.path != null) {
          _videoController = VideoPlayerController.file(File(file.path!))
            ..initialize().then((_) {
              setState(() {});
              _videoController?.play();
              _videoController?.setLooping(true);
            });
        }

        setState(() {
          _imageBytes = file.bytes;
          _imageFileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivo: $e')),
        );
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final category = _categoryCtrl.text.trim();

    final provider = context.read<ProductProvider>();

    if (isEditing) {
      final updated = widget.product!.copyWith(
        name: name,
        description: description,
        price: price,
        imageBytes: _imageBytes,
        imageFileName: _imageFileName,
        category: category,
        isAvailable: _isAvailable,
      );
      provider.updateProduct(updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto actualizado')));
    } else {
      final newProduct = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        description: description,
        price: price,
        imageBytes: _imageBytes,
        imageFileName: _imageFileName,
        category: category,
        isAvailable: _isAvailable,
      );
      provider.addProduct(newProduct);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Producto agregado')));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickMedia,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.2)),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: isVideo && _videoController != null && _videoController!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                )
                              : Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isVideo ? Icons.videocam_outlined : Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isVideo ? 'Video seleccionado' : 'Tocar para agregar imagen o video',
                              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                            if (_imageFileName != null)
                              Text(
                                _imageFileName!,
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 64),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Precio (\$)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Ingrese un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Disponible'),
                subtitle: Text(
                  _isAvailable
                      ? 'Visible para clientes'
                      : 'Oculto para clientes',
                ),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
                secondary: Icon(
                  _isAvailable ? Icons.visibility : Icons.visibility_off,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(
                    isEditing ? 'Guardar cambios' : 'Agregar producto',
                    style: const TextStyle(fontSize: 16),
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
      ),
    );
  }
}
