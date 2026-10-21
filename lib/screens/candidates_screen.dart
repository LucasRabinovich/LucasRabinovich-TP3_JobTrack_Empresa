
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'candidate_detail_screen.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  static const Color background = Color(0xFFF4F4F4);
  static const Color lime = Color(0xFFD4FF00);

  String? selectedOfferId;
  String selectedStatus = 'TODOS';

  final List<String> statuses = [
    'TODOS',
    'POSTULADO',
    'EN PROCESO',
    'ENTREVISTA',
    'OFERTA',
    'RECHAZADO',
  ];

  Widget buildStatus(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: status == 'RECHAZADO'
            ? const Color(0xFFFFD1D1)
            : lime,
        border: Border.all(
          color: Colors.black,
          width: 1.5,
        ),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget buildCandidateCard(
    QueryDocumentSnapshot<Map<String, dynamic>> application,
  ) {
    final data = application.data();

    final candidateId = data['userId']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'POSTULADO';
    final role = data['role']?.toString() ?? 'No especificado';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (candidateId.isNotEmpty)
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(candidateId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'CANDIDATO',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Text(
                    'CARGANDO CANDIDATO...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }

                final profile = snapshot.data!.data();

                final name =
                    profile?['name']?.toString().trim() ?? '';

                return Text(
                  name.isEmpty ? 'CANDIDATO' : name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                );
              },
            )
          else
            const Text(
              'CANDIDATO SIN IDENTIFICAR',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),

          const SizedBox(height: 10),

          Text(
            'PUESTO: $role',
            style: const TextStyle(
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 14),

          buildStatus(status),

          const SizedBox(height: 16),

          const Text(
            'POSTULACIÓN RECIBIDA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CandidateDetailScreen(
                      applicationId: application.id,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_search),
              label: const Text(
                'VER CANDIDATO',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.all(14),
                shape: const RoundedRectangleBorder(
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
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Iniciá sesión para continuar'),
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
          'CANDIDATOS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('job_offers')
            .where('companyId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, offersSnapshot) {
          if (offersSnapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar ofertas: ${offersSnapshot.error}',
              ),
            );
          }

          if (!offersSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            );
          }

          final offers = offersSnapshot.data!.docs;

          if (offers.isEmpty) {
            return const Center(
              child: Text(
                'TODAVÍA NO TENÉS OFERTAS PUBLICADAS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          }

          final validOfferIds =
              offers.map((offer) => offer.id).toSet();

          final currentOfferId =
              selectedOfferId != null &&
                      validOfferIds.contains(selectedOfferId)
                  ? selectedOfferId
                  : offers.first.id;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'POSTULACIONES RECIBIDAS',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Seleccioná una oferta para consultar '
                      'los candidatos que se postularon.',
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      key: ValueKey(currentOfferId),
                      initialValue: currentOfferId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                      ),
                      items: offers.map((offer) {
                        final title =
                            offer.data()['title']?.toString() ??
                                'Sin título';

                        return DropdownMenuItem<String>(
                          value: offer.id,
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedOfferId = value;
                          selectedStatus = 'TODOS';
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: statuses.map((status) {
                          final selected =
                              selectedStatus == status;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: selected,
                              selectedColor: lime,
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              labelStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  selectedStatus = status;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  key: ValueKey(currentOfferId),
                  stream: FirebaseFirestore.instance
                      .collection('applications')
                      .where(
                        'offerId',
                        isEqualTo: currentOfferId,
                      )
                      .snapshots(),
                  builder: (context, applicationsSnapshot) {
                    if (applicationsSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No se pudieron cargar las postulaciones:\n'
                            '${applicationsSnapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (!applicationsSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.black,
                        ),
                      );
                    }

                    final applications =
                        applicationsSnapshot.data!.docs.where((doc) {
                      final data = doc.data();

                      if (data['companyId'] != user.uid) {
                        return false;
                      }

                      return selectedStatus == 'TODOS' ||
                          data['status'] == selectedStatus;
                    }).toList();

                    if (applications.isEmpty) {
                      return const Center(
                        child: Text(
                          'NO HAY POSTULACIONES PARA ESTE FILTRO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        24,
                      ),
                      itemCount: applications.length,
                      itemBuilder: (context, index) {
                        return buildCandidateCard(
                          applications[index],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

