
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'my_company_screen.dart';
import 'create_offer_screen.dart';

class MyOffersScreen extends StatelessWidget {
  const MyOffersScreen({super.key});

  static const Color lime = Color(0xFFD4FF00);
  static const Color background = Color(0xFFF4F4F4);

  Future<void> _changeOfferStatus(
    BuildContext context,
    String offerId,
    bool isActive,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Colors.black, width: 2),
        ),
        title: Text(
          isActive ? 'CERRAR OFERTA' : 'REABRIR OFERTA',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          isActive
              ? 'La oferta dejará de aparecer entre las ofertas '
                  'disponibles para candidatos. Las postulaciones '
                  'recibidas se conservarán.'
              : 'La oferta volverá a estar disponible '
                  'para nuevas postulaciones.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.black : lime,
              foregroundColor:
                  isActive ? Colors.white : Colors.black,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              isActive ? 'CERRAR' : 'REABRIR',
            ),
          ),
        ],
      ),
    );

    if (shouldChange != true || !context.mounted) return;

    try {
      final offerRef = FirebaseFirestore.instance
          .collection('job_offers')
          .doc(offerId);

      final offerSnapshot = await offerRef.get();

      if (!offerSnapshot.exists ||
          offerSnapshot.data()?['companyId'] != user.uid) {
        throw Exception('La oferta no pertenece a esta empresa.');
      }

      await offerRef.update({
        'isActive': !isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'Oferta cerrada correctamente'
                : 'Oferta reabierta correctamente',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar la oferta: $e'),
        ),
      );
    }
  }

  Widget _buildTag(String text) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOfferCard(
    BuildContext context,
    String offerId,
    Map<String, dynamic> offer,
  ) {
    final isActive = offer['isActive'] == true;

    final title =
        offer['title']?.toString() ?? 'SIN TÍTULO';

    final seniority =
        offer['seniority']?.toString() ?? 'No especificado';

    final modality =
        offer['modality']?.toString() ?? '';

    final contract =
        offer['contractType']?.toString() ?? '';

    final description =
        offer['description']?.toString() ?? '';

    final salary =
        offer['salaryRange']?.toString() ?? 'No especificado';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Editar oferta',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateOfferScreen(
                        offerId: offerId,
                        existingOffer: offer,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: isActive ? lime : Colors.black,
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
            child: Text(
              isActive ? 'OFERTA ACTIVA' : 'OFERTA CERRADA',
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            seniority.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(modality),
              _buildTag(contract),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          const Divider(
            color: Colors.black,
            thickness: 1,
          ),

          const SizedBox(height: 8),

          Text(
            'SALARIO: $salary',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),

          const SizedBox(height: 16),

          StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('applications')
                .where('offerId', isEqualTo: offerId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'No se pudo consultar el número de postulantes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Text(
                  'Cargando postulantes...',
                  style: TextStyle(fontSize: 12),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: lime,
                  border: Border.all(
                    color: Colors.black,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '${snapshot.data!.docs.length} POSTULANTES',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _changeOfferStatus(
                context,
                offerId,
                isActive,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isActive ? Colors.black : lime,
                foregroundColor:
                    isActive ? Colors.white : Colors.black,
                padding: const EdgeInsets.all(16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
              ),
              icon: Icon(
                isActive
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined,
              ),
              label: Text(
                isActive ? 'CERRAR OFERTA' : 'REABRIR OFERTA',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: background,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              ),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const MyCompanyScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'INICIO',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted),
            label: 'OFERTAS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'CANDIDATOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.domain),
            label: 'PERFIL',
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
          child: Text('Debés iniciar sesión'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'MIS AVISOS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            color: Colors.black,
            height: 2,
          ),
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('job_offers')
            .where('companyId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: SelectableText(
                'Error al cargar ofertas:\n${snapshot.error}',
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

          final docs = snapshot.data!.docs.toList();

          docs.sort((a, b) {
            final aDate =
                a.data()['createdAt'] as Timestamp?;
            final bDate =
                b.data()['createdAt'] as Timestamp?;

            return (bDate?.toDate() ?? DateTime(1970))
                .compareTo(
              aDate?.toDate() ?? DateTime(1970),
            );
          });

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'AÚN NO PUBLICASTE OFERTAS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CreateOfferScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'CREAR MI PRIMERA OFERTA',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final document = docs[index];

              return _buildOfferCard(
                context,
                document.id,
                document.data(),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }
}
