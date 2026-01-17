import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/contact.dart';
import '../services/api_service.dart';

class EditContactPage extends StatefulWidget {
  final Contact contact;

  const EditContactPage({super.key, required this.contact});

  @override
  State<EditContactPage> createState() => _EditContactPageState();
}

class _EditContactPageState extends State<EditContactPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;
  late TextEditingController _adresseController;
  
  final _apiService = ApiService.instance;
  final _imagePicker = ImagePicker();
  
  String? _currentPhotoPath;
  File? _newSelectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.contact.nom);
    _prenomController = TextEditingController(text: widget.contact.prenom);
    _telephoneController = TextEditingController(text: widget.contact.telephone);
    _emailController = TextEditingController(text: widget.contact.email ?? '');
    _adresseController = TextEditingController(text: widget.contact.adresse ?? '');
    _currentPhotoPath = widget.contact.photoPath;
  }

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
          _newSelectedImage = File(image.path);
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
            if (_currentPhotoPath != null || _newSelectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer la photo'),
                onTap: () async {
                  Navigator.pop(context);
                  if (widget.contact.id != null && _currentPhotoPath != null) {
                    try {
                      await _apiService.deletePhoto(widget.contact.id!);
                    } catch (e) {
                      _showError('Erreur lors de la suppression');
                    }
                  }
                  setState(() {
                    _currentPhotoPath = null;
                    _newSelectedImage = null;
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

  Future<void> _updateContact() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final updated = widget.contact.copyWith(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          telephone: _telephoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          adresse: _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
        );

        final savedContact = await _apiService.updateContact(updated);

        // Upload nouvelle photo si sélectionnée
        if (_newSelectedImage != null && savedContact.id != null) {
          await _apiService.uploadPhoto(savedContact.id!, _newSelectedImage!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact modifié avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pop(context, savedContact);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _deleteContact() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le contact'),
        content: Text('Voulez-vous vraiment supprimer ${widget.contact.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted && widget.contact.id != null) {
      try {
        await _apiService.deleteContact(widget.contact.id!);
        if (mounted) {
          Navigator.pop(context, 'deleted');
        }
      } catch (e) {
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
        title: const Text('Modifier le contact'),
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
                  child: _newSelectedImage != null
                      ? ClipOval(
                          child: Image.file(
                            _newSelectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _currentPhotoPath != null
                          ? ClipOval(
                              child: Image.network(
                                _apiService.getPhotoUrl(_currentPhotoPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      widget.contact.initials,
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C6FDC),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                widget.contact.initials,
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7C6FDC),
                                ),
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Modifier la photo',
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
                  onPressed: _isLoading ? null : _updateContact,
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
                          'SAUVEGARDER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: _deleteContact,
                  icon: const Icon(Icons.delete),
                  label: const Text('SUPPRIMER LE CONTACT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
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