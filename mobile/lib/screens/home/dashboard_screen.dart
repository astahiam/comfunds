import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _healthData;
  List<dynamic> _projects = [];
  List<dynamic> _cooperatives = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        _apiService.getHealthCheck(),
        _apiService.getProjects(limit: 5),
        _apiService.getCooperatives(limit: 5),
      ]);

      setState(() {
        _healthData = results[0];
        _projects = results[1]['data'] ?? [];
        _cooperatives = results[2]['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ComFunds Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.logout();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome, ${authProvider.user?.name ?? 'User'}!',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        authProvider.user?.email ?? '',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // System health
                    if (_healthData != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.health_and_safety, color: AppColors.success),
                                  SizedBox(width: 8),
                                  Text(
                                    'System Status',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: AppColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${_healthData!['message']}'),
                                ],
                              ),
                              if (_healthData!['data'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Database Shards: ${_healthData!['data']['database_shards']} active',
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Recent projects
                    const Text(
                      'Recent Projects',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_projects.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No projects available'),
                        ),
                      )
                    else
                      ..._projects.take(3).map((project) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(Icons.business_center, color: Colors.white),
                          ),
                          title: Text(project['name'] ?? 'Unknown Project'),
                          subtitle: Text(project['description'] ?? 'No description'),
                          trailing: Text(
                            '\$${project['funding_goal'] ?? '0'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      )),
                    const SizedBox(height: 16),

                    // Recent cooperatives
                    const Text(
                      'Active Cooperatives',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_cooperatives.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No cooperatives available'),
                        ),
                      )
                    else
                      ..._cooperatives.take(3).map((coop) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.secondary,
                            child: Icon(Icons.group, color: Colors.white),
                          ),
                          title: Text(coop['name'] ?? 'Unknown Cooperative'),
                          subtitle: Text(coop['description'] ?? 'No description'),
                          trailing: Text(
                            '${coop['member_count'] ?? '0'} members',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )),

                    const SizedBox(height: 32),

                    // Quick actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () {
                                // Navigate to projects
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.business_center,
                                      size: 32,
                                      color: AppColors.primary,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Browse Projects',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Card(
                            child: InkWell(
                              onTap: () {
                                // Navigate to cooperatives
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.group,
                                      size: 32,
                                      color: AppColors.secondary,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Join Cooperative',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
