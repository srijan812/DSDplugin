import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trip.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onStartNewTrip;

  const DashboardScreen({super.key, required this.onStartNewTrip});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();

    return Stack(
      children: [
        Column(
          children: [
            // ── Blue Gradient Header ──────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.primaryBlueDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const _DashboardHeader(),
            ),

            // ── White content surface with rounded top ────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  children: [
                    _SearchBar(
                      query: vm.searchQuery,
                      onQueryChange: vm.onSearchQueryChange,
                    ),
                    const SizedBox(height: 32),
                    _ActionRow(
                      onStartNewTrip: () {
                        vm.startNewTrip();
                        onStartNewTrip();
                      },
                      onPending: vm.openPendingGRNs,
                      onCompleted: vm.openCompletedTrips,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Trips',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black.withOpacity(0.8),
                              ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: AppColors.primaryBlueMid,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...vm.filteredTrips
                        .map((trip) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _TripCard(trip: trip),
                            ))
                        .toList(),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Loading overlay ───────────────────────────────────────
        if (vm.isLoading)
          const ModalBarrier(color: Color(0x33000000), dismissible: false),
        if (vm.isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.menu, color: Colors.white, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'NeoICR',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Automated GRN processing',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xE5FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.notifications_none, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQueryChange;

  const _SearchBar({required this.query, required this.onQueryChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Icon(Icons.search, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onQueryChange,
              decoration: const InputDecoration(
                hintText: 'Search Trip',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Row
// ─────────────────────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final VoidCallback onStartNewTrip;
  final VoidCallback onPending;
  final VoidCallback onCompleted;

  const _ActionRow({
    required this.onStartNewTrip,
    required this.onPending,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionCard(
          title: 'Start a\nnew trip',
          icon: Icons.local_shipping_outlined,
          isPrimary: true,
          onClick: onStartNewTrip,
        ),
        _ActionCard(
          title: 'Pending\nGRN',
          icon: Icons.description_outlined,
          onClick: onPending,
        ),
        _ActionCard(
          title: 'Completed',
          icon: Icons.check_circle_outlined,
          onClick: onCompleted,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onClick;

  const _ActionCard({
    required this.title,
    required this.icon,
    this.isPrimary = false,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary
              ? Border.all(color: const Color(0x4D1E88E5))
              : null,
          boxShadow: isPrimary
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isPrimary ? AppColors.primaryBlueMid : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : Colors.grey,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trip Card
// ─────────────────────────────────────────────────────────────────────────────
class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final isCompleted = trip.status == TripStatus.completed;
    return Container(
      decoration: BoxDecoration(
        color: trip.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.1)
              : Colors.yellow.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inv: ${trip.invoiceNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xCC000000),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vendor: ${trip.vendorName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0x99000000),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.statusPassed : AppColors.statusPending,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              isCompleted ? 'Completed' : 'Pending',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
