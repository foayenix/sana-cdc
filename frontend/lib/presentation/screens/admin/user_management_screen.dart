import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/models/admin.dart';
import '../../../core/constants/app_constants.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedRole;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(usersProvider.notifier).loadUsers();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    final usersState = ref.read(usersProvider);
    if (usersState.users.length >= usersState.total) return;

    setState(() => _isLoadingMore = true);
    await ref.read(usersProvider.notifier).loadUsers(
          role: _selectedRole,
          search: _searchController.text.isEmpty ? null : _searchController.text,
          offset: usersState.users.length,
        );
    setState(() => _isLoadingMore = false);
  }

  void _performSearch() {
    ref.read(usersProvider.notifier).loadUsers(
          role: _selectedRole,
          search: _searchController.text.isEmpty ? null : _searchController.text,
        );
  }

  void _filterByRole(String? role) {
    setState(() => _selectedRole = role);
    ref.read(usersProvider.notifier).loadUsers(
          role: role,
          search: _searchController.text.isEmpty ? null : _searchController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(usersProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildRoleFilter(),
          if (usersState.isLoading && usersState.users.isEmpty)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (usersState.error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${usersState.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(usersProvider.notifier).refresh();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.read(usersProvider.notifier).refresh();
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: usersState.users.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == usersState.users.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final user = usersState.users[index];
                    return _buildUserCard(user);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSubmitted: (_) => _performSearch(),
      ),
    );
  }

  Widget _buildRoleFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text('Filter by role: '),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('All'),
              selected: _selectedRole == null,
              onSelected: (_) => _filterByRole(null),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Clients'),
              selected: _selectedRole == AppConstants.roleClient,
              onSelected: (_) => _filterByRole(AppConstants.roleClient),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Practitioners'),
              selected: _selectedRole == AppConstants.rolePractitioner,
              onSelected: (_) => _filterByRole(AppConstants.rolePractitioner),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Admins'),
              selected: _selectedRole == AppConstants.roleAdmin,
              onSelected: (_) => _filterByRole(AppConstants.roleAdmin),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Text(
            user.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    user.role,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: user.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          _showUserDetails(user);
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'CLIENT':
        return Colors.blue;
      case 'PRACTITIONER':
        return Colors.green;
      case 'ADMIN':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showUserDetails(AdminUser user) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'User Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailRow('Name', user.name),
                    _buildDetailRow('Email', user.email),
                    _buildDetailRow('Role', user.role),
                    _buildDetailRow(
                      'Status',
                      user.isActive ? 'Active' : 'Inactive',
                    ),
                    _buildDetailRow(
                      'Created',
                      user.createdAt.toString().substring(0, 10),
                    ),
                    if (user.lastLoginAt != null)
                      _buildDetailRow(
                        'Last Login',
                        user.lastLoginAt.toString().substring(0, 16),
                      ),
                    if (user.clientProfile != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Client Profile',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(),
                      if (user.clientProfile!.phone != null)
                        _buildDetailRow('Phone', user.clientProfile!.phone!),
                      if (user.clientProfile!.address != null)
                        _buildDetailRow('Address', user.clientProfile!.address!),
                      if (user.clientProfile!.primaryConcerns != null &&
                          user.clientProfile!.primaryConcerns!.isNotEmpty)
                        _buildDetailRow(
                          'Primary Concerns',
                          user.clientProfile!.primaryConcerns!.join(', '),
                        ),
                    ],
                    if (user.practitionerProfile != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Practitioner Profile',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(),
                      if (user.practitionerProfile!.bio != null)
                        _buildDetailRow('Bio', user.practitionerProfile!.bio!),
                      if (user.practitionerProfile!.specialties != null &&
                          user.practitionerProfile!.specialties!.isNotEmpty)
                        _buildDetailRow(
                          'Specialties',
                          user.practitionerProfile!.specialties!.join(', '),
                        ),
                      _buildDetailRow(
                        'Verification Status',
                        user.practitionerProfile!.verificationStatus,
                      ),
                      if (user.practitionerProfile!.rating != null)
                        _buildDetailRow(
                          'Rating',
                          '${user.practitionerProfile!.rating} (${user.practitionerProfile!.reviewCount} reviews)',
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
