import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService.instance;
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe requis';
    }
    if (value.length < 6) {
      return 'Minimum 6 caractères';
    }
    return null;
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = await _apiService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Bienvenue ${user.fullName} !'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.pushReplacementNamed(context, '/contacts_list');
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(e.toString().replaceAll('Exception: ', '')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C6FDC).withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C6FDC).withOpacity(0.2),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        Container(
                          height: 350,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Image.asset(
                            'assets/login_img.webp',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F2FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  size: 100,
                                  color: Color(0xFF7C6FDC),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 50),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F2FF),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                              prefixIcon: const Icon(
                                Icons.mail_outline,
                                color: Color(0xFF7C6FDC),
                                size: 22,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              errorStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F2FF),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 15,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF7C6FDC),
                                size: 22,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                  size: 22,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              errorStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C6FDC),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: Color(0xFF7C6FDC),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}