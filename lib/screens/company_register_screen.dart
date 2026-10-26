import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyRegisterScreen extends StatefulWidget {
  const CompanyRegisterScreen({super.key});

  @override
  State<CompanyRegisterScreen> createState() => _CompanyRegisterScreenState();
}

class _CompanyRegisterScreenState extends State<CompanyRegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cuitController = TextEditingController();
  final _countryController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _logoUrlController = TextEditingController();
  
  String _selectedSector = 'Tecnología / Software';
  bool _isLoading = false;

  static const Color lime = Color(0xFFD4FF00);

  final List<String> _sectores = [
    'Tecnología / Software',
    'Finanzas / Bancos',
    'Salud / Medicina',
    'Comercio / Retail',
    'Educación',
    'Industria / Manufactura',
    'Otro'
  ];

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: lime,
      ),
    );
  }

  Future<void> _registerCompany() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final cuit = _cuitController.text.trim();

    if (email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty || cuit.isEmpty) {
      _showMessage('Por favor, completá los campos obligatorios (*).');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'role': 'empresa',
        'name': '$firstName $lastName',
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'cuit': cuit,
        'sector': _selectedSector,
        'country': _countryController.text.trim(),
        'website': _websiteController.text.trim(),
        'bio': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'logoUrl': _logoUrlController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      Navigator.pop(context);
      _showMessage('¡Cuenta de empresa creada con éxito!');

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _showMessage('La contraseña es muy débil.');
      } else if (e.code == 'email-already-in-use') {
        _showMessage('Ya existe una cuenta con este email.');
      } else {
        _showMessage('Error: ${e.message}');
      }
    } catch (e) {
      _showMessage('Error al registrar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            obscureText: isPassword,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: lime, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('REGISTRO DE EMPRESA', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        shape: const Border(bottom: BorderSide(color: lime, width: 2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'DATOS CORPORATIVOS',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: lime),
            ),
            const SizedBox(height: 20),
            
            _buildTextField(controller: _firstNameController, label: 'NOMBRE/S *'),
            _buildTextField(controller: _lastNameController, label: 'APELLIDO *'),
            _buildTextField(controller: _cuitController, label: 'CUIT *', keyboardType: TextInputType.number),
            
            const Text('SECTOR / INDUSTRIA *', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white)),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.white,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSector,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  items: _sectores.map((String sector) {
                    return DropdownMenuItem<String>(
                      value: sector,
                      child: Text(sector, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedSector = newValue);
                    }
                  },
                ),
              ),
            ),
            
            _buildTextField(controller: _countryController, label: 'PAÍS DE LA EMPRESA (Opcional)'),
            _buildTextField(controller: _websiteController, label: 'SITIO WEB (Opcional)', keyboardType: TextInputType.url),
            _buildTextField(controller: _logoUrlController, label: 'URL DEL LOGO (Opcional)', keyboardType: TextInputType.url),
            _buildTextField(controller: _descriptionController, label: 'BREVE DESCRIPCIÓN (Opcional)', maxLines: 3),
            
            const SizedBox(height: 10),
            const Divider(color: lime, thickness: 2),
            const SizedBox(height: 20),
            
            const Text(
              'DATOS DE ACCESO Y CONTACTO',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: lime),
            ),
            const SizedBox(height: 20),
            
            _buildTextField(controller: _emailController, label: 'EMAIL CORPORATIVO *', keyboardType: TextInputType.emailAddress),
            _buildTextField(controller: _phoneController, label: 'TELÉFONO DE CONTACTO (Opcional)', keyboardType: TextInputType.phone),
            _buildTextField(controller: _passwordController, label: 'CONTRASEÑA *', isPassword: true),
            
            const SizedBox(height: 30),
            
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: lime,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: _isLoading ? null : _registerCompany,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('CREAR CUENTA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}