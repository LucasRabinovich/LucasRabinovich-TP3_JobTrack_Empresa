
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class CandidateDetailScreen extends StatefulWidget {
  final String applicationId;

  const CandidateDetailScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<CandidateDetailScreen> createState() =>
      _CandidateDetailScreenState();
}

class _CandidateDetailScreenState
    extends State<CandidateDetailScreen> {
  static const Color background = Color(0xFFF4F4F4);
  static const Color lime = Color(0xFFD4FF00);

  static const String supabaseUrl =
      'https://zdaldzotfyuivcrjcuzg.supabase.co';

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

  Future<void> openCv() async {
    if (isOpeningCv) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Iniciá sesión para ver el CV.');
      return;
    }

    setState(() {
      isOpeningCv = true;
    });

    try {
      final token = await user.getIdToken(true);

      if (token == null || token.isEmpty) {
        throw Exception(
          'No se pudo obtener la sesión de Firebase.',
        );
      }

      final response = await http.post(
        Uri.parse(
          '$supabaseUrl/functions/v1/obtener-cv-empresa',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'applicationId': widget.applicationId,
        }),
      ).timeout(
        const Duration(seconds: 25),
      );

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Respuesta inválida del servidor.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          decoded['error']?.toString() ??
              'Error ${response.statusCode}',
        );
      }

      final url = decoded['url'];

      if (url is! String || url.isEmpty) {
        throw Exception(
          'El servidor no devolvió un enlace al CV.',
        );
      }

      final uri = Uri.tryParse(url);

      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host !=
              'zdaldzotfyuivcrjcuzg.supabase.co' ||
          !uri.path.startsWith(
            '/storage/v1/object/sign/cvs/',
          )) {
        throw Exception(
          'El enlace recibido no es válido.',
        );
      }

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception(
          'No se pudo abrir el PDF.',
        );
      }
    } catch (e) {
      showMessage(
        'No se pudo abrir el CV: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpeningCv = false;
        });
      }
    }
  }

  Future<void> updateStatus(
    String companyId,
    String newStatus,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null ||
        user.uid != companyId ||
        isSaving) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final applicationRef =
          FirebaseFirestore.instance
              .collection('applications')
              .doc(widget.applicationId);

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final snapshot =
              await transaction.get(applicationRef);

          if (!snapshot.exists) {
            throw Exception(
              'La postulación ya no existe.',
            );
          }

          final application = snapshot.data();

          if (application?['companyId'] != user.uid) {
            throw Exception(
              'No tenés permiso para modificar esta postulación.',
            );
          }

          transaction.update(applicationRef, {
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        },
      );

      showMessage(
        'Estado actualizado correctamente',
      );
    } catch (e) {
      showMessage(
        'No se pudo actualizar el estado: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _showInterviewDialog(
    String candidateId,
    String fallbackCompany,
    String role,
  ) async {
    final dateController = TextEditingController();
    final linkController = TextEditingController();
    final notesController = TextEditingController();

    String modality = 'VIRTUAL';
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: background,
              shape: const RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
                borderRadius: BorderRadius.zero,
              ),
              title: const Text(
                'PROGRAMAR ENTREVISTA',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FECHA Y HORA (Ej: 25/10 - 14:30)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'MODALIDAD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: modality,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: 'VIRTUAL',
                            child: Text(
                              'VIRTUAL',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'PRESENCIAL',
                            child: Text(
                              'PRESENCIAL',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              modality = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      modality == 'VIRTUAL'
                          ? 'ENLACE (MEET/ZOOM)'
                          : 'DIRECCIÓN',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: linkController,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'NOTAS / INSTRUCCIONES (Opcional)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText:
                            'Ej: Preguntar por recepción, llevar DNI, etc.',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
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
                    backgroundColor: lime,
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (dateController.text
                              .trim()
                              .isEmpty) {
                            showMessage(
                              'Por favor ingresá la fecha y hora',
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            final currentUser =
                                FirebaseAuth.instance
                                    .currentUser;

                            if (currentUser == null) {
                              throw Exception(
                                'Sesión no disponible.',
                              );
                            }

                            final companyId =
                                currentUser.uid;

                            final companyDoc =
                                await FirebaseFirestore
                                    .instance
                                    .collection('users')
                                    .doc(companyId)
                                    .get();

                            final realCompanyName =
                                companyDoc.data()?['name']
                                        ?.toString() ??
                                    fallbackCompany;

                            await FirebaseFirestore
                                .instance
                                .collection('interviews')
                                .add({
                              'userId': candidateId,
                              'companyId': companyId,
                              'company': realCompanyName,
                              'position': role,
                              'dateString':
                                  dateController.text
                                      .trim(),
                              'modality': modality,
                              'link':
                                  linkController.text
                                      .trim(),
                              'notes':
                                  notesController.text
                                      .trim(),
                              'createdAt':
                                  FieldValue
                                      .serverTimestamp(),
                            });

                            await FirebaseFirestore
                                .instance
                                .collection('applications')
                                .doc(widget.applicationId)
                                .update({
                              'status': 'ENTREVISTA',
                              'updatedAt':
                                  FieldValue
                                      .serverTimestamp(),
                            });

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(dialogContext);

                            showMessage(
                              'ENTREVISTA PROGRAMADA CON ÉXITO',
                            );
                          } catch (e) {
                            showMessage(
                              'Error al programar la entrevista: $e',
                            );

                            if (dialogContext.mounted) {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                            }
                          }
                        },
                  child: Text(
                    isSubmitting
                        ? 'GUARDANDO...'
                        : 'CONFIRMAR',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    dateController.dispose();
    linkController.dispose();
    notesController.dispose();
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 22,
        bottom: 10,
      ),
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

  Widget informationField(
    String label,
    dynamic value,
  ) {
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
            style: const TextStyle(
              fontSize: 15,
            ),
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
      child: child,
    );
  }

  Widget buildCandidateProfile(
    String candidateId,
  ) {
    if (candidateId.isEmpty) {
      return borderedPanel(
        const Text(
          'No se encontró el identificador del candidato.',
        ),
      );
    }

    return FutureBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(candidateId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return borderedPanel(
            const Text(
              'No se pudo consultar el perfil del candidato.',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.black,
            ),
          );
        }

        final profile = snapshot.data!.data();

        if (profile == null) {
          return borderedPanel(
            const Text(
              'El candidato no tiene un perfil disponible.',
            ),
          );
        }

        return borderedPanel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              informationField(
                'NOMBRE',
                profile['name'],
              ),
              informationField(
                'EMAIL',
                profile['email'],
              ),
              informationField(
                'TELÉFONO',
                profile['phone'],
              ),
              informationField(
                'UBICACIÓN',
                profile['location'],
              ),
              informationField(
                'PROFESIÓN',
                profile['profession'],
              ),
              informationField(
                'BIOGRAFÍA',
                profile['bio'],
              ),
              informationField(
                'EXPERIENCIA',
                profile['experience'],
              ),
              informationField(
                'EDUCACIÓN',
                profile['education'],
              ),
              informationField(
                'HABILIDADES',
                profile['skills'],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildCvSection(
    Map<String, dynamic> application,
  ) {
    final candidateId =
        application['userId']?.toString() ?? '';

    final cvDocumentId =
        application['cvDocumentId']?.toString() ?? '';

    final cvName =
        application['cvName']?.toString() ??
            'Currículum PDF';

    final cvStorageType =
        application['cvStorageType']?.toString() ?? '';

    if (candidateId.isEmpty ||
        cvDocumentId.isEmpty ||
        cvStorageType != 'supabase') {
      return borderedPanel(
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.description_outlined,
              size: 32,
            ),
            SizedBox(height: 12),
            Text(
              'CV NO ASOCIADO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Esta postulación no tiene un CV '
              'del sistema actual asociado.',
            ),
          ],
        ),
      );
    }

    return FutureBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('documents')
          .doc(cvDocumentId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return borderedPanel(
            const Text(
              'No se pudo consultar el CV asociado '
              'a esta postulación.',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.black,
            ),
          );
        }

        final document = snapshot.data!.data();

        if (document == null ||
            document['userId'] != candidateId ||
            document['type'] != 'cv' ||
            document['storageType'] != 'supabase' ||
            document['storagePath'] !=
                '$candidateId/$cvDocumentId.pdf') {
          return borderedPanel(
            const Text(
              'El CV de esta postulación '
              'ya no está disponible.',
            ),
          );
        }

        final size =
            (document['size'] as num?)?.toInt() ?? 0;

        return borderedPanel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CV ASOCIADO A ESTA POSTULACIÓN',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cvName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${(size / 1024).toStringAsFixed(1)} KB',
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      isOpeningCv ? null : openCv,
                  icon: isOpeningCv
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_outlined,
                        ),
                  label: Text(
                    isOpeningCv
                        ? 'ABRIENDO CV...'
                        : 'VER CV',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lime,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(14),
                    shape:
                        const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildStatusSelector(
    String currentStatus,
    String companyId,
  ) {
    final normalizedStatus =
        statuses.contains(currentStatus)
            ? currentStatus
            : 'POSTULADO';

    return borderedPanel(
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ESTADO DEL PROCESO',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey(normalizedStatus),
            initialValue: normalizedStatus,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
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
                    if (value != null &&
                        value != normalizedStatus) {
                      updateStatus(
                        companyId,
                        value,
                      );
                    }
                  },
          ),
          if (isSaving) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              color: Colors.black,
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Los cambios se sincronizan '
            'con la App Candidato.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Debés iniciar sesión para continuar',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: lime,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'DETALLE DEL CANDIDATO',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .doc(widget.applicationId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar la postulación:\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            );
          }

          final application =
              snapshot.data!.data();

          if (application == null) {
            return const Center(
              child: Text(
                'La postulación no existe.',
              ),
            );
          }

          final companyId =
              application['companyId']
                      ?.toString() ??
                  '';

          if (companyId != user.uid) {
            return const Center(
              child: Text(
                'No tenés acceso a esta postulación.',
              ),
            );
          }

          final candidateId =
              application['userId']
                      ?.toString() ??
                  '';

          final status =
              application['status']
                      ?.toString() ??
                  'POSTULADO';

          final companyName =
              application['company']
                      ?.toString() ??
                  'EMPRESA';

          final roleName =
              application['role']
                      ?.toString() ??
                  'PUESTO';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'INFORMACIÓN DE LA POSTULACIÓN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                borderedPanel(
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      informationField(
                        'PUESTO',
                        application['role'],
                      ),
                      informationField(
                        'EMPRESA',
                        application['company'],
                      ),
                      informationField(
                        'ESTADO ACTUAL',
                        status,
                      ),
                    ],
                  ),
                ),
                sectionTitle(
                  'PERFIL DEL CANDIDATO',
                ),
                buildCandidateProfile(
                  candidateId,
                ),
                sectionTitle(
                  'CURRÍCULUM VITAE',
                ),
                buildCvSection(
                  application,
                ),
                sectionTitle(
                  'GESTIONAR POSTULACIÓN',
                ),
                buildStatusSelector(
                  status,
                  companyId,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showInterviewDialog(
                        candidateId,
                        companyName,
                        roleName,
                      );
                    },
                    icon: const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                    ),
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
                      shape:
                          const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
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

