import 'package:flutter/material.dart';
import 'package:job_track/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. TODOS LOS CONTROLADORES BASADOS EN TU DISEÑO
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _cuitController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _logoController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _selectedIndustry = 'Tecnología / Software';
  final List<String> _industryOptions = ['Tecnología / Software', 'Finanzas', 'Salud', 'Educación', 'Otro'];

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _cuitController.dispose();
    _countryController.dispose();
    _websiteController.dispose();
    _logoController.dispose();
    _descriptionController.dispose();
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
    final lastName = _lastNameController.text.trim();
    final cuit = _cuitController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validar solo los obligatorios (marcados con *)
    if (name.isEmpty || lastName.isEmpty || cuit.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos obligatorios (*)')),
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
        role: 'empresa',
        industry: _selectedIndustry,
        
        
        
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta corporativa creada con éxito. Ya puedes iniciar sesión.')),
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

  
  Widget _buildBrutalistTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool isOptional = false,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    const brutalistBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Colors.black, width: 2.0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isOptional ? '$label (Opcional)' : '$label *',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          style: TextStyle(fontFamily: 'monospace', letterSpacing: isObscure ? 4.0 : 1.0),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey, letterSpacing: isObscure ? 4.0 : 1.0),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: brutalistBorder,
            focusedBorder: brutalistBorder,
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: suffixIcon,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
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
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('REGISTRO DE EMPRESA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.black, 
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Theme(
              data: ThemeData.dark(), // Forzamos modo oscuro para los textos
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'DATOS CORPORATIVOS',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Color(0xFFCCFF00)), // Verde flúor
                  ),
                  const SizedBox(height: 32),

                  _buildBrutalistTextField(label: 'NOMBRE/S', controller: _nameController),
                  _buildBrutalistTextField(label: 'APELLIDO', controller: _lastNameController),
                  _buildBrutalistTextField(label: 'CUIT', controller: _cuitController, keyboardType: TextInputType.number),
                  
                  
                  const Text('SECTOR / INDUSTRIA *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedIndustry,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.black, fontSize: 16),
                    decoration: const InputDecoration(
                      filled: true, fillColor: Colors.white,
                      enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: _industryOptions.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                    onChanged: (newValue) => setState(() => _selectedIndustry = newValue!),
                  ),
                  const SizedBox(height: 24),

                  _buildBrutalistTextField(label: 'PAÍS DE LA EMPRESA', controller: _countryController, isOptional: true),
                  _buildBrutalistTextField(label: 'SITIO WEB', controller: _websiteController, isOptional: true, keyboardType: TextInputType.url),
                  _buildBrutalistTextField(label: 'URL DEL LOGO', controller: _logoController, isOptional: true, keyboardType: TextInputType.url),
                  _buildBrutalistTextField(label: 'BREVE DESCRIPCIÓN', controller: _descriptionController, isOptional: true),
                  
                  _buildBrutalistTextField(label: 'EMAIL CORPORATIVO', controller: _emailController, keyboardType: TextInputType.emailAddress),
                  
                 
                  _buildBrutalistTextField(
                    label: 'CONTRASEÑA', 
                    controller: _passwordController, 
                    isObscure: _obscurePassword,
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // Botón de Registro
                  GestureDetector(
                    onTap: _handleRegister,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey[800] : const Color(0xFFCCFF00), // Verde flúor
                        border: Border.all(color: Colors.white, width: 2.0),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3.0))
                            : const Text('CREAR CUENTA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.black)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}