import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/contact.dart';
import '../services/api_service.dart';
import 'edit_contact_page.dart';

class ContactDetailPage extends StatefulWidget {
  final Contact contact;

  const ContactDetailPage({super.key, required this.contact});

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  late Contact _contact;
  final _apiService = ApiService.instance;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
  }

  Future<void> _reloadContact() async {
    if (_contact.id != null) {
      try {
        final updated = await _apiService.getContact(_contact.id!);
        if (mounted) {
          setState(() {
            _contact = updated;
          });
        }
      } catch (e) {
        // Erreur silencieuse lors du rechargement
      }
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri launchUri = Uri(scheme: 'tel', path: _contact.telephone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showError('Impossible d\'appeler ce numéro');
    }
  }

  Future<void> _sendWhatsApp() async {
    String phoneNumber = _contact.telephone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri.parse('https://wa.me/$phoneNumber');
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Impossible d\'ouvrir WhatsApp');
    }
  }

  Future<void> _sendEmail() async {
    if (_contact.email == null || _contact.email!.isEmpty) {
      _showError('Pas d\'email disponible');
      return;
    }
    final Uri launchUri = Uri(scheme: 'mailto', path: _contact.email);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showError('Impossible d\'envoyer un email');
    }
  }

  Future<void> _openMap() async {
    if (_contact.adresse == null || _contact.adresse!.isEmpty) {
      _showError('Pas d\'adresse disponible');
      return;
    }
    final query = Uri.encodeComponent(_contact.adresse!);
    final Uri launchUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showError('Impossible d\'ouvrir Maps');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final updated = _contact.copyWith(isFavorite: !_contact.isFavorite);
      await _apiService.updateContact(updated);
      setState(() {
        _contact = updated;
      });
    } catch (e) {
      _showError('Erreur lors de la mise à jour');
    }
  }

  Future<void> _deleteContact() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le contact'),
        content: Text('Voulez-vous vraiment supprimer ${_contact.fullName} ?'),
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

    if (confirm == true && mounted && _contact.id != null) {
      try {
        await _apiService.deleteContact(_contact.id!);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showError('Erreur lors de la suppression');
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF7C6FDC),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF7C6FDC),
                      const Color(0xFF7C6FDC).withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Hero(
                      tag: 'contact_${_contact.id}',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _contact.photoPath != null
                            ? ClipOval(
                                child: Image.network(
                                  _apiService.getPhotoUrl(_contact.photoPath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        _contact.initials,
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
                                  _contact.initials,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7C6FDC),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _contact.fullName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: Icon(
                        _contact.isFavorite ? Icons.star : Icons.star_border,
                        color: _contact.isFavorite ? Colors.amber : Colors.white,
                        size: 32,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditContactPage(contact: _contact),
                    ),
                  );
                  
                  if (result != null) {
                    if (result == 'deleted') {
                      Navigator.pop(context, true);
                    } else if (result is Contact) {
                      setState(() {
                        _contact = result;
                      });
                      await _reloadContact();
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteContact,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.phone,
                                label: 'Appeler',
                                onTap: _makePhoneCall,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                icon: FontAwesomeIcons.whatsapp,
                                label: 'WhatsApp',
                                onTap: _sendWhatsApp,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.email,
                                label: 'Email',
                                onTap: _sendEmail,
                                enabled: _contact.email != null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.map,
                                label: 'Maps',
                                onTap: _openMap,
                                enabled: _contact.adresse != null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoTile(
                    icon: Icons.phone,
                    label: 'Téléphone',
                    value: _contact.telephone,
                  ),

                  if (_contact.email != null && _contact.email!.isNotEmpty)
                    _buildInfoTile(
                      icon: Icons.email,
                      label: 'Email',
                      value: _contact.email!,
                    ),

                  if (_contact.adresse != null && _contact.adresse!.isNotEmpty)
                    _buildInfoTile(
                      icon: Icons.location_on,
                      label: 'Adresse',
                      value: _contact.adresse!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? const Color(0xFF7C6FDC) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: enabled ? const Color(0xFF7C6FDC) : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7C6FDC),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}