import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyInterviewsScreen extends StatefulWidget {
  const CompanyInterviewsScreen({super.key});

  @override
  State<CompanyInterviewsScreen> createState() => _CompanyInterviewsScreenState();
}

class _CompanyInterviewsScreenState extends State<CompanyInterviewsScreen> {
  static const Color background = Color(0xFFF4F4F4);
  static const Color lime = Color(0xFFD4FF00);

  String? savingDecisionId;

  BoxDecoration _brutalBox() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
    );
  }

  DateTime _parseCustomDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 2) return DateTime(2099);

      final dateParts = parts[0].trim().split('/');
      final timeParts = parts[1].trim().split(':');

      if (dateParts.length != 2 || timeParts.length != 2) return DateTime(2099);

      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final year = DateTime.now().year;

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return DateTime(2099);
    }
  }

  Future<void> _deleteInterview(String docId) async {
    await FirebaseFirestore.instance.collection('interviews').doc(docId).delete();
  }

  Future<void> _decideCandidate(
    String interviewId,
    String decision,
  ) async {
    if (savingDecisionId != null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: background,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.black, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          decision == 'ACEPTADO'
              ? 'ACEPTAR POSTULANTE'
              : 'RECHAZAR POSTULANTE',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          '¿Confirmás que querés ${decision == 'ACEPTADO' ? 'aceptar' : 'rechazar'} al postulante? Esta decisión será definitiva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: decision == 'ACEPTADO'
                  ? lime
                  : const Color(0xFFFFA6A6),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'CONFIRMAR',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => savingDecisionId = interviewId);

    try {
      final db = FirebaseFirestore.instance;
      final interviewRef = db.collection('interviews').doc(interviewId);
      final interviewDoc = await interviewRef.get();

      if (!interviewDoc.exists ||
          interviewDoc.data()?['companyId'] != user.uid) {
        throw Exception('Entrevista no disponible.');
      }

      final interview = interviewDoc.data()!;
      final candidateId = interview['userId']?.toString() ?? '';
      final position = interview['position']?.toString() ?? '';
      final applicationId = interview['applicationId']?.toString() ?? '';

      if (candidateId.isEmpty || position.isEmpty) {
        throw Exception('Faltan datos para identificar la postulación.');
      }

      DocumentReference<Map<String, dynamic>> applicationRef;

      if (applicationId.isNotEmpty) {
        applicationRef = db.collection('applications').doc(applicationId);
      } else {
        final query = await db
            .collection('applications')
            .where('companyId', isEqualTo: user.uid)
            .where('userId', isEqualTo: candidateId)
            .get();

        final matches = query.docs.where(
          (doc) => doc.data()['role']?.toString() == position,
        ).toList();

        if (matches.length != 1) {
          throw Exception(
            matches.isEmpty
                ? 'No se encontró la postulación.'
                : 'Hay varias postulaciones para este puesto.',
          );
        }

        applicationRef = matches.first.reference;
      }

      await db.runTransaction((transaction) async {
        final currentInterview = await transaction.get(interviewRef);
        final currentApplication = await transaction.get(applicationRef);

        if (!currentInterview.exists || !currentApplication.exists) {
          throw Exception('La entrevista o postulación ya no existe.');
        }

        final interviewData = currentInterview.data()!;
        final applicationData = currentApplication.data()!;

        if (interviewData['companyId'] != user.uid ||
            applicationData['companyId'] != user.uid ||
            applicationData['userId'] != candidateId ||
            applicationData['role']?.toString() != position) {
          throw Exception('La entrevista no coincide con la postulación.');
        }

        final status = applicationData['status']?.toString() ?? '';

        if (status != 'ENTREVISTA' ||
            interviewData['decisionStatus'] == 'ACEPTADO' ||
            interviewData['decisionStatus'] == 'RECHAZADO') {
          throw Exception('Esta postulación ya no admite una decisión.');
        }

        transaction.update(applicationRef, {
          'status': decision,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(interviewRef, {
          'applicationId': applicationRef.id,
          'decisionStatus': decision,
          'decisionAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('POSTULANTE $decision CORRECTAMENTE')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la decisión: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => savingDecisionId = null);
    }
  }

  Future<void> _showContactInfo(String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!mounted) return;
      Navigator.pop(context);

      final data = doc.data() ?? {};
      final name = data['name']?.toString() ?? 'Sin nombre';
      final email = data['email']?.toString() ?? 'Sin email';
      final phone = data['phone']?.toString() ?? 'Sin teléfono';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: background,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.black, width: 2),
            borderRadius: BorderRadius.zero,
          ),
          title: const Text(
            'CONTACTO DEL CANDIDATO',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOMBRE: $name',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'EMAIL: $email',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'TELÉFONO: $phone',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CERRAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _editInterview(
    String docId,
    Map<String, dynamic> data,
  ) async {
    final dateController = TextEditingController(text: data['dateString']);
    final linkController = TextEditingController(text: data['link']);
    final notesController = TextEditingController(text: data['notes']);
    String modality = data['modality'] ?? 'VIRTUAL';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: background,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.black, width: 2),
            borderRadius: BorderRadius.zero,
          ),
          title: const Text(
            'EDITAR ENTREVISTA',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha y Hora',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: modality,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'VIRTUAL',
                      child: Text('VIRTUAL'),
                    ),
                    DropdownMenuItem(
                      value: 'PRESENCIAL',
                      child: Text('PRESENCIAL'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => modality = val);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: 'Link / Dirección',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas / Instrucciones',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('interviews')
                    .doc(docId)
                    .update({
                  'dateString': dateController.text.trim(),
                  'modality': modality,
                  'link': linkController.text.trim(),
                  'notes': notesController.text.trim(),
                });

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'GUARDAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterviewList(
    List<QueryDocumentSnapshot> docs,
    bool isHistory,
  ) {
    final filteredDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final decision = data['decisionStatus']?.toString() ?? '';
      final hasDecision =
          decision == 'ACEPTADO' || decision == 'RECHAZADO';

      return isHistory ? hasDecision : !hasDecision;
    }).toList();

    filteredDocs.sort((a, b) {
      final dateA = _parseCustomDate(
        (a.data() as Map<String, dynamic>)['dateString'] ?? '',
      );
      final dateB = _parseCustomDate(
        (b.data() as Map<String, dynamic>)['dateString'] ?? '',
      );
      return dateA.compareTo(dateB);
    });

    if (filteredDocs.isEmpty) {
      return Center(
        child: Text(
          isHistory
              ? 'NO HAY HISTORIAL'
              : 'NO HAY ENTREVISTAS PENDIENTES',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId']?.toString() ?? '';
        final decision = data['decisionStatus']?.toString() ?? '';
        final hasDecision =
            decision == 'ACEPTADO' || decision == 'RECHAZADO';

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: _brutalBox(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['position']?.toString().toUpperCase() ?? 'PUESTO',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: decision == 'ACEPTADO'
                          ? lime
                          : decision == 'RECHAZADO'
                              ? const Color(0xFFFFA6A6)
                              : Colors.white,
                      border: Border.all(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      hasDecision ? decision : 'PENDIENTE',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(
                color: Colors.black,
                thickness: 1.5,
              ),
              const SizedBox(height: 8),
              Text(
                'FECHA: ${data['dateString']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'MODALIDAD: ${data['modality']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      icon: const Icon(
                        Icons.person_search,
                        size: 16,
                      ),
                      label: const Text(
                        'CONTACTO',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      onPressed: () => _showContactInfo(userId),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text(
                        'EDITAR',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      onPressed: () => _editInterview(doc.id, data),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text(
                        'BORRAR',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      onPressed: () => _deleteInterview(doc.id),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(
                color: Colors.black,
                thickness: 1.5,
              ),
              const SizedBox(height: 8),
              const Text(
                'RESULTADO DEL PROCESO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),

              if (hasDecision)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: decision == 'ACEPTADO'
                        ? lime
                        : const Color(0xFFFFA6A6),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'POSTULANTE $decision',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lime,
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(
                            side: BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: savingDecisionId != null
                            ? null
                            : () => _decideCandidate(
                                  doc.id,
                                  'ACEPTADO',
                                ),
                        child: const Text(
                          'ACEPTAR',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA6A6),
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(
                            side: BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: savingDecisionId != null
                            ? null
                            : () => _decideCandidate(
                                  doc.id,
                                  'RECHAZADO',
                                ),
                        child: const Text(
                          'RECHAZAR',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              if (savingDecisionId == doc.id)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: LinearProgressIndicator(
                    color: Colors.black,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: const Text(
            'MIS ENTREVISTAS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: lime,
            indicatorWeight: 4,
            labelColor: lime,
            unselectedLabelColor: Colors.white54,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
            tabs: [
              Tab(text: 'PRÓXIMAS'),
              Tab(text: 'HISTORIAL'),
            ],
          ),
        ),
        body: user == null
            ? const Center(
                child: Text(
                  'INICIÁ SESIÓN',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('interviews')
                    .where('companyId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('ERROR AL CARGAR ENTREVISTAS'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.black,
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return TabBarView(
                    children: [
                      _buildInterviewList(docs, false),
                      _buildInterviewList(docs, true),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
