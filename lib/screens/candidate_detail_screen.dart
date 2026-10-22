import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class CandidateDetailScreen extends StatefulWidget {
  final String applicationId;

  const CandidateDetailScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  static const Color background = Color(0xFFF4F4F4);
  static const Color lime = Color(0xFFD4FF00);

  static const List<String> statuses = [
    'POSTULADO',
    'ENTREVISTA',
    'ACEPTADO',
    'RECHAZADO',
  ];

  bool isSaving = false;
  bool isOpeningCv = false;

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> updateStatus(String companyId, String newStatus) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid != companyId || isSaving) {
      return;
    }

    setState(() => isSaving = true);

    try {
      final applicationRef = FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId);

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final snapshot = await transaction.get(applicationRef);

          if (!snapshot.exists) {
            throw Exception('La postulación ya no existe.');
          }

          final application = snapshot.data();

          if (application?['companyId'] != user.uid) {
            throw Exception('No tenés permiso para modificar esta postulación.');
          }

          transaction.update(applicationRef, {
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        },
      );

      showMessage('Estado actualizado correctamente');
    } catch (e) {
      showMessage('No se pudo actualizar el estado: $e');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _showInterviewDialog(String candidateId, String company, String role) async {
    final dateController = TextEditingController();
    final linkController = TextEditingController();
    final notesController = TextEditingController();
    String modality = 'VIRTUAL';
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: background,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: Colors.black, width: 2),
                borderRadius: BorderRadius.zero,
              ),
              title: const Text(
                'PROGRAMAR ENTREVISTA',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FECHA Y HORA (Ej: 25/10 - 14:30)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.zero,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text('MODALIDAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: DropdownButton<String>(
                        value: modality,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'VIRTUAL', child: Text('VIRTUAL', style: TextStyle(fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'PRESENCIAL', child: Text('PRESENCIAL', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        onChanged: (val) {
                          setDialogState(() => modality = val!);
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      modality == 'VIRTUAL' ? 'ENLACE (MEET/ZOOM)' : 'DIRECCIÓN',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: linkController,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.zero,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text('NOTAS / INSTRUCCIONES (Opcional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Ej: Preguntar por recepción, llevar DNI, etc.',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.black54),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 2),
                          borderRadius: BorderRadius.zero,
                        ),
                        focusedBorder: OutlineInputBorder(
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
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (dateController.text.trim().isEmpty) {
                            showMessage('Por favor ingresá la fecha y hora');
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          try {
                            await FirebaseFirestore.instance.collection('interviews').add({
                              'userId': candidateId,
                              'company': company,
                              'position': role,
                              'dateString': dateController.text.trim(),
                              'modality': modality,
                              'link': linkController.text.trim(),
                              'notes': notesController.text.trim(),
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            showMessage('ENTREVISTA PROGRAMADA CON ÉXITO');
                            
                          } catch (e) {
                            showMessage('Error al programar la entrevista: $e');
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  child: Text(
                    isSubmitting ? 'GUARDANDO...' : 'CONFIRMAR',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> openCv(String documentId, String candidateId) async {
    if (isOpeningCv) return;

    final company = FirebaseAuth.instance.currentUser;

    if (company == null) {
      showMessage('Debés iniciar sesión.');
      return;
    }

    setState(() => isOpeningCv = true);

    try {
      final applicationSnapshot = await FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId)
          .get();

      final application = applicationSnapshot.data();

      if (application == null ||
          application['companyId'] != company.uid ||
          application['userId'] != candidateId) {
        throw Exception('No tenés permiso para consultar este CV.');
      }

      final documentRef = FirebaseFirestore.instance
          .collection('documents')
          .doc(documentId);

      final documentSnapshot = await documentRef.get();
      final document = documentSnapshot.data();

      if (document == null ||
          document['userId'] != candidateId ||
          document['type'] != 'cv') {
        throw Exception('CV no disponible.');
      }

      final chunkCount = (document['chunkCount'] as num?)?.toInt() ?? 0;

      if (chunkCount <= 0 || chunkCount > 18) {
        throw Exception('El CV tiene una cantidad de fragmentos inválida.');
      }

      final builder = BytesBuilder(copy: false);

      for (int i = 0; i < chunkCount; i++) {
        final chunkId = i.toString().padLeft(4, '0');

        final chunkSnapshot = await documentRef
            .collection('chunks')
            .doc(chunkId)
            .get();

        if (!chunkSnapshot.exists) {
          throw Exception('Falta una parte del archivo PDF.');
        }

        final blob = chunkSnapshot.data()?['data'];

        if (blob is! Blob) {
          throw Exception('No se pudo recuperar el contenido del CV.');
        }

        builder.add(blob.bytes);
      }

      final bytes = builder.takeBytes();

      final expectedSize = (document['size'] as num?)?.toInt();

      if (expectedSize == null || bytes.length != expectedSize) {
        throw Exception('El PDF descargado está incompleto.');
      }

      final directory = await getTemporaryDirectory();

      final pdfFile = File('${directory.path}/jobtrack_empresa_cv_$documentId.pdf');

      await pdfFile.writeAsBytes(bytes, flush: true);

      final result = await OpenFilex.open(pdfFile.path);

      if (result.type != ResultType.done) {
        throw Exception('No se pudo abrir el PDF: ${result.message}');
      }
    } catch (e) {
      showMessage('Error al abrir CV: $e');
    } finally {
      if (mounted) {
        setState(() => isOpeningCv = false);
      }
    }
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget informationField(String label, dynamic value) {
    final text = value?.toString().trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text.isEmpty ? 'No especificado' : text,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget borderedPanel(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildCandidateProfile(String candidateId) {
    if (candidateId.isEmpty) {
      return borderedPanel(const Text('No se encontró el identificador del candidato.'));
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(candidateId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return borderedPanel(const Text('No se pudo consultar el perfil del candidato.'));
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        final profile = snapshot.data!.data();

        if (profile == null) {
          return borderedPanel(const Text('El candidato no tiene un perfil disponible.'));
        }

        return borderedPanel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              informationField('NOMBRE', profile['name']),
              informationField('EMAIL', profile['email']),
              informationField('TELÉFONO', profile['phone']),
              informationField('UBICACIÓN', profile['location']),
              informationField('PROFESIÓN', profile['profession']),
              informationField('BIOGRAFÍA', profile['bio']),
              informationField('EXPERIENCIA', profile['experience']),
              informationField('EDUCACIÓN', profile['education']),
              informationField('HABILIDADES', profile['skills']),
            ],
          ),
        );
      },
    );
  }

  Widget buildCvSection(String candidateId) {
    if (candidateId.isEmpty) {
      return borderedPanel(const Text('Candidato no identificado.'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('documents')
          .where('userId', isEqualTo: candidateId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return borderedPanel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NO SE PUDIERON CONSULTAR LOS CV',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text('${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        final documents = snapshot.data!.docs
            .where((doc) => doc.data()['type'] == 'cv')
            .toList();

        documents.sort((a, b) {
          final aPrimary = a.data()['isPrimary'] == true;
          final bPrimary = b.data()['isPrimary'] == true;

          if (aPrimary != bPrimary) {
            return aPrimary ? -1 : 1;
          }

          return 0;
        });

        if (documents.isEmpty) {
          return borderedPanel(
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description_outlined, size: 32),
                SizedBox(height: 12),
                Text(
                  'CV NO DISPONIBLE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text('El candidato todavía no cargó ningún CV.'),
              ],
            ),
          );
        }

        return borderedPanel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CURRÍCULUMS DEL CANDIDATO',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              for (final document in documents) ...[
                Builder(
                  builder: (context) {
                    final data = document.data();
                    final name = data['name']?.toString() ?? 'Currículum PDF';
                    final isPrimary = data['isPrimary'] == true;
                    final size = (data['size'] as num?)?.toInt() ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(size / 1024).toStringAsFixed(1)} KB',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(7),
                            color: lime,
                            child: const Text(
                              'CV PRINCIPAL',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isOpeningCv ? null : () => openCv(document.id, candidateId),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: Text(isOpeningCv ? 'ABRIENDO CV...' : 'VER CV'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: lime,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.all(14),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                                side: BorderSide(color: Colors.black, width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget buildStatusSelector(String currentStatus, String companyId) {
    final normalizedStatus = statuses.contains(currentStatus) ? currentStatus : 'POSTULADO';

    return borderedPanel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ESTADO DEL PROCESO',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(normalizedStatus),
            initialValue: normalizedStatus,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            items: statuses.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: isSaving
                ? null
                : (value) {
                    if (value != null && value != normalizedStatus) {
                      updateStatus(companyId, value);
                    }
                  },
          ),
          if (isSaving) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(color: Colors.black),
          ],
          const SizedBox(height: 12),
          const Text(
            'Los cambios se sincronizan con la App Candidato.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debés iniciar sesión para continuar'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: lime,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'DETALLE DEL CANDIDATO',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .doc(widget.applicationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar la postulación:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          final application = snapshot.data!.data();

          if (application == null) {
            return const Center(
              child: Text('La postulación no existe.'),
            );
          }

          final companyId = application['companyId']?.toString() ?? '';

          if (companyId != user.uid) {
            return const Center(
              child: Text('No tenés acceso a esta postulación.'),
            );
          }

          final candidateId = application['userId']?.toString() ?? '';
          final status = application['status']?.toString() ?? 'POSTULADO';
          final companyName = application['company']?.toString() ?? 'EMPRESA';
          final roleName = application['role']?.toString() ?? 'PUESTO';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'INFORMACIÓN DE LA POSTULACIÓN',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                borderedPanel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      informationField('PUESTO', application['role']),
                      informationField('EMPRESA', application['company']),
                      informationField('ESTADO ACTUAL', status),
                    ],
                  ),
                ),
                sectionTitle('PERFIL DEL CANDIDATO'),
                buildCandidateProfile(candidateId),
                sectionTitle('CURRÍCULUM VITAE'),
                buildCvSection(candidateId),
                sectionTitle('GESTIONAR POSTULACIÓN'),
                buildStatusSelector(status, companyId),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showInterviewDialog(candidateId, companyName, roleName),
                    icon: const Icon(Icons.calendar_month, color: Colors.white),
                    label: const Text(
                      'PROGRAMAR ENTREVISTA',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.all(18),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}