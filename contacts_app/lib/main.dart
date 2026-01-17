import 'package:flutter/material.dart';
import 'pages/login.dart';
import 'pages/signup.dart';
import 'pages/contacts_list.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser l'API service
  await ApiService.instance.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion de Contacts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      // Si l'utilisateur est déjà connecté, aller directement à la liste
      home: ApiService.instance.isAuthenticated 
          ? const ContactsListPage() 
          : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/contacts_list': (context) => const ContactsListPage(),
      },
    );
  }
}