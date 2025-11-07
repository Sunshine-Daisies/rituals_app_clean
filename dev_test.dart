import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/supabase_service.dart';
import 'lib/services/rituals_service.dart';
import 'lib/services/ritual_logs_service.dart';
import 'lib/services/devices_service.dart';
import 'lib/services/llm_usage_service.dart';

/// Manual test file for Supabase CRUD services
/// Run with: flutter run dev_test.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded');
  } catch (e) {
    print('❌ Failed to load .env file: $e');
    return;
  }
  
  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    print('✅ Supabase initialized');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
    return;
  }

  runApp(const CrudTestApp());
}

class CrudTestApp extends StatelessWidget {
  const CrudTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD Services Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestHomePage(),
    );
  }
}

class TestHomePage extends StatefulWidget {
  const TestHomePage({super.key});

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  final List<String> _testResults = [];
  bool _isRunning = false;
  bool _isAuthenticated = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _addResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toIso8601String()}: $result');
    });
  }

  Future<void> _signIn() async {
    try {
      _addResult('🔐 Attempting to sign in...');
      
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        setState(() {
          _isAuthenticated = true;
        });
        _addResult('✅ Successfully signed in as: ${response.user!.email}');
      } else {
        _addResult('❌ Sign in failed: No user returned');
      }
    } catch (e) {
      _addResult('❌ Sign in error: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      setState(() {
        _isAuthenticated = false;
        _testResults.clear();
      });
      _addResult('✅ Successfully signed out');
    } catch (e) {
      _addResult('❌ Sign out error: $e');
    }
  }

  Future<void> _runAllTests() async {
    if (_isRunning || !_isAuthenticated) return;
    
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    _addResult('🚀 Starting CRUD Services Tests...');

    // Test each service
    await _testRitualsService();
    await _testRitualLogsService();
    await _testDevicesService();
    await _testLlmUsageService();

    _addResult('✅ All tests completed!');
    
    setState(() {
      _isRunning = false;
    });
  }

  String _getCurrentUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id ?? 'unknown-user';
  }

  Future<void> _testRitualsService() async {
    _addResult('📋 Testing RitualsService...');
    
    try {
      // Test createRitual with correct day format
      final ritual = await RitualsService.createRitual(
        name: 'qweqwe',
        steps: [
          {'title': 'Wake up', 'duration': 1},
          {'title': 'Drink water', 'duration': 2},
        ],
        reminderTime: '07:00',
        reminderDays: ['Mon', 'Tue', 'Wed'], // Correct format: Mon, Tue, Wed, Thu, Fri, Sat, Sun
        timezone: 'Europe/Istanbul',
      );
      
      if (ritual != null) {
        _addResult('✅ RitualsService.createRitual - SUCCESS');
        
        try {
          // Test updateRitual
          final updatedRitual = await RitualsService.updateRitual(
            id: ritual.id,
            name: 'asd',
          );
          
          if (updatedRitual != null) {
            _addResult('✅ RitualsService.updateRitual - SUCCESS');
          }
          
          // Test getRituals
          final rituals = await RitualsService.getRituals(_getCurrentUserId());
          _addResult('✅ RitualsService.getRituals - Found ${rituals.length} rituals');
          
          // Test archiveRitual
          await RitualsService.archiveRitual(ritual.id);
          _addResult('✅ RitualsService.archiveRitual - SUCCESS');
          
        } catch (e) {
          _addResult('❌ RitualsService additional tests failed: $e');
        }
      } else {
        _addResult('❌ RitualsService.createRitual failed - No ritual returned');
      }
    } catch (e) {
      _addResult('❌ RitualsService test failed: $e');
    }
  }

  Future<void> _testRitualLogsService() async {
    _addResult('📋 Testing RitualLogsService...');
    
    try {
      // First get existing rituals to use a real ritual ID
      final rituals = await RitualsService.getRituals(_getCurrentUserId());
      
      if (rituals.isNotEmpty) {
        final ritualId = rituals.first.id;
        
        // Test logCompletion
        final log = await RitualLogsService.logCompletion(
          ritualId: ritualId,
          stepIndex: 0,
          source: 'manual',
        );
        
        if (log != null) {
          _addResult('✅ RitualLogsService.logCompletion - SUCCESS');
          
          // Test getLogs
          final logs = await RitualLogsService.getLogs(ritualId);
          _addResult('✅ RitualLogsService.getLogs - Found ${logs.length} logs');
        }
      } else {
        _addResult('⚠️ RitualLogsService test skipped - No rituals found to test with');
      }
    } catch (e) {
      _addResult('❌ RitualLogsService test failed: $e');
    }
  }

  Future<void> _testDevicesService() async {
    _addResult('📋 Testing DevicesService...');
    
    try {
      // Test registerDevice
      final device = await DevicesService.registerDevice(
        profileId: _getCurrentUserId(),
        deviceToken: 'test-device-token-${DateTime.now().millisecondsSinceEpoch}',
        platform: 'android',
        appVersion: '1.0.0',
        locale: 'tr',
      );
      
      if (device != null) {
        _addResult('✅ DevicesService.registerDevice - SUCCESS');
        
        // Test updateLastSeen
        await DevicesService.updateLastSeen(device.id);
        _addResult('✅ DevicesService.updateLastSeen - SUCCESS');
      }
    } catch (e) {
      _addResult('❌ DevicesService test failed: $e');
    }
  }

  Future<void> _testLlmUsageService() async {
    _addResult('📋 Testing LlmUsageService...');
    
    try {
      final userId = _getCurrentUserId();
      final sessionId = 'test-session-${DateTime.now().millisecondsSinceEpoch}';
      
      _addResult('🔍 Attempting to log usage with userId: $userId, sessionId: $sessionId');
      
      // Test logUsage
      final usage = await LlmUsageService.logUsage(
        userId: userId,
        model: 'gpt-3.5-turbo',
        tokensIn: 100,
        tokensOut: 50,
        sessionId: sessionId,
        intent: 'chat',
        promptType: 'user',
      );
      
      if (usage != null) {
        _addResult('✅ LlmUsageService.logUsage - SUCCESS');
        
        // Test getUsage
        final usageList = await LlmUsageService.getUsage(_getCurrentUserId());
        _addResult('✅ LlmUsageService.getUsage - Found ${usageList.length} usage records');
      }
    } catch (e) {
      _addResult('❌ LlmUsageService test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase CRUD Services Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: _isAuthenticated ? [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ] : null,
      ),
      body: Column(
        children: [
          if (!_isAuthenticated) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Sign In to Test Services',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _signIn,
                        child: const Text('Sign In'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRunning ? null : _runAllTests,
                  child: _isRunning 
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Running Tests...'),
                          ],
                        )
                      : const Text('Run All CRUD Tests'),
                ),
              ),
            ),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final result = _testResults[index];
                final isError = result.contains('❌');
                final isSuccess = result.contains('✅');
                
                return Card(
                  color: isError 
                      ? Colors.red.shade50 
                      : isSuccess 
                          ? Colors.green.shade50 
                          : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      result,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: isError 
                            ? Colors.red.shade700 
                            : isSuccess 
                                ? Colors.green.shade700 
                                : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}