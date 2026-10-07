import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_track/screens/new_application_screen.dart';
import 'package:job_track/screens/application_detail_screen.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'TODOS';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectStatus(String status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
          'POSTULACIONES',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'MIS POSTULACIONES',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Consulta y organiza tus procesos laborales.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 24),

            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const NewApplicationScreen(),
                  ),
                );

                if (mounted) {
                  setState(() {});
                }
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4FF00),
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
                child: const Center(
                  child: Text(
                    '+ NUEVA POSTULACIÓN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                hintText: 'Buscar empresa o puesto...',
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.black,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: brutalistBorder,
                focusedBorder: brutalistBorder,
                contentPadding: EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterButton('TODOS'),
                _buildFilterButton('POSTULADO'),
                _buildFilterButton('EN PROCESO'),
                _buildFilterButton('ENTREVISTA'),
                _buildFilterButton('OFERTA'),
                _buildFilterButton('RECHAZADO'),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: user == null
                  ? const Center(
                      child: Text(
                        'NO HAY USUARIO AUTENTICADO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('applications')
                          .where(
                            'userId',
                            isEqualTo: user.uid,
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'ERROR AL CARGAR POSTULACIONES',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        final search = _searchController.text
                            .trim()
                            .toLowerCase();

                        final filteredDocs = docs.where((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;

                          final company =
                              (data['company'] ?? '')
                                  .toString()
                                  .toLowerCase();

                          final role =
                              (data['role'] ?? '')
                                  .toString()
                                  .toLowerCase();

                          final status =
                              (data['status'] ?? '')
                                  .toString();

                          final matchesSearch =
                              company.contains(search) ||
                              role.contains(search);

                          final matchesStatus =
                              _selectedStatus == 'TODOS' ||
                              status == _selectedStatus;

                          return matchesSearch &&
                              matchesStatus;
                        }).toList();

                        if (filteredDocs.isEmpty) {
                          return const Center(
                            child: Text(
                              'NO SE ENCONTRARON POSTULACIONES',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final document =
                                filteredDocs[index];

                            final data = document.data()
                                as Map<String, dynamic>;

                            return _buildApplicationCard(
                              applicationId: document.id,
                              applicationData: data,
                              company:
                                  data['company']?.toString() ??
                                  'Sin empresa',
                              role:
                                  data['role']?.toString() ??
                                  'Sin puesto',
                              status:
                                  data['status']?.toString() ??
                                  'SIN ESTADO',
                              modality:
                                  data['modality']?.toString() ??
                                  '',
                              salary:
                                  data['salary']?.toString() ??
                                  '',
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String status) {
    final bool selected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        _selectStatus(status);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD4FF00)
              : Colors.white,
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
        ),
        child: Text(
          status,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard({
    required String applicationId,
    required Map<String, dynamic> applicationData,
    required String company,
    required String role,
    required String status,
    required String modality,
    required String salary,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ApplicationDetailScreen(
              applicationId: applicationId,
              applicationData: applicationData,
            ),
          ),
        );
      },
      child: Container(
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
            Text(
              company,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              role,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),

            if (modality.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Modalidad: $modality',
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
            ],

            if (salary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Salario: $salary',
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
            ],

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4FF00),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const Icon(
                  Icons.arrow_forward,
                  color: Colors.black,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}