import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class SellerContactScreen extends StatefulWidget {
  const SellerContactScreen({super.key});

  @override
  State<SellerContactScreen> createState() => _SellerContactScreenState();
}

class _SellerContactScreenState extends State<SellerContactScreen> {
  late final TextEditingController _contactoCtr;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _cbuCtrl;
  late final TextEditingController _aliasCtrl;
  late final TextEditingController _titularCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final p = context.read<ProductProvider>();
    _contactoCtr = TextEditingController(text: p.contacto);
    _emailCtrl = TextEditingController(text: p.email);
    _telefonoCtrl = TextEditingController(text: p.telefono);
    _cbuCtrl = TextEditingController(text: p.cbu);
    _aliasCtrl = TextEditingController(text: p.alias);
    _titularCtrl = TextEditingController(text: p.titular);
  }

  @override
  void dispose() {
    _contactoCtr.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _cbuCtrl.dispose();
    _aliasCtrl.dispose();
    _titularCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProductProvider>().updateContactInfo(
      contacto: _contactoCtr.text.trim(),
      email: _emailCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
    );
    context.read<ProductProvider>().updatePaymentInfo(
      cbu: _cbuCtrl.text.trim(),
      alias: _aliasCtrl.text.trim(),
      titular: _titularCtrl.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Información de contacto actualizada')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Información de Contacto'),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta información se mostrará a los clientes en los detalles del producto y al finalizar la compra.',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _contactoCtr,
                decoration: InputDecoration(
                  labelText: 'Nombre / Tienda',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.store),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!v.contains('@')) return 'Correo inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Teléfono / WhatsApp',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Datos de Pago (Transferencia)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titularCtrl,
                decoration: InputDecoration(
                  labelText: 'Titular de la Cuenta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cbuCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'CBU / CVU',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aliasCtrl,
                decoration: InputDecoration(
                  labelText: 'Alias',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Guardar cambios',
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
      ),
    );
  }
}
