import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;
  final Map<String, dynamic> applicationData;

  const ApplicationDetailScreen({
    super.key,
    required this.applicationId,
    required this.applicationData,
  });

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState
    extends State<ApplicationDetailScreen> {
  late String _selectedStatus;
  late TextEditingController _notesController;

  bool _isSaving = false;

  final List<String> _statuses = [
    'POSTULADO',
    'EN PROCESO',
    'ENTREVISTA',
    'OFERTA',
    'RECHAZADO',
  ];

  @override
  void initState() {
    super.initState();

    _selectedStatus =
        widget.applicationData['status']?.toString() ?? 'POSTULADO';

    _notesController = TextEditingController(
      text: widget.applicationData['notes']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .update({
        'status': _selectedStatus,
        'notes': _notesController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados correctamente'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar cambios: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day}/${date.month}/${date.year}';
    }

    return 'Sin fecha';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.applicationData;

    final company = data['company']?.toString() ?? 'Sin empresa';
    final role = data['role']?.toString() ?? 'Sin puesto';
    final modality = data['modality']?.toString() ?? 'Sin modalidad';
    final salary = data['salary']?.toString() ?? '';
    final offerLink = data['offerLink']?.toString() ?? '';

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
          'DETALLE',
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
              Text(
                company.toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                role,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 24),

              _buildInfoBox(
                title: 'FECHA',
                value: _formatDate(data['date']),
              ),

              const SizedBox(height: 12),

              _buildInfoBox(
                title: 'MODALIDAD',
                value: modality,
              ),

              if (salary.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoBox(
                  title: 'SALARIO',
                  value: salary,
                ),
              ],

              if (offerLink.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoBox(
                  title: 'LINK DE LA OFERTA',
                  value: offerLink,
                ),
              ],

              const SizedBox(height: 28),

              const Text(
                'ESTADO ACTUAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                ),
                items: _statuses
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 28),

              const Text(
                'NOTAS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _notesController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Agrega notas sobre entrevistas, contactos o próximos pasos...',
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'TIMELINE DEL PROCESO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 16),

              _buildTimelineItem(
                title: 'POSTULADO',
                active: true,
              ),
              _buildTimelineItem(
                title: 'EN PROCESO',
                active: _selectedStatus == 'EN PROCESO' ||
                    _selectedStatus == 'ENTREVISTA' ||
                    _selectedStatus == 'OFERTA',
              ),
              _buildTimelineItem(
                title: 'ENTREVISTA',
                active: _selectedStatus == 'ENTREVISTA' ||
                    _selectedStatus == 'OFERTA',
              ),
              _buildTimelineItem(
                title: 'OFERTA',
                active: _selectedStatus == 'OFERTA',
              ),

              const SizedBox(height: 32),

              GestureDetector(
                onTap: _saveChanges,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _isSaving
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
                    child: _isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.black,
                          )
                        : const Text(
                            'GUARDAR CAMBIOS',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required bool active,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFD4FF00)
                    : Colors.white,
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
            Container(
              width: 2,
              height: 34,
              color: Colors.black,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            title,
            style: TextStyle(
              fontWeight:
                  active ? FontWeight.w900 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}