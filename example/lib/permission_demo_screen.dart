import 'package:flutter/material.dart';
import 'package:connect_kit/connect_kit.dart';

class PermissionDemoScreen extends StatefulWidget {
  const PermissionDemoScreen({super.key});

  @override
  State<PermissionDemoScreen> createState() => _PermissionDemoScreenState();
}

enum _PermissionAction { request, check, revoke, settings }

class _PermissionDemoScreenState extends State<PermissionDemoScreen> {
  final ConnectKit _connectKit = ConnectKit.instance;

  _PermissionAction _selectedAction = _PermissionAction.request;
  Set<CKType> _selectedReadTypes = {};
  Set<CKType> _selectedWriteTypes = {};
  bool _requestHistory = false;
  bool _requestBackground = false;

  bool _isLoading = false;
  String _resultMessage = '';
  String _resultDuration = '';
  bool _showResultPanel = false;
  CKAccessStatus? _lastAccessStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ConnectKit',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Action Section
            _buildActionSection(),
            const SizedBox(height: 24),

            // Select Data Types Section (only for request and check)
            if (_selectedAction == _PermissionAction.request ||
                _selectedAction == _PermissionAction.check) ...[
              _buildDataTypesSection(),
              const SizedBox(height: 24),
            ],

            // Additional Options Section (only for request and check)
            if (_selectedAction == _PermissionAction.request ||
                _selectedAction == _PermissionAction.check) ...[
              _buildAdditionalOptionsSection(),
              const SizedBox(height: 24),
            ],

            // Code Snippet Section
            _buildCodeSnippetSection(),

