import 'package:flutter/material.dart';
import 'package:connect_kit/connect_kit.dart';

class WriteDataDemoScreen extends StatefulWidget {
  const WriteDataDemoScreen({super.key});

  @override
  State<WriteDataDemoScreen> createState() => _WriteDataDemoScreenState();
}

class _WriteDataDemoScreenState extends State<WriteDataDemoScreen> {
  final ConnectKit _connectKit = ConnectKit.instance;
  final Set<CKType> _selectedTypes = {};
  bool _isLoading = false;
  String _resultDuration = '';
  CKWriteResult? _lastWriteResult;
  String? _lastException;

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
          'Write Data',
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
            _buildTypeSelectionSection(),
            const SizedBox(height: 24),
            _buildCodeSnippetSection(),
            const SizedBox(height: 50),
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
                _selectedTypes.isNotEmpty && !_isLoading ? _writeData : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
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
                      Text('Writing...'),
                    ],
                  )
                : const Text(
                    'Write Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelectionSection() {
    return _buildSection(
      'Select Data Types to Write',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select types to generate and write sample data for:',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CKType.steps,
              CKType.weight,
              CKType.height,
              CKType.distance,
            ].map((type) {
              final isSelected = _selectedTypes.contains(type);
              return FilterChip(
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTypes.add(type);
                    } else {
                      _selectedTypes.remove(type);
                    }
                  });
                },
                label: Text(type.displayName),
                backgroundColor: Colors.grey[100],
                selectedColor: Colors.green[100],
                checkmarkColor: Colors.green[600],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.green[800] : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.green[300]! : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeSnippetSection() {
    return _buildSection(
      'Code Snippet',
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _generateCodeSnippet(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  String _generateCodeSnippet() {
    if (_selectedTypes.isEmpty) {
      return '// Select types to see code snippet';
    }

    final buffer = StringBuffer();
    buffer.writeln('final records = <CKRecord>[];');
    buffer.writeln('final now = DateTime.now().toUtc();');
    buffer.writeln();

    for (final type in _selectedTypes) {
      if (type == CKType.steps) {
        buffer.writeln('records.add(CKRecordBuilder.steps(');
        buffer.writeln('  count: 100,');
        buffer.writeln('  startTime: now.subtract(Duration(minutes: 10)),');
        buffer.writeln('  endTime: now,');
        buffer.writeln('  source: CKSource.manualEntry(),');
        buffer.writeln('));');
      } else if (type == CKType.weight) {
        buffer.writeln('records.add(CKRecordBuilder.weight(');
        buffer.writeln('  weight: 70.5,');
        buffer.writeln('  weightUnit: CKMassUnit.kilogram,');
        buffer.writeln('  time: now,');
        buffer.writeln('  source: CKSource.manualEntry(),');
        buffer.writeln('));');
      } else if (type == CKType.height) {
        buffer.writeln('records.add(CKRecordBuilder.height(');
        buffer.writeln('  length: 1.75,');
        buffer.writeln('  lengthUnit: CKLengthUnit.meter,');
        buffer.writeln('  time: now,');
        buffer.writeln('  source: CKSource.manualEntry(),');
        buffer.writeln('));');
      } else if (type == CKType.distance) {
        buffer.writeln('records.add(CKRecordBuilder.distance(');
        buffer.writeln('  length: 500,');
        buffer.writeln('  lengthUnit: CKLengthUnit.meter,');
        buffer.writeln('  startTime: now.subtract(Duration(minutes: 10)),');
        buffer.writeln('  endTime: now,');
        buffer.writeln('  source: CKSource.manualEntry(),');
        buffer.writeln('));');
      }
      buffer.writeln();
    }

    buffer.writeln('await ConnectKit.instance.writeRecords(records);');
    return buffer.toString();
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
            style: const TextStyle(
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

  Future<void> _writeData() async {
    final stopwatch = Stopwatch()..start();

    setState(() {
      _isLoading = true;
      _resultDuration = '';
      _lastWriteResult = null;
      _lastException = null;
    });

    try {
      final records = <CKRecord>[];
      final now = DateTime.now().toUtc();

      for (final type in _selectedTypes) {
        if (type == CKType.steps) {
          records.add(CKRecordBuilder.steps(
            count: 100,
            startTime: now.subtract(const Duration(minutes: 10)),
            endTime: now,
            source: CKSource.manualEntry(),
          ));
        } else if (type == CKType.weight) {
          records.add(CKRecordBuilder.weight(
            weight: 70.5,
            weightUnit: CKMassUnit.kilogram,
            time: now,
            source: CKSource.manualEntry(),
          ));
        } else if (type == CKType.height) {
          records.add(CKRecordBuilder.height(
            length: 1.75,
            lengthUnit: CKLengthUnit.meter,
            time: now,
            source: CKSource.manualEntry(),
          ));
        } else if (type == CKType.distance) {
          records.add(CKRecordBuilder.distance(
            length: 500,
            lengthUnit: CKLengthUnit.meter,
            startTime: now.subtract(const Duration(minutes: 10)),
            endTime: now,
            source: CKSource.manualEntry(),
          ));
        }
      }

      final result = await _connectKit.writeRecords(records);

      stopwatch.stop();

      if (mounted) {
        setState(() {
          _lastWriteResult = result;
          _resultDuration = '${stopwatch.elapsedMilliseconds}ms';
        });
        _showResultModal();
      }
    } catch (e) {
      stopwatch.stop();

      if (mounted) {
        setState(() {
          _lastException = e.toString();
          _resultDuration = '${stopwatch.elapsedMilliseconds}ms';
        });
        _showResultModal();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showResultModal() {
    final hasException = _lastException != null;
    final result = _lastWriteResult;
    final resultType = hasException
        ? 'error'
        : (result?.outcome == WriteOutcome.completeSuccess
            ? 'success'
            : (result?.outcome == WriteOutcome.partialSuccess
                ? 'partial'
                : 'error'));

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
              color: Colors.black.withValues(alpha: 0.1),
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

            // Result card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getResultBackgroundColor(resultType),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getResultBorderColor(resultType)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon, text, and duration
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
                  ),

                  // Write result details (if available)
                  if (result != null && !hasException) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Outcome
                    Row(
                      children: [
                        Text(
                          'Outcome:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getResultTextColor(resultType)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            result.outcome.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getResultTextColor(resultType),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Persisted IDs
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Persisted Records:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${result.persistedRecordIds?.length ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    if (result.persistedRecordIds?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      ...result.persistedRecordIds!.map((id) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 2),
                            child: Text(
                              '• $id',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontFamily: 'monospace',
                              ),
                            ),
                          )),
                    ],
                    const SizedBox(height: 12),

                    // Validation failures
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Validation Failures:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${result.validationFailures?.length ?? 0}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                (result.validationFailures?.isNotEmpty ?? false)
                                    ? Colors.red[700]
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (result.validationFailures?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      ...result.validationFailures!.map((failure) => Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• [${failure.indexPath.join(".")}]',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[600],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(
                                    failure.message,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ),
                                if (failure.type != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      'Type: ${failure.type}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.red[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ],
              ),
            ),

            // Exception details (only for errors)
            if (hasException)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  _lastException!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontFamily: 'monospace',
                  ),
                ),
              ),

            // Platform explanation box
            if (!hasException) _buildPlatformExplanationBox(),

            // Close button
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
        return Colors.orange[50]!;
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
        return Colors.orange[200]!;
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
        return Icons.warning;
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
        return Colors.orange[600]!;
      case 'error':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getResultText(String resultType) {
    if (_lastException != null) {
      return 'Write operation failed';
    }
    switch (resultType) {
      case 'success':
        return 'All records written successfully';
      case 'partial':
        return 'Some records failed validation';
      case 'error':
        return 'Write operation failed';
      default:
        return 'Unknown result';
    }
  }

  Color _getResultTextColor(String resultType) {
    switch (resultType) {
      case 'success':
        return Colors.green[700]!;
      case 'partial':
        return Colors.orange[700]!;
      case 'error':
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Widget _buildPlatformExplanationBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
            child: Column(
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
                            'Health Connect validates all records synchronously and returns detailed validation failures.',
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
                            'HealthKit accepts records but may silently reject invalid data. Check the Health app to verify.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
