import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/contact.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  // 🔧 CORRECTION : URL selon votre plateforme
  // Pour tests WEB (navigateur) - décommentez cette ligne :
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Pour émulateur Android - décommentez cette ligne :
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Pour appareil physique - remplacez XXX par votre IP locale :
  // static const String baseUrl = 'http://192.168.1.XXX:8000/api';
  
  // Pour iOS Simulator :
  // static const String baseUrl = 'http://localhost:8000/api';
  
  String? _token;
  User? _currentUser;
  
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;

  // Initialiser le service (charger le token depuis SharedPreferences)
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    if (_token != null) {
      try {
        await _loadCurrentUser();
      } catch (e) {
        _token = null;
        await prefs.remove('auth_token');
      }
    }
  }

  // Headers avec authentification
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }

  // Gérer les erreurs HTTP
  void _handleError(http.Response response) {
    try {
      final body = json.decode(response.body);
      final message = body['detail'] ?? 'Une erreur est survenue';
      throw Exception(message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion au serveur');
    }
  }

  // ============ AUTHENTIFICATION ============

  Future<User> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      print('🔄 Tentative d\'inscription à : $baseUrl/auth/register');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'telephone': telephone,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue : ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        _currentUser = User.fromJson(data['user']);
        
        // Sauvegarder le token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        
        print('✅ Inscription réussie pour ${_currentUser!.fullName}');
        return _currentUser!;
      } else {
        print('❌ Erreur ${response.statusCode}: ${response.body}');
        _handleError(response);
        throw Exception('Registration failed');
      }
    } on SocketException catch (e) {
      print('❌ Erreur de connexion socket : $e');
      throw Exception('Impossible de se connecter au serveur. Vérifiez que le backend est démarré.');
    } on http.ClientException catch (e) {
      print('❌ Erreur client HTTP : $e');
      throw Exception('Erreur de connexion. Vérifiez l\'URL du backend : $baseUrl');
    } catch (e) {
      print('❌ Erreur inattendue : $e');
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue');
    }
  }

  Future<User> login(String email, String password) async {
    try {
      print('🔄 Tentative de connexion à : $baseUrl/auth/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue : ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        _currentUser = User.fromJson(data['user']);
        
        // Sauvegarder le token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        
        print('✅ Connexion réussie pour ${_currentUser!.fullName}');
        return _currentUser!;
      } else {
        print('❌ Erreur ${response.statusCode}: ${response.body}');
        _handleError(response);
        throw Exception('Login failed');
      }
    } on SocketException catch (e) {
      print('❌ Erreur de connexion socket : $e');
      throw Exception('Impossible de se connecter au serveur. Vérifiez que le backend est démarré.');
    } on http.ClientException catch (e) {
      print('❌ Erreur client HTTP : $e');
      throw Exception('Erreur de connexion. Vérifiez l\'URL du backend : $baseUrl');
    } catch (e) {
      print('❌ Erreur inattendue : $e');
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue');
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> _loadCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _getHeaders(),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _currentUser = User.fromJson(data);
    } else {
      throw Exception('Failed to load user');
    }
  }

  // ============ CONTACTS ============

  Future<List<Contact>> getContacts({String? search}) async {
    try {
      var url = '$baseUrl/contacts';
      if (search != null && search.isNotEmpty) {
        url += '?search=${Uri.encodeComponent(search)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Contact.fromJson(json)).toList();
      } else {
        _handleError(response);
        throw Exception('Failed to load contacts');
      }
    } on SocketException {
      throw Exception('Impossible de se connecter au serveur');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue');
    }
  }

  Future<Contact> getContact(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contacts/$id'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Contact.fromJson(data);
      } else {
        _handleError(response);
        throw Exception('Failed to load contact');
      }
    } on SocketException {
      throw Exception('Impossible de se connecter au serveur');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue');
    }
  }

  Future<Contact> createContact(Contact contact) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contacts'),
        headers: _getHeaders(),
        body: json.encode(contact.toJson()),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Contact.fromJson(data);
      } else {
        _handleError(response);
        throw Exception('Failed to create contact');
      }
    } on SocketException {
      throw Exception('Impossible de se connecter au serveur');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue');
    }
  }

  Future<Contact> updateContact(Contact contact) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contacts/${contact.id}'),
        headers: _getHeaders(),
        body: json.encode(contact.toJson()),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Contact.fromJson(data);
      } else {
        _handleError(response);
        throw Exception('Failed to update contact');
      }
    } on SocketException {
      throw Exception('Impossible de se connecter au serveur');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue');
    }
  }

  Future<void> deleteContact(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/contacts/$id'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 204) {
        _handleError(response);
        throw Exception('Failed to delete contact');
      }
    } on SocketException {
      throw Exception('Impossible de se connecter au serveur');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue');
    }
  }

  // ============ PHOTOS ============

  Future<String?> uploadPhoto(int contactId, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/contacts/$contactId/photo'),
      );
      
      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['photo_path'];
      } else {
        _handleError(response);
        throw Exception('Failed to upload photo');
      }
    } on SocketException {
      throw Exception('Impossible de se connecter au serveur');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue lors de l\'upload');
    }
  }

  Future<void> deletePhoto(int contactId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/contacts/$contactId/photo'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 204) {
        _handleError(response);
        throw Exception('Failed to delete photo');
      }
    } on SocketException {
      throw Exception('Impossible de se connecter au serveur');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Une erreur est survenue');
    }
  }

  // URL de la photo
  String getPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return '';
    // Remplacer /api par la base URL complète
    final baseWithoutApi = baseUrl.replaceAll('/api', '');
    return '$baseWithoutApi/uploads/photos/$photoPath';
  }
}