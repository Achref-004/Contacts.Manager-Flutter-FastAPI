import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/contact.dart';
import '../services/api_service.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  
  final _apiService = ApiService.instance;
  final _imagePicker = ImagePicker();
  
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection de l\'image');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer la photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName requis';
    }
    if (value.length < 2) {
      return '$fieldName trop court';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Téléphone requis';
    }
    if (value.length < 8) {
      return 'Numéro invalide';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  void _formatPhone() {
    String text = _telephoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length >= 8) {
      text = '${text.substring(0, 2)} ${text.substring(2, 5)} ${text.substring(5)}';
    }
    _telephoneController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _saveContact() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final contact = Contact(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          telephone: _telephoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
          isFavorite: false,
        );

        final createdContact = await _apiService.createContact(contact);

        // Upload photo si sélectionnée
        if (_selectedImage != null && createdContact.id != null) {
          await _apiService.uploadPhoto(createdContact.id!, _selectedImage!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact ajouté avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nouveau contact'),
        backgroundColor: const Color(0xFF7C6FDC),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF3F2FF),
                    border: Border.all(color: const Color(0xFF7C6FDC), width: 2),
                  ),
                  child: _selectedImage != null
                      ? ClipOval(
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: Color(0xFF7C6FDC),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajouter une photo',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                controller: _prenomController,
                label: 'Prénom *',
                icon: Icons.person_outline,
                validator: (value) => _validateName(value, 'Prénom'),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _nomController,
                label: 'Nom *',
                icon: Icons.person_outline,
                validator: (value) => _validateName(value, 'Nom'),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _telephoneController,
                label: 'Téléphone *',
                icon: Icons.phone_outlined,
                validator: _validatePhone,
                keyboardType: TextInputType.phone,
                onChanged: (_) => _formatPhone(),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                validator: _validateEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _adresseController,
                label: 'Adresse',
                icon: Icons.location_on_outlined,
                keyboardType: TextInputType.streetAddress,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6FDC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'ENREGISTRER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF7C6FDC)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}