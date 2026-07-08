import 'package:flutter/material.dart';
import '../db_helper.dart';
import 'index.dart';

class HistoryPage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HistoryPage({super.key, required this.userData});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _requestsFuture = DatabaseHelper.instance.fetchRequests(
      widget.userData['id'],
      widget.userData['role'] ?? 'Patient',
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed': return const Color(0xFF10B981);
      case 'In Progress': return const Color(0xFF2563EB);
      case 'Pending Review': return const Color(0xFFF59E0B);
      default: return const Color(0xFF64748B);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Completed': return Icons.check_circle_rounded;
      case 'In Progress': return Icons.sync_rounded;
      case 'Pending Review': return Icons.hourglass_empty_rounded;
      default: return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDoctor = widget.userData['role'] == 'Doctor';

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
        }

        final allRequests = snapshot.data ?? [];
        final requests = _searchQuery.isEmpty
            ? allRequests
            : allRequests.where((r) =>
                (r['body_part']?.toString().toLowerCase() ?? '').contains(_searchQuery.toLowerCase())).toList();

        return Column(
          children: [
            // Search bar for doctors
            if (isDoctor && allRequests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by X-Ray name...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),

            Expanded(
              child: allRequests.isEmpty
                  ? _EmptyState(isDark: isDark)
                  : requests.isEmpty
                      ? Center(
                          child: Text(
                            'No results for "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: requests.length,
                          itemBuilder: (_, i) => _RequestCard(
                            request: requests[i],
                            isDark: isDark,
                            statusColor: _statusColor(requests[i]['status'] ?? ''),
                            statusIcon: _statusIcon(requests[i]['status'] ?? ''),
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2538) : const Color(0xFFF8FAFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 56,
              color: isDark ? const Color(0xFF2D3748) : const Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No History Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your X-Ray reports will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  final bool isDark;
  final Color statusColor;
  final IconData statusIcon;

  const _RequestCard({
    required this.request,
    required this.isDark,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ReportDetailPage(request: r),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _hovering
                ? (widget.isDark ? const Color(0xFF1E2D40) : const Color(0xFFF0F7FF))
                : (widget.isDark ? const Color(0xFF1E2538) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovering
                  ? const Color(0xFF2563EB).withOpacity(0.3)
                  : (widget.isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9)),
            ),
          ),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.statusIcon, color: widget.statusColor, size: 20),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${r['body_part'] ?? 'Unknown'} X-Ray',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 13, color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          r['patient_name'] ?? '—',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today_rounded, size: 13, color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          r['date'] ?? '—',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.statusColor.withOpacity(0.25)),
                ),
                child: Text(
                  r['status'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: widget.isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