            const SizedBox(height: 50), // Extra padding at bottom
          ],
        ),
      ),
      persistentFooterButtons: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed:
                _canExecuteAction() && !_isLoading ? _executeAction : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Processing...'),
                    ],
                  )
                : Text(
                    _getActionButtonText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return _buildSection(
      'Select Action',
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton('Request', _PermissionAction.request),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton('Check', _PermissionAction.check),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton('Revoke', _PermissionAction.revoke),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Settings',
                  _PermissionAction.settings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, _PermissionAction action) {
    final isSelected = _selectedAction == action;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedAction = action;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[600] : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDataTypesSection() {
    return _buildSection(
      'Select Data Types (CKTypes)',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Read Types
          Text(
            'Read Types',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildTypeButtons(_selectedReadTypes, (type, selected) {
            setState(() {
              if (selected) {
                _selectedReadTypes.add(type);
              } else {
                _selectedReadTypes.remove(type);
              }
            });
          }),

          const SizedBox(height: 20),

          // Write Types
          Text(
            'Write Types',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildTypeButtons(_selectedWriteTypes, (type, selected) {
            setState(() {
              if (selected) {
                _selectedWriteTypes.add(type);
              } else {
                _selectedWriteTypes.remove(type);
              }
            });
          }),
        ],
      ),
    );
  }

  Widget _buildTypeButtons(
    Set<CKType> selectedTypes,
    Function(CKType, bool) onToggle,
  ) {
    // Different types for read vs write sections
    final isReadSection = selectedTypes == _selectedReadTypes;
    final types = isReadSection
        ? [
            CKType.height,
            CKType.weight,
            CKType.steps,
            CKType.distance,
            CKType.heartRate,
          ]
        : [CKType.height, CKType.steps, CKType.distance, CKType.workout];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = selectedTypes.contains(type);
        return FilterChip(
          selected: isSelected,
          onSelected: (selected) => onToggle(type, selected),
          label: Text(type.displayName),
          backgroundColor: Colors.grey[100],
          selectedColor: Colors.blue[100],
          checkmarkColor: Colors.blue[600],
          labelStyle: TextStyle(
            color: isSelected ? Colors.blue[800] : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? Colors.blue[300]! : Colors.transparent,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdditionalOptionsSection() {
    return _buildSection(
      'Special Permissions',
      Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Checkbox(
                  value: _requestHistory,
                  onChanged: (value) {
                    setState(() {
                      _requestHistory = value ?? false;
                    });
                  },
                ),
                const Text('History'),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Checkbox(
                  value: _requestBackground,
                  onChanged: (value) {
                    setState(() {
                      _requestBackground = value ?? false;
                    });
                  },
                ),
                const Text('Background'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSnippetSection() {
    final codeSnippet = _generateCodeSnippet();

    return _buildSection(
      'Code Snippet',
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.4,
              ),
              children: _buildHighlightedCode(codeSnippet),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  bool _canExecuteAction() {
    switch (_selectedAction) {
      case _PermissionAction.request:
        return _selectedReadTypes.isNotEmpty ||
            _selectedWriteTypes.isNotEmpty ||
            _requestHistory ||
            _requestBackground;
      case _PermissionAction.check:
        return _selectedReadTypes.isNotEmpty ||
            _selectedWriteTypes.isNotEmpty ||
            _requestHistory ||
            _requestBackground;
      case _PermissionAction.revoke:
        return true; // revokePermissions doesn't require any parameters
      case _PermissionAction.settings:
        return true; // openHealthSettings doesn't require any parameters
    }
  }

  String _getActionButtonText() {
    switch (_selectedAction) {
      case _PermissionAction.request:
        return 'Request Permissions';
      case _PermissionAction.check:
        return 'Check Permissions';
      case _PermissionAction.revoke:
        return 'Revoke Permissions';
      case _PermissionAction.settings:
        return 'Open Settings';
    }
  }

  Future<void> _executeAction() async {
    final stopwatch = Stopwatch()..start();

    setState(() {
      _isLoading = true;
      _resultMessage = '';
      _resultDuration = '';
      _lastAccessStatus = null;
    });

    try {
      String result;

      switch (_selectedAction) {
        case _PermissionAction.request:
          final success = await _connectKit.requestPermissions(
            readTypes: _selectedReadTypes,
            writeTypes: _selectedWriteTypes,
            forHistory: _requestHistory,
            forBackground: _requestBackground,
          );
          result = 'Request ${success ? "successful" : "failed"}';
          break;

        case _PermissionAction.check:
          final forData = <CKType, Set<CKAccessType>>{};
          for (final type in _selectedReadTypes) {
            forData[type] = {CKAccessType.read};
          }
          for (final type in _selectedWriteTypes) {
            forData[type] = {CKAccessType.write};
          }

          _lastAccessStatus = await _connectKit.checkPermissions(
            forData: forData,
            forHistory: _requestHistory,
            forBackground: _requestBackground,
          );

          // Determine success based on permission status
          bool allGranted = true;
          bool anyDenied = false;

          // Check history access
          if (_requestHistory && _lastAccessStatus!.historyAccess.isDenied) {
            allGranted = false;
            anyDenied = true;
          }

          // Check background access
          if (_requestBackground &&
              _lastAccessStatus!.backgroundAccess.isDenied) {
            allGranted = false;
            anyDenied = true;
          }

          // Check data access
          for (final entry in _lastAccessStatus!.dataAccess.entries) {
            for (final accessEntry in entry.value.entries) {
              if (accessEntry.value.isDenied) {
                allGranted = false;
                anyDenied = true;
              } else if (accessEntry.value.isNotDetermined ||
                  accessEntry.value.isUnknown ||
                  accessEntry.value.isNotSupported) {
                allGranted = false;
              }
            }
          }

          if (allGranted) {
            result = 'All permissions granted';
          } else if (anyDenied) {
            result = 'Some permissions denied';
          } else {
            result = 'Some permissions limited';
          }
          break;

        case _PermissionAction.revoke:
          final success = await _connectKit.revokePermissions();
          result = 'Revoke ${success ? "successful" : "failed"}';
          break;

        case _PermissionAction.settings:
          final success = await _connectKit.openHealthSettings();
          result = 'Settings ${success ? "opened" : "failed to open"}';
          break;
      }

      stopwatch.stop();

      setState(() {
        _resultMessage = result;
        _resultDuration = '${stopwatch.elapsedMilliseconds}ms';
      });

      // Show result in modal bottom sheet
      _showResultModal(result, false);
    } catch (e) {
      stopwatch.stop();

      final errorMessage = 'Error: ${e.toString()}';
      setState(() {
        _resultMessage = errorMessage;
        _resultDuration = '${stopwatch.elapsedMilliseconds}ms';
      });

      // Show error in modal bottom sheet
      _showResultModal(errorMessage, true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showResultModal(String message, bool isError) {
    // Parse the result message to determine success type
    final isAllGranted = message.contains('successful') ||
        message.contains('All permissions granted');
    final isPartialGranted =
        message.contains('failed') || message.contains('Some permissions');
    final resultType =
        isError ? 'error' : (isAllGranted ? 'success' : 'partial');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Result content
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getResultBackgroundColor(resultType),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getResultBorderColor(resultType)),
              ),
              child: _selectedAction == _PermissionAction.check &&
                      _lastAccessStatus != null
                  ? _buildCheckPermissionsResult(resultType)
                  : _buildDefaultResultHeader(resultType),
            ),

            // CKAccessStatus details (only for checkPermissions) - REMOVED: now shown in main result box
            // if (_lastAccessStatus != null)
            //   Container(
            //     width: double.infinity,
            //     margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            //     padding: const EdgeInsets.all(16),
            //     decoration: BoxDecoration(
            //       color: Colors.blue[50],
            //       borderRadius: BorderRadius.circular(12),
            //       border: Border.all(color: Colors.blue[200]!),
            //     ),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           children: [
            //             Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
            //             const SizedBox(width: 8),
            //             Text(
            //               'Permission Status Details:',
            //               style: TextStyle(
            //                 fontWeight: FontWeight.w600,
            //                 color: Colors.blue[900],
            //                 fontSize: 16,
            //               ),
            //             ),
            //           ],
            //         ),
            //         const SizedBox(height: 12),
            //         // History access
            //         if (_requestHistory) ...[
            //           Padding(
            //             padding: const EdgeInsets.only(left: 28),
            //             child: RichText(
            //               text: TextSpan(
            //                 style: const TextStyle(
            //                   fontSize: 14,
            //                   color: Colors.black87,
            //                   height: 1.4,
            //                 ),
            //                 children: [
            //                   const TextSpan(
            //                     text: 'History Access: ',
            //                     style: TextStyle(fontWeight: FontWeight.w600),
            //                   ),
            //                   TextSpan(
            //                     text: _lastAccessStatus!.historyAccess.name,
            //                     style: TextStyle(
            //                       color: _lastAccessStatus!.historyAccess.isGranted
            //                           ? Colors.green[700]
            //                           : _lastAccessStatus!.historyAccess.isDenied
            //                               ? Colors.red[700]
            //                               : Colors.orange[700],
            //                       fontWeight: FontWeight.w500,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //           const SizedBox(height: 8),
            //         ],
            //         // Background access
            //         if (_requestBackground) ...[
            //           Padding(
            //             padding: const EdgeInsets.only(left: 28),
            //             child: RichText(
            //               text: TextSpan(
            //                 style: const TextStyle(
            //                   fontSize: 14,
            //                   color: Colors.black87,
            //                   height: 1.4,
            //                 ),
            //                 children: [
            //                   const TextSpan(
            //                     text: 'Background Access: ',
            //                     style: TextStyle(fontWeight: FontWeight.w600),
            //                   ),
            //                   TextSpan(
            //                     text: _lastAccessStatus!.backgroundAccess.name,
            //                     style: TextStyle(
            //                       color: _lastAccessStatus!.backgroundAccess.isGranted
            //                           ? Colors.green[700]
            //                           : _lastAccessStatus!.backgroundAccess.isDenied
            //                               ? Colors.red[700]
            //                               : Colors.orange[700],
            //                       fontWeight: FontWeight.w500,
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //           const SizedBox(height: 8),
            //         ],
            //         // Data access types
            //         if (_lastAccessStatus!.dataAccess.isNotEmpty) ...[
            //           const Padding(
            //             padding: EdgeInsets.only(left: 28, top: 8),
            //             child: Text(
            //               'Data Access:',
            //               style: TextStyle(
            //                 fontSize: 14,
            //                 fontWeight: FontWeight.w600,
            //                 color: Colors.black87,
            //               ),
            //             ),
            //           ),
            //           const SizedBox(height: 8),
            //           ..._lastAccessStatus!.dataAccess.entries.map((entry) {
            //             return Padding(
            //               padding: const EdgeInsets.only(left: 44, bottom: 4),
            //               child: Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   Text(
            //                     entry.key.displayName,
            //                     style: const TextStyle(
            //                       fontSize: 13,
            //                       fontWeight: FontWeight.w600,
            //                       color: Colors.black87,
            //                     ),
            //                   ),
            //                   const SizedBox(height: 2),
            //                   ...entry.value.entries.map((accessEntry) {
            //                     final status = accessEntry.value;
            //                     return Padding(
            //                       padding: const EdgeInsets.only(left: 16),
            //                       child: RichText(
            //                         text: TextSpan(
            //                           style: const TextStyle(
            //                             fontSize: 12,
            //                             color: Colors.black87,
            //                             height: 1.3,
            //                           ),
            //                           children: [
            //                             TextSpan(
            //                               text: '${accessEntry.key.name}: ',
            //                               style: const TextStyle(fontWeight: FontWeight.w500),
            //                             ),
            //                             TextSpan(
            //                               text: status.name,
            //                               style: TextStyle(
            //                                 color: status.isGranted
            //                                     ? Colors.green[600]
            //                                     : status.isDenied
            //                                         ? Colors.red[600]
            //                                         : Colors.orange[600],
            //                                 fontWeight: FontWeight.w600,
            //                               ),
            //                             ),
            //                           ],
            //                         ),
            //                       ),
            //                     );
            //                   }),
            //                 ],
            //               ),
            //             );
            //           }),
            //         ],
            //       ],
            //     ),
            //   ),
            // End of CKAccessStatus container (now commented out - moved to main result box)

            // Exception details (only for errors)
            if (isError)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontFamily: 'monospace',
                  ),
                ),
              ),

            // Platform explanation box
            _buildPlatformExplanationBox(resultType),

            // Close button (outside the result box)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getResultBackgroundColor(String resultType) {
    switch (resultType) {
      case 'success':
        return Colors.green[50]!;
      case 'partial':
        return Colors.grey[200]!;
      case 'error':
        return Colors.red[50]!;
      default:
        return Colors.grey[50]!;
    }
  }

  Color _getResultBorderColor(String resultType) {
    switch (resultType) {
      case 'success':
        return Colors.green[200]!;
      case 'partial':
        return Colors.grey[400]!;
      case 'error':
        return Colors.red[200]!;
      default:
        return Colors.grey[200]!;
    }
  }

  IconData _getResultIcon(String resultType) {
    switch (resultType) {
      case 'success':
        return Icons.check_circle;
      case 'partial':
        return Icons.remove_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getResultIconColor(String resultType) {
    switch (resultType) {
      case 'success':
        return Colors.green[600]!;
      case 'partial':
        return Colors.grey[600]!;
      case 'error':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getResultText(String resultType) {
    switch (resultType) {
      case 'success':
        if (_selectedAction == _PermissionAction.check) {
          return 'All permissions granted';
        } else if (_selectedAction == _PermissionAction.revoke) {
          return 'All types revoked';
        } else {
          return 'All requests granted';
        }
      case 'partial':
        return _selectedAction == _PermissionAction.check
            ? 'Some permissions limited/denied'
            : 'Not all requests granted';
      case 'error':
        return 'Error occurred';
      default:
        return 'Unknown result';
    }
  }

  Color _getResultTextColor(String resultType) {
    switch (resultType) {
      case 'success':
        return Colors.green[600]!;
      case 'partial':
        return Colors.grey[700]!;
      case 'error':
        return Colors.red[600]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Widget _buildPlatformExplanationBox(String resultType) {
    if (resultType == 'error') return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Platform Behavior:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: _buildPlatformSpecificInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSpecificInfo() {
    switch (_selectedAction) {
      case _PermissionAction.request:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [TextSpan(text: 'Android → ')],
                  ),
                  WidgetSpan(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: const Text(
                        'true',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' means all granted, while '),
                  WidgetSpan(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: const Text(
                        'false',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' means not all granted'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [TextSpan(text: 'iOS → ')],
                  ),
                  WidgetSpan(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: const Text(
                        'true',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' means dialog shown; '),
                  WidgetSpan(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: const Text(
                        'false',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' means issue shown dialog'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: Colors.blue[200],
              margin: const EdgeInsets.symmetric(horizontal: 28),
            ),
            const SizedBox(height: 16),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'History permission requires an accompanying data-type read permission to trigger the dialog.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'Background permission triggers with any accompanying data-type read or write permission.',
                  ),
                ],
              ),
            ),
          ],
        );

      case _PermissionAction.check:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [TextSpan(text: 'Android → ')],
                  ),
                  TextSpan(
                    text:
                        'Returns reliable permission status for all access types (read, write, history, background).',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [TextSpan(text: 'iOS → ')],
                  ),
                  TextSpan(
                    text:
                        'Read access always returns "unknown" - you must query data to infer actual status. Write access status is reliable.',
                  ),
                ],
              ),
            ),
          ],
        );

      case _PermissionAction.revoke:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [TextSpan(text: 'Android → ')],
                  ),
                  TextSpan(
                    text:
                        'Fully supported. Revokes the requested permissions immediately.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [TextSpan(text: 'iOS → ')],
                  ),
                  TextSpan(
                    text:
                        'Not supported. HealthKit does not allow apps to programmatically revoke their own permissions. User must manually revoke via iOS Settings.',
                  ),
                ],
              ),
            ),
          ],
        );

      case _PermissionAction.settings:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [TextSpan(text: 'Android → ')],
                  ),
                  TextSpan(
                    text:
                        'Opens Health Connect settings for your app. On Android 14+, opens directly to app\'s permission screen.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [TextSpan(text: 'iOS → ')],
                  ),
                  TextSpan(
                    text:
                        'Opens your app\'s system settings page. User must navigate to Health → Data Access & Devices → [Your App].',
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  List<TextSpan> _buildHighlightedCode(String code) {
    final spans = <TextSpan>[];
    final lines = code.split('\n');

    for (final line in lines) {
      final lineSpans = <TextSpan>[];

      // Keywords
      final keywords = [
        'final',
        'await',
        'forHistory',
        'forBackground',
        'true',
        'false',
      ];
      final types = ['CKType'];

      String remaining = line;

      // Highlight keywords
      for (final keyword in keywords) {
        final index = remaining.indexOf(keyword);
        if (index != -1) {
          if (index > 0) {
            lineSpans.add(
              TextSpan(
                text: remaining.substring(0, index),
                style: const TextStyle(color: Color(0xFFD4D4D4)), // Light gray
              ),
            );
          }
          lineSpans.add(
            TextSpan(
              text: keyword,
              style: TextStyle(
                color: keyword == 'final' || keyword == 'await'
                    ? const Color(0xFF569CD6) // Blue for keywords
                    : keyword.contains('for')
                        ? const Color(0xFF9CDCFE) // Light blue for parameters
                        : const Color(0xFF569CD6), // Blue for booleans
              ),
            ),
          );
          remaining = remaining.substring(index + keyword.length);
        }
      }

      // Highlight CKType
      for (final type in types) {
        int index = remaining.indexOf(type);
        while (index != -1) {
          if (index > 0) {
            lineSpans.add(
              TextSpan(
                text: remaining.substring(0, index),
                style: const TextStyle(color: Color(0xFFD4D4D4)), // Light gray
              ),
            );
          }

          // Extract the full CKType.enumValue
          final match = RegExp(
            r'CKType\.\w+',
          ).firstMatch(remaining.substring(index));
          if (match != null) {
            lineSpans.add(
              TextSpan(
                text: match.group(0)!,
                style: const TextStyle(
                  color: Color(0xFF4EC9B0),
                ), // Green for types
              ),
            );
            remaining = remaining.substring(index + match.group(0)!.length);
          } else {
            remaining = remaining.substring(index + type.length);
          }
          index = remaining.indexOf(type);
        }
      }

      // Highlight method calls
      final methodMatch = RegExp(r'connectKit\.\w+\(').firstMatch(remaining);
      if (methodMatch != null) {
        final beforeMethod = remaining.substring(0, methodMatch.start);
        if (beforeMethod.isNotEmpty) {
          lineSpans.add(
            TextSpan(
              text: beforeMethod,
              style: const TextStyle(color: Color(0xFFD4D4D4)), // Light gray
            ),
          );
        }

        lineSpans.add(
          TextSpan(
            text: methodMatch.group(0)!,
            style: const TextStyle(
              color: Color(0xFFDCDCAA),
            ), // Yellow for methods
          ),
        );

        remaining = remaining.substring(methodMatch.end);
      }

      // Add remaining text
      if (remaining.isNotEmpty) {
        lineSpans.add(
          TextSpan(
            text: remaining,
            style: const TextStyle(color: Color(0xFFD4D4D4)), // Light gray
          ),
        );
      }

      spans.add(TextSpan(children: lineSpans));
      spans.add(const TextSpan(text: '\n'));
    }

    return spans;
  }

  String _generateCodeSnippet() {
    final buffer = StringBuffer();

    switch (_selectedAction) {
      case _PermissionAction.request:
        buffer.writeln('final success = await connectKit.requestPermissions(');
        _addDataParameters(buffer);
        buffer.writeln(');');
        break;
      case _PermissionAction.check:
        buffer
            .writeln('final accessStatus = await connectKit.checkPermissions(');
        _addCheckParameters(buffer);
        buffer.writeln(');');
        break;
      case _PermissionAction.revoke:
        buffer.writeln('final success = await connectKit.revokePermissions();');
        break;
      case _PermissionAction.settings:
        buffer
            .writeln('final success = await connectKit.openHealthSettings();');
        break;
    }

    return buffer.toString();
  }

  void _addDataParameters(StringBuffer buffer) {
    // Read types
    if (_selectedReadTypes.isNotEmpty) {
      buffer.writeln('  readTypes: {');
      for (int i = 0; i < _selectedReadTypes.length; i++) {
        final type = _selectedReadTypes.elementAt(i);
        final isLast = i == _selectedReadTypes.length - 1;
        buffer.writeln('    CKType.${type.toString()}${isLast ? '' : ','}');
      }
      buffer.writeln('  },');
    }

    // Write types
    if (_selectedWriteTypes.isNotEmpty) {
      buffer.writeln('  writeTypes: {');
      for (int i = 0; i < _selectedWriteTypes.length; i++) {
        final type = _selectedWriteTypes.elementAt(i);
        final isLast = i == _selectedWriteTypes.length - 1;
        buffer.writeln('    CKType.${type.toString()}${isLast ? '' : ','}');
      }
      buffer.writeln('  },');
    }

    // Special permissions
    if (_requestHistory || _requestBackground) {
      buffer.writeln('  forHistory: $_requestHistory,');
      buffer.writeln('  forBackground: $_requestBackground,');
    }
  }

  void _addCheckParameters(StringBuffer buffer) {
    // Build forData map
    final forData = <CKType, Set<CKAccessType>>{};
    for (final type in _selectedReadTypes) {
      forData[type] = {CKAccessType.read};
    }
    for (final type in _selectedWriteTypes) {
      forData[type] = {CKAccessType.write};
    }

    if (forData.isNotEmpty) {
      buffer.writeln('  forData: {');
      forData.forEach((type, accessTypes) {
        buffer.writeln('    ${type.toString()}: {');
        for (int i = 0; i < accessTypes.length; i++) {
          final accessType = accessTypes.elementAt(i);
          final isLast = i == accessTypes.length - 1;
          buffer.writeln(
              '      CKAccessType.${accessType.toString()}${isLast ? '' : ','}');
        }
        buffer.writeln('    },');
      });
      buffer.writeln('  },');
    }

    // Special permissions
    if (_requestHistory || _requestBackground) {
      buffer.writeln('  forHistory: $_requestHistory,');
      buffer.writeln('  forBackground: $_requestBackground,');
    }
  }

  Widget _buildCheckPermissionsResult(String resultType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getResultIcon(resultType),
              color: _getResultIconColor(resultType),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Permission Status Retrieved',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getResultTextColor(resultType),
                ),
              ),
            ),
            if (_resultDuration.isNotEmpty)
              Text(
                _resultDuration,
                style: TextStyle(
                  fontSize: 12,
                  color: _getResultTextColor(resultType),
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // History access
        if (_requestHistory) ...[
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'History Access: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: _lastAccessStatus!.historyAccess.name,
                    style: TextStyle(
                      color: _lastAccessStatus!.historyAccess.isGranted
                          ? Colors.green[700]
                          : _lastAccessStatus!.historyAccess.isDenied
                              ? Colors.red[700]
                              : Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Background access
        if (_requestBackground) ...[
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Background Access: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: _lastAccessStatus!.backgroundAccess.name,
                    style: TextStyle(
                      color: _lastAccessStatus!.backgroundAccess.isGranted
                          ? Colors.green[700]
                          : _lastAccessStatus!.backgroundAccess.isDenied
                              ? Colors.red[700]
                              : Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Data access types
        if (_lastAccessStatus!.dataAccess.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 28, top: 8),
            child: Text(
              'Data Access:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._lastAccessStatus!.dataAccess.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ...entry.value.entries.map((accessEntry) {
                    final status = accessEntry.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                          children: [
                            TextSpan(
                              text: '${accessEntry.key.name}: ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            TextSpan(
                              text: status.name,
                              style: TextStyle(
                                color: status.isGranted
                                    ? Colors.green[600]
                                    : status.isDenied
                                        ? Colors.red[600]
                                        : Colors.orange[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildDefaultResultHeader(String resultType) {
    return Row(
      children: [
        Icon(
          _getResultIcon(resultType),
          color: _getResultIconColor(resultType),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _getResultText(resultType),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getResultTextColor(resultType),
            ),
          ),
        ),
        if (_resultDuration.isNotEmpty)
          Text(
            _resultDuration,
            style: TextStyle(
              fontSize: 12,
              color: _getResultTextColor(resultType),
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );
  }
}
