import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'export_dialog.dart';
import 'import_dialog.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surfaceDark,
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentPurple.withValues(alpha: 0.35),
                  AppTheme.surfaceDark,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/icon/play_store_512.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppTheme.accentPurple,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Expense Tracker',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Offline Personal Ledger',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                ),
              ],
            ),
          ),

          // Drawer Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              children: [
                _buildDrawerItem(
                  icon: Icons.history_rounded,
                  title: 'Transaction History',
                  subtitle: 'Search, filter & daily summary',
                  color: Colors.blueAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HistoryScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.donut_large_rounded,
                  title: 'Spending Analytics',
                  subtitle: 'Interactive charts & category shares',
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.track_changes_rounded,
                  title: 'Category Budgets',
                  subtitle: 'Monthly limits & warning alerts',
                  color: Colors.amberAccent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BudgetScreen()),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
                  child: Divider(color: Colors.white10),
                ),
                _buildDrawerItem(
                  icon: Icons.file_download_outlined,
                  title: 'Export Statement',
                  subtitle: 'PDF, Excel (.xlsx) & CSV',
                  color: Colors.tealAccent,
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => const ExportDialog(),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.file_upload_outlined,
                  title: 'Import Previous Data',
                  subtitle: 'Restore from CSV, Excel, or JSON',
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => const ImportDialog(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Drawer Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Currency: BDT (৳)',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    String versionDisplay = 'v1.0.0+1';
                    if (snapshot.hasData) {
                      final info = snapshot.data!;
                      versionDisplay = info.buildNumber.isNotEmpty
                          ? 'v${info.version}+${info.buildNumber}'
                          : 'v${info.version}';
                    }
                    return Text(
                      versionDisplay,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white24),
      ),
    );
  }
}
