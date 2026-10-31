// ─────────────────────────────────────────────────────────────────────────────
// lib/screens/institutions_screen.dart
//
// Step 1 of User Journey:
// Fetches institutions from GET /institutions (via local proxy) and lets the
// user tap one to begin the AIS consent flow.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/institution.dart';
import '../services/yapily_service.dart';
import '../widgets/institution_card.dart';
import 'auth_screen.dart';
import 'pfm_dashboard_screen.dart';

class InstitutionsScreen extends StatefulWidget {
  final YapilyService service;

  const InstitutionsScreen({super.key, required this.service});

  @override
  State<InstitutionsScreen> createState() => _InstitutionsScreenState();
}

class _InstitutionsScreenState extends State<InstitutionsScreen> {
  List<Institution> _institutions = [];
  String _searchQuery = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  Future<void> _loadInstitutions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.service.getInstitutions();
      // Sort sandbox banks (like Modelo Sandbox) to the top for convenience
      list.sort((a, b) {
        final aModelo = a.id.toLowerCase().contains('modelo') ? 0 : 1;
        final bModelo = b.id.toLowerCase().contains('modelo') ? 0 : 1;
        if (aModelo != bModelo) return aModelo.compareTo(bModelo);
        return a.name.compareTo(b.name);
      });
      if (!mounted) return;
      setState(() {
        _institutions = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showProxyConfigDialog() {
    final controller = TextEditingController(text: widget.service.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          'Proxy Server URL',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Android Emulator: http://10.0.2.2:4000/proxy\n'
              'iOS Simulator: http://localhost:4000/proxy',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D1117),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.service.customBaseUrl = controller.text.trim();
              Navigator.pop(ctx);
              _loadInstitutions();
            },
            child: const Text('Save & Reload'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _institutions.where((inst) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return inst.name.toLowerCase().contains(q) ||
          inst.id.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Your Bank (AISP)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Step 1 of 3 • GET /institutions',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PfmDashboardScreen(service: widget.service),
                ),
              );
            },
            icon: const Icon(
              Icons.pie_chart_rounded,
              color: Color(0xFF3FB950),
              size: 18,
            ),
            label: const Text(
              'PFM Dashboard',
              style: TextStyle(
                color: Color(0xFF3FB950),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Proxy URL Settings',
            icon: const Icon(Icons.settings_ethernet_rounded, color: Color(0xFF8B949E)),
            onPressed: _showProxyConfigDialog,
          ),
          IconButton(
            tooltip: 'Refresh institutions',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF58A6FF)),
            onPressed: _loadInstitutions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search institution (e.g. Modelo Sandbox)…',
                hintStyle: const TextStyle(color: Color(0xFF8B949E)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8B949E)),
                filled: true,
                fillColor: const Color(0xFF161B22),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF30363D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF30363D)),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Institution> filtered) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF58A6FF)),
            SizedBox(height: 14),
            Text(
              'Fetching institutions from Yapily sandbox…',
              style: TextStyle(color: Color(0xFF8B949E)),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFF85149), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Could not reach local proxy or Yapily API',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loadInstitutions,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No matching institutions found.',
          style: TextStyle(color: Color(0xFF8B949E)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final inst = filtered[index];
        return InstitutionCard(
          institution: inst,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AuthScreen(
                  institution: inst,
                  service: widget.service,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
