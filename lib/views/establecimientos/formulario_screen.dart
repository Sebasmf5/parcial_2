import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:parcial_2/models/establecimiento.dart';
import 'package:parcial_2/services/establecimiento_service.dart';

/// Formulario para crear o editar un Establecimiento.
///
/// Si [establecimientoId] es null → modo creación.
/// Si [establecimientoId] tiene valor → modo edición (precarga datos).
class FormularioScreen extends StatefulWidget {
  final int? establecimientoId;

  const FormularioScreen({super.key, this.establecimientoId});

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = EstablecimientoService();
  final _picker = ImagePicker();

  final _nombreCtrl = TextEditingController();
  final _nitCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  bool _isLoadingData = false;

  bool get _isEditing => widget.establecimientoId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadEstablecimiento();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nitCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEstablecimiento() async {
    setState(() => _isLoadingData = true);
    try {
      final est = await _service.getById(widget.establecimientoId!);
      if (!mounted) return;
      _nombreCtrl.text = est.nombre;
      _nitCtrl.text = est.nit;
      _direccionCtrl.text = est.direccion;
      _telefonoCtrl.text = est.telefono;
      setState(() => _isLoadingData = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingData = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Seleccionar imagen',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF6C63FF)),
                title: const Text('Cámara', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF6C63FF)),
                title: const Text('Galería', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final est = Establecimiento(
        nombre: _nombreCtrl.text.trim(),
        nit: _nitCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
      );

      if (_isEditing) {
        await _service.update(widget.establecimientoId!, est, logoFile: _selectedImage);
      } else {
        await _service.create(est, logoFile: _selectedImage);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Establecimiento actualizado' : 'Establecimiento creado'),
          backgroundColor: const Color(0xFF43E97B),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Establecimiento' : 'Nuevo Establecimiento',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Selector de imagen
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.file(_selectedImage!, fit: BoxFit.contain),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded,
                                      size: 48, color: Colors.grey[500]),
                                  const SizedBox(height: 8),
                                  Text('Seleccionar logo',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(_nombreCtrl, 'Nombre', Icons.store_rounded),
                    const SizedBox(height: 16),
                    _buildTextField(_nitCtrl, 'NIT', Icons.badge_rounded),
                    const SizedBox(height: 16),
                    _buildTextField(_direccionCtrl, 'Dirección', Icons.location_on_rounded),
                    const SizedBox(height: 16),
                    _buildTextField(_telefonoCtrl, 'Teléfono', Icons.phone_rounded,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        disabledBackgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isEditing ? 'Actualizar' : 'Crear',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El campo $label es obligatorio';
        }
        return null;
      },
    );
  }
}
