
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

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

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  static const Color background = Color(0xFFF4F4F4);
  static const Color lime = Color(0xFFD4FF00);

  static const List<String> statuses = [
    'POSTULADO',
    'EN PROCESO',
    'ENTREVISTA',
    'OFERTA',
    'RECHAZADO',
  ];

  bool isSaving = false;

  Future<void> updateStatus(
    String companyId,
    String newStatus,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.uid != companyId || isSaving) {
      return;
    }

    setState(() => isSaving = true);

    try {
      final applicationRef = FirebaseFirestore.instance
          .collection('applications')
          .doc(widget.applicationId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final applicationSnapshot =
            await transaction.get(applicationRef);

        if (!applicationSnapshot.exists) {
          throw Exception('La postulación ya no existe.');
        }

        final application = applicationSnapshot.data();

        if (application?['companyId'] != user.uid) {
          throw Exception('No tenés permiso para modificar esta postulación.');
        }

        transaction.update(applicationRef, {
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado actualizado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar el estado: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
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

  Widget buildCandidateProfile(String candidateId) {
    if (candidateId.isEmpty) {
      return borderedPanel(
        const Text('No se encontró el identificador del candidato.'),
      );
    }

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
            child: CircularProgressIndicator(color: Colors.black),
          );
        }

        final profile = snapshot.data!.data();

        if (profile == null) {
          return borderedPanel(
            const Text('El candidato no tiene un perfil disponible.'),
          );
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

  Widget buildCvSection(
    Map<String, dynamic> application,
  ) {
    // Solo se acepta una referencia al CV asociada
    // específicamente a esta postulación.
    final cvUrl = application['cvUrl']?.toString().trim() ?? '';

    if (cvUrl.isEmpty) {
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
            Text(
              'El candidato todavía no adjuntó un CV '
              'a esta postulación.',
            ),
          ],
        ),
      );
    }

    return borderedPanel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.picture_as_pdf_outlined, size: 32),
          const SizedBox(height: 10),
          const Text(
            'CV ADJUNTO',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: cvUrl),
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Enlace del CV copiado al portapapeles',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('COPIAR ENLACE DEL CV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: lime,
              foregroundColor: Colors.black,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusSelector(
    String currentStatus,
    String companyId,
  ) {
    final normalizedStatus = statuses.contains(currentStatus)
        ? currentStatus
        : 'POSTULADO';

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
                borderSide: BorderSide(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
            items: statuses.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: isSaving
                ? null
                : (value) {
                    if (value != null &&
                        value != normalizedStatus) {
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

          final companyId =
              application['companyId']?.toString() ?? '';

          if (companyId != user.uid) {
            return const Center(
              child: Text(
                'No tenés acceso a esta postulación.',
              ),
            );
          }

          final candidateId =
              application['userId']?.toString() ?? '';

          final status =
              application['status']?.toString() ?? 'POSTULADO';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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

                sectionTitle('PERFIL DEL CANDIDATO'),

                buildCandidateProfile(candidateId),

                sectionTitle('CURRÍCULUM VITAE'),

                buildCvSection(application),

                sectionTitle('GESTIONAR POSTULACIÓN'),

                buildStatusSelector(status, companyId),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
