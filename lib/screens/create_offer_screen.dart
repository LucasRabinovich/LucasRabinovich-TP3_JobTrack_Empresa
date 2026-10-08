import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateOfferScreen extends StatefulWidget {
  final String? offerId;
  final Map<String, dynamic>? existingOffer;

  const CreateOfferScreen({super.key, this.offerId, this.existingOffer});

  @override
  State<CreateOfferScreen> createState() => _CreateOfferScreenState();
}

class _CreateOfferScreenState extends State<CreateOfferScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  String _selectedModality = 'Remoto';
  String _selectedContract = 'Full-time';
  String _selectedSeniority = 'Junior';
  bool _isLoading = false;

  final List<String> _modalityOptions = ['Remoto', 'Híbrido', 'Presencial'];
  final List<String> _contractOptions = ['Full-time', 'Part-time', 'Freelance', 'Pasantía'];
  final List<String> _seniorityOptions = ['Trainee', 'Junior', 'Semi-Senior', 'Senior'];

  @override
  void initState() {
    super.initState();
    if (widget.existingOffer != null) {
      _titleController.text = widget.existingOffer!['title'] ?? '';
      _salaryController.text = widget.existingOffer!['salaryRange'] ?? '';
      _descriptionController.text = widget.existingOffer!['description'] ?? '';
      _locationController.text = widget.existingOffer!['location'] ?? '';
      _selectedModality = widget.existingOffer!['modality'] ?? 'Remoto';
      _selectedContract = widget.existingOffer!['contractType'] ?? 'Full-time';
      _selectedSeniority = widget.existingOffer!['seniority'] ?? 'Junior';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _handlePublish() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final salary = _salaryController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título y la descripción son obligatorios')),
      );
      return;
    }

    if ((_selectedModality == 'Presencial' || _selectedModality == 'Híbrido') && location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor indica la ubicación para esta modalidad')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;

      final offerData = {
        'title': title,
        'modality': _selectedModality,
        'contractType': _selectedContract,
        'seniority': _selectedSeniority,
        'location': _selectedModality == 'Remoto' ? 'No aplica' : location,
        'salaryRange': salary.isNotEmpty ? salary : 'No especificado',
        'description': description,
        'isActive': true,
      };

      if (widget.offerId == null) {
        offerData['companyId'] = uid;
        offerData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('job_offers').add(offerData);
      } else {
        await FirebaseFirestore.instance.collection('job_offers').doc(widget.offerId).update(offerData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.offerId == null ? '¡Oferta publicada con éxito!' : '¡Oferta actualizada!')),
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

    final bool requiresLocation = _selectedModality == 'Presencial' || _selectedModality == 'Híbrido';
    final bool isEditing = widget.offerId != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'JOB TRACKER',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: Colors.black, height: 2.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'EDITAR OFERTA' : 'NUEVA OFERTA',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.black),
              ),
              const SizedBox(height: 8),
              Container(height: 2, color: Colors.black),
              const SizedBox(height: 24),
              
              const Text('TÍTULO DEL PUESTO *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'Ej. Backend Node.js', hintStyle: TextStyle(color: Colors.grey),
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              const Text('NIVEL / SENIORITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSeniority,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                style: const TextStyle(fontFamily: 'monospace', color: Colors.black, fontSize: 16),
                decoration: const InputDecoration(
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _seniorityOptions.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => _selectedSeniority = newValue!),
              ),
              const SizedBox(height: 24),

              const Text('MODALIDAD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedModality,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                style: const TextStyle(fontFamily: 'monospace', color: Colors.black, fontSize: 16),
                decoration: const InputDecoration(
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _modalityOptions.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => _selectedModality = newValue!),
              ),
              const SizedBox(height: 24),

              if (requiresLocation) ...[
                const Text('UBICACIÓN / CIUDAD *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    hintText: 'Ej. Buenos Aires, Centro', hintStyle: TextStyle(color: Colors.grey),
                    filled: true, fillColor: Colors.white,
                    enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text('TIPO DE CONTRATO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedContract,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                style: const TextStyle(fontFamily: 'monospace', color: Colors.black, fontSize: 16),
                decoration: const InputDecoration(
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _contractOptions.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                onChanged: (newValue) => setState(() => _selectedContract = newValue!),
              ),
              const SizedBox(height: 24),

              const Text('RANGO SALARIAL (OPCIONAL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              TextField(
                controller: _salaryController,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'Ej. \$2000 - \$3000 USD', hintStyle: TextStyle(color: Colors.grey),
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              const Text('DESCRIPCIÓN / REQUISITOS *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: 'Responsabilidades, stack tecnológico, beneficios...', hintStyle: TextStyle(color: Colors.grey),
                  filled: true, fillColor: Colors.white,
                  enabledBorder: brutalistBorder, focusedBorder: brutalistBorder, contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 40),

              GestureDetector(
                onTap: _handlePublish,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey[800] : Colors.black,
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0))
                        : Text(
                            isEditing ? 'GUARDAR CAMBIOS' : 'PUBLICAR OFERTA',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () {
                  if (!_isLoading) Navigator.pop(context);
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)],
                  ),
                  child: const Center(
                    child: Text('CANCELAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.black)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}