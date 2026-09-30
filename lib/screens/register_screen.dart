import 'package:flutter/material.dart';
import 'package:job_track/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isCandidate = true;

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  void _handleRegister() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final industry = _industryController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    if (!_isCandidate && industry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa la industria o sector')),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato de email inválido')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.registerUser(
        email: email,
        password: password,
        name: name,
        role: _isCandidate ? 'candidato' : 'empresa',
        industry: !_isCandidate ? industry : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada con éxito. Ya puedes iniciar sesión.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brutalistBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Colors.black, width: 2.0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'JOBTRACKER',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'REGISTRO',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona tu tipo de cuenta para empezar.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCandidate = true),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isCandidate ? const Color(0xFFD4FF00) : Colors.white,
                          border: Border.all(color: Colors.black, width: 2.0),
                          boxShadow: _isCandidate
                              ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: _isCandidate ? Colors.black : Colors.grey[600],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CANDIDATO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: _isCandidate ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCandidate = false),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: !_isCandidate ? Colors.black : Colors.white,
                          border: Border.all(color: Colors.black, width: 2.0),
                          boxShadow: !_isCandidate
                              ? const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.domain,
                              color: !_isCandidate ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'EMPRESA',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                                color: !_isCandidate ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                _isCandidate ? 'NOMBRE COMPLETO' : 'NOMBRE DE LA EMPRESA',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: _isCandidate ? 'Ej. Juan Pérez' : 'Ej. TechCorp Inc.',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: brutalistBorder,
                  focusedBorder: brutalistBorder,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              if (!_isCandidate) ...[
                const Text(
                  'INDUSTRIA / SECTOR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _industryController,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    hintText: 'Ej. Desarrollo de Software',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: brutalistBorder,
                    focusedBorder: brutalistBorder,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                _isCandidate ? 'EMAIL' : 'EMAIL CORPORATIVO',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'correo@ejemplo.com',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: brutalistBorder,
                  focusedBorder: brutalistBorder,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'CONTRASEÑA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(
                  fontFamily: 'monospace', 
                  letterSpacing: _obscurePassword ? 4.0 : 1.0
                ),
                decoration: InputDecoration(
                  hintText: _obscurePassword ? '........' : 'Tu contraseña',
                  hintStyle: TextStyle(
                    color: Colors.grey, 
                    letterSpacing: _obscurePassword ? 4.0 : 1.0
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: brutalistBorder,
                  focusedBorder: brutalistBorder,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _handleRegister,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isLoading 
                        ? (_isCandidate ? const Color(0xFFAACC00) : Colors.grey[800]) 
                        : (_isCandidate ? const Color(0xFFD4FF00) : Colors.black),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: _isCandidate ? Colors.black : Colors.white,
                              strokeWidth: 3.0,
                            ),
                          )
                        : Text(
                            _isCandidate ? 'CREAR CUENTA DE CANDIDATO' : 'CREAR CUENTA DE EMPRESA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: _isCandidate ? Colors.black : Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(text: '¿Ya tienes cuenta? '),
                        TextSpan(
                          text: 'Ingresa aquí',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationThickness: 2.0,
                          ),
                        ),
                      ],
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