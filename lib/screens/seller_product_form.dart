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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar publicación' : 'Nueva publicación',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fotos y videos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickMedia,
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              isVideo && _videoController != null && _videoController!.value.isInitialized
                                  ? AspectRatio(
                                      aspectRatio: _videoController!.value.aspectRatio,
                                      child: VideoPlayer(_videoController!),
                                    )
                                  : Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                                ),
                              ),
                              if (isVideo)
                                const Icon(Icons.play_circle_fill, color: Colors.white70, size: 64),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            const Text('Agregar imagen o video', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Información básica'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameCtrl,
                label: 'Título de la publicación',
                hint: 'Ej: Vasija de barro pintada',
                icon: Icons.title,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descCtrl,
                label: 'Descripción del producto',
                hint: 'Cuéntales a tus clientes sobre tu producto...',
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Precio y Categoría'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceCtrl,
                      label: 'Precio (\$)',
                      hint: '0',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        final parsed = double.tryParse(v.trim());
                        if (parsed == null || parsed <= 0) return 'Precio inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _categoryCtrl,
                      label: 'Categoría',
                      hint: 'Ej: Cerámica',
                      icon: Icons.category_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: SwitchListTile(
                  title: const Text('Producto disponible', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Los clientes podrán verlo en la web'),
                  activeColor: const Color(0xFFD35400),
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD35400),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing ? 'Guardar cambios' : 'Publicar producto',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD35400))),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }
}
