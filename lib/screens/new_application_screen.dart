import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String numbers = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbers.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final value = int.parse(numbers);

    final formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    final result = '\$ $formatted';

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: result.length,
      ),
    );
  }
}

class NewApplicationScreen extends StatefulWidget {
  const NewApplicationScreen({super.key});

  @override
  State<NewApplicationScreen> createState() =>
      _NewApplicationScreenState();
}

class _NewApplicationScreenState
    extends State<NewApplicationScreen> {
  final TextEditingController _companyController =
      TextEditingController();

  final TextEditingController _roleController =
      TextEditingController();

  final TextEditingController _offerLinkController =
      TextEditingController();

  final TextEditingController _salaryController =
      TextEditingController();

  DateTime? _selectedDate;

  String _selectedModality = 'PRESENCIAL';

  bool _isLoading = false;

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _offerLinkController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveApplication() async {
    if (_isLoading) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay un usuario autenticado'),
        ),
      );
      return;
    }

    final company = _companyController.text.trim();
    final role = _roleController.text.trim();

    if (company.isEmpty || role.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa empresa, puesto y fecha',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .add({
        'userId': user.uid,
        'company': company,
        'role': role,
        'date': Timestamp.fromDate(_selectedDate!),
        'status': 'POSTULADO',
        'offerLink': _offerLinkController.text.trim(),
        'modality': _selectedModality,
        'salary': _salaryController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Postulación guardada correctamente',
            ),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar la postulación: $e',
            ),
          ),
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
      borderSide: BorderSide(
        color: Colors.black,
        width: 2,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD4FF00),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'NUEVA POSTULACIÓN',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'REGISTRAR POSTULACIÓN',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Guarda la información del proceso laboral.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 28),

              _buildLabel('EMPRESA'),

              TextField(
                controller: _companyController,
                decoration: const InputDecoration(
                  hintText: 'Ej. Mercado Libre',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: brutalistBorder,
                  focusedBorder: brutalistBorder,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 20),

              _buildLabel('PUESTO / ROL'),

              TextField(
                controller: _roleController,
                decoration: const InputDecoration(
                  hintText: 'Ej. Flutter Developer',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: brutalistBorder,
                  focusedBorder: brutalistBorder,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 20),

              _buildLabel('FECHA'),

              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Seleccionar fecha'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                      const Icon(
                        Icons.calendar_month,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _buildLabel('MODALIDAD'),

              DropdownButtonFormField<String>(
                initialValue: _selectedModality,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: brutalistBorder,
                  focusedBorder: brutalistBorder,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'PRESENCIAL',
                    child: Text('PRESENCIAL'),
                  ),
                  DropdownMenuItem(
                    value: 'HÍBRIDO',
                    child: Text('HÍBRIDO'),
                  ),
                  DropdownMenuItem(
                    value: 'REMOTO',
                    child: Text('REMOTO'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedModality = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              _buildLabel('SALARIO'),

              TextField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(),
                ],
                decoration: const InputDecoration(
                  hintText: '\$ 0',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: brutalistBorder,
                  focusedBorder: brutalistBorder,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 20),

              _buildLabel('LINK DE LA OFERTA'),

              TextField(
                controller: _offerLinkController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  hintText: 'https://...',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: brutalistBorder,
                  focusedBorder: brutalistBorder,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 32),

              GestureDetector(
                onTap: _saveApplication,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? const Color(0xFFAACC00)
                        : const Color(0xFFD4FF00),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
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
                        ? const CircularProgressIndicator(
                            color: Colors.black,
                          )
                        : const Text(
                            'GUARDAR POSTULACIÓN',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}