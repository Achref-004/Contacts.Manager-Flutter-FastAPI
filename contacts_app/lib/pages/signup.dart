import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
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
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
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

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _apiService.register(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        telephone: _telephoneController.text.trim(),
        password: _passwordController.text,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2FF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          prefixIcon: Icon(icon, color: const Color(0xFF7C6FDC), size: 22),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          errorStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF7C6FDC),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Expanded(
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
                              const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Sign up to get started',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 40),

                              Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Image.asset(
                                  'assets/singup_img.jpg',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      padding: const EdgeInsets.all(30),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F2FF),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.person_add_outlined,
                                        size: 80,
                                        color: Color(0xFF7C6FDC),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 40),

                              _buildTextField(
                                controller: _nomController,
                                hintText: 'Nom',
                                icon: Icons.person_outline,
                                validator: (value) => _validateName(value, 'Nom'),
                                keyboardType: TextInputType.name,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _prenomController,
                                hintText: 'Prénom',
                                icon: Icons.person_outline,
                                validator: (value) => _validateName(value, 'Prénom'),
                                keyboardType: TextInputType.name,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _telephoneController,
                                hintText: 'Numéro de téléphone',
                                icon: Icons.phone_outlined,
                                validator: _validatePhone,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _emailController,
                                hintText: 'Email',
                                icon: Icons.mail_outline,
                                validator: _validateEmail,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 16),

                              _buildTextField(
                                controller: _passwordController,
                                hintText: 'Mot de passe',
                                icon: Icons.lock_outline,
                                validator: _validatePassword,
                                obscureText: _obscurePassword,
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
                              ),
                              const SizedBox(height: 30),

                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signUp,
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
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'SIGN UP',
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
                                    "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'Login',
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
          ),
        ],
      ),
    );
  }
}