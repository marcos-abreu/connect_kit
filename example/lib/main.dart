import 'package:flutter/material.dart';
import 'package:connect_kit/connect_kit.dart';
import 'permission_demo_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConnectKit Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ConnectKit _connectKit = ConnectKit.instance;
  String _sdkStatus = 'Checking...';
  String _sdkResponseTime = '';
  bool _isLoading = false;
  List<String> _permissionResults = [];

  @override
  void initState() {
    super.initState();
    _checkSdkAvailability();
  }

  Future<void> _checkSdkAvailability() async {
    final stopwatch = Stopwatch()..start();

    setState(() {
      _sdkStatus = 'Checking...';
      _sdkResponseTime = '';
    });

    try {
      final status = await _connectKit.isSdkAvailable();
      stopwatch.stop();

      setState(() {
        _sdkStatus = status.name;
        _sdkResponseTime = '${stopwatch.elapsedMilliseconds}ms';
      });
    } catch (e) {
      stopwatch.stop();

      setState(() {
        _sdkStatus = 'Error: ${e.toString()}';
        _sdkResponseTime = '${stopwatch.elapsedMilliseconds}ms';
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _permissionResults.clear();
    });

    try {
      final result = await _connectKit.requestPermissions(
        readTypes: {CKType.steps, CKType.heartRate, CKType.weight},
        writeTypes: {CKType.steps, CKType.weight},
        forHistory: true,
      );

      if (result) {
        final permissions = await _connectKit.checkPermissions(
          forData: {
            CKType.steps: {CKAccessType.read, CKAccessType.write},
            CKType.heartRate: {CKAccessType.read},
            CKType.weight: {CKAccessType.read, CKAccessType.write}
          },
          forHistory: true,
        );

        setState(() {
          for (final type in permissions.checkedTypes) {
            final readStatus = permissions.getStatus(type, CKAccessType.read);
            final writeStatus = permissions.getStatus(type, CKAccessType.write);

            _permissionResults.add(
              '${type.displayName}: Read=${readStatus.name}, Write=${writeStatus.name}'
            );
          }
        });
      } else {
        setState(() {
          _permissionResults.add('Permission request was cancelled or failed');
        });
      }
    } catch (e) {
      setState(() {
        _permissionResults.add('Error: ${e.toString()}');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon/logo placeholder
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App title
                    const Text(
                      'ConnectKit',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    const Text(
                      'Cross-platform health and fitness data access',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SDK Status section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _sdkStatus == 'available' ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SDK Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _sdkStatus,
                        style: TextStyle(
                          color: _sdkStatus == 'available' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_sdkResponseTime.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          _sdkResponseTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _checkSdkAvailability,
                        borderRadius: BorderRadius.circular(20),
                        splashColor: Colors.blue.withOpacity(0.3),
                        highlightColor: Colors.blue.withOpacity(0.1),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.refresh,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SDK Functionality Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'isSdkAvailable:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.only(left: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• On iOS, it checks if HealthKit is available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• On Android, it checks if Health Connect is available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Quadrant with four options
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  // Permissions button
                  ElevatedButton(
                    onPressed: _sdkStatus == 'available' ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PermissionDemoScreen(),
                        ),
                      );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security,
                          size: 32,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Permissions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        ],
                    ),
                  ),

                  // Write Data button
                  ElevatedButton(
                    onPressed: _sdkStatus == 'available' ? () {
                      // TODO: Implement write data functionality
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload,
                          size: 32,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Write Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Read Data button
                  ElevatedButton(
                    onPressed: _sdkStatus == 'available' ? () {
                      // TODO: Implement read data functionality
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download,
                          size: 32,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Read Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Delete Data button
                  ElevatedButton(
                    onPressed: _sdkStatus == 'available' ? () {
                      // TODO: Implement delete data functionality
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete,
                          size: 32,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Delete Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Results section
              if (_permissionResults.isNotEmpty)
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Permission Results:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _permissionResults.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  _permissionResults[index],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
