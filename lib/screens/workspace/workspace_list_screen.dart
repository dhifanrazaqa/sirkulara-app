import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../services/workspace_service.dart';

class WorkspaceListScreen extends StatefulWidget {
  const WorkspaceListScreen({super.key});

  @override
  State<WorkspaceListScreen> createState() => _WorkspaceListScreenState();
}

class _WorkspaceListScreenState extends State<WorkspaceListScreen> {
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        context.read<WorkspaceService>().fetchAllWorkspaces(user.uid);
      }
    });
  }

  Future<void> _startManualWorkspace() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final workspaceService = context.read<WorkspaceService>();
    final nameController = TextEditingController(text: 'tas_sachet');
    final weightController = TextEditingController(text: '300');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Workspace Manual', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama produk'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Berat (gram)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D6940),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mulai'),
          ),
        ],
      ),
    );
    if (result != true) return;
    if (!mounted) return;
    await workspaceService.startWorkspace(
      user.uid,
      nameController.text.trim().isEmpty ? 'tas_sachet' : nameController.text.trim(),
      'sachet_multilayer',
      double.tryParse(weightController.text) ?? 300,
    );
    if (!mounted) return;
    Navigator.pushNamed(context, '/workspace-step');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              Color(0xFFCFEDA0),
              Color(0xFFFAFAF4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Sirkulara',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF404941),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Riwayat Workspace',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C19),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _startManualWorkspace,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add, color: Color(0xFF1A1C19), size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.close, color: Color(0xFF1A1C19), size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFilterChip('Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sedang Berjalan'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Selesai'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Workspace List
              Expanded(
                child: Consumer<WorkspaceService>(
                  builder: (context, workspaceService, _) {
                    if (workspaceService.isLoadingAll) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D6940)),
                        ),
                      );
                    }

                    final allWorkspaces = workspaceService.allWorkspaces;
                    
                    // Filter logic
                    final filteredWorkspaces = allWorkspaces.where((w) {
                      if (_selectedFilter == 'Semua') return true;
                      final status = w['status'] as String? ?? 'in_progress';
                      if (_selectedFilter == 'Sedang Berjalan') return status == 'in_progress';
                      if (_selectedFilter == 'Selesai') return status == 'completed';
                      return true;
                    }).toList();

                    if (filteredWorkspaces.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada proyek ${_selectedFilter != 'Semua' ? _selectedFilter.toLowerCase() : ''}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredWorkspaces.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final w = filteredWorkspaces[index];
                        final id = w['id'] as String;
                        final name = w['productName'] as String? ?? 'Produk Daur Ulang';
                        final material = w['materialType'] as String? ?? 'plastik';
                        final status = w['status'] as String? ?? 'in_progress';
                        
                        final startedAt = w['startedAt'] as Timestamp?;
                        final dateStr = startedAt != null 
                            ? DateFormat('dd MMM yyyy').format(startedAt.toDate())
                            : '-';

                        final stepsData = w['steps'] as List<dynamic>? ?? [];
                        final stepsCount = stepsData.length;
                        
                        int completedCount = 0;
                        for (final stepMap in stepsData) {
                          if (stepMap is Map && stepMap['isCompleted'] == true) {
                            completedCount++;
                          }
                        }

                        final bool isInProgress = status == 'in_progress';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1D6940).withValues(alpha: 0.05),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () async {
                                await workspaceService.loadWorkspaceAsActive(id);
                                if (!context.mounted) return;
                                if (isInProgress) {
                                  Navigator.pushNamed(context, '/workspace-step');
                                } else {
                                  Navigator.pushNamed(context, '/workspace-complete');
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Status icon
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: isInProgress 
                                            ? const Color(0xFFCBEA9D) 
                                            : const Color(0xFFF4F4EE),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isInProgress ? Icons.recycling : Icons.check_circle_outline,
                                        color: isInProgress 
                                            ? const Color(0xFF516A2C) 
                                            : const Color(0xFF1D6940),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Mid Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A1C19),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Bahan: ${_capitalize(material)} • Mulai: $dateStr',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF707A71),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Status Badge
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isInProgress 
                                                      ? const Color(0xFFFFF7E6) 
                                                      : const Color(0xFFE6F4EA),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  isInProgress ? 'Sedang Berjalan' : 'Selesai',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isInProgress 
                                                        ? const Color(0xFFD48800) 
                                                        : const Color(0xFF137333),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (isInProgress)
                                                Text(
                                                  'Langkah $completedCount/$stepsCount',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF404941),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Color(0xFF707A71)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D6940) : Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  )
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF404941),
          ),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}
