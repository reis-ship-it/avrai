import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class SupabaseIntegrationExample extends StatefulWidget {
  const SupabaseIntegrationExample({super.key});

  @override
  State<SupabaseIntegrationExample> createState() => _SupabaseIntegrationExampleState();
}

class _SupabaseIntegrationExampleState extends State<SupabaseIntegrationExample> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      final response = await _supabase.from('users').select('*').limit(1);
      setState(() {
        _status = '✅ Connected! Found ${response.length} users';
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Connection failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestUser() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating test user...';
    });

    try {
      final newUser = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': 'Test User ${DateTime.now().second}',
        'created_at': DateTime.now().toIso8601String(),
      };
      await _supabase.from('users').insert(newUser);
      setState(() {
        _status = '✅ Test user created!';
        _isLoading = false;
      });
      await _loadUsers();
    } catch (e) {
      setState(() {
        _status = '❌ Failed to create user: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final response = await _supabase.from('users').select('*').order('created_at', ascending: false);
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      setState(() {
        _status = '❌ Failed to load users: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Integration Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connection Status', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_status),
                    const SizedBox(height: 16),
                    Row(children: [
                      ElevatedButton(onPressed: _isLoading ? null : _testConnection, child: const Text('Test Connection')),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _isLoading ? null : _createTestUser, child: const Text('Create Test User')),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Users (${_users.length})', style: Theme.of(context).textTheme.titleLarge),
                      IconButton(onPressed: _loadUsers, icon: const Icon(Icons.refresh)),
                    ]),
                    if (_users.isEmpty)
                      const Padding(padding: EdgeInsets.all(16.0), child: Text('No users found. Create one to test!'))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            title: Text(user['name'] ?? 'Unknown'),
                            subtitle: Text('ID: ${user['id']}'),
                            trailing: Text(user['created_at'] != null ? DateTime.parse(user['created_at']).toString().substring(0, 19) : 'Unknown'),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Configuration', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('URL: ${SupabaseConfig.url}'),
                    const Text('Environment: ${SupabaseConfig.environment}'),
                    Text('Valid Config: ${SupabaseConfig.isValid ? '✅' : '❌'}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


