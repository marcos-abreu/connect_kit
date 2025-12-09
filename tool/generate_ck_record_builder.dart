import 'dart:io';

// Configuration
const inputFilePath = 'lib/src/models/schema/ck_type.dart';
const outputFilePath = 'lib/src/models/records/ck_record_builder.g.dart';
const builderClass = 'CKRecordBuilder';
const imports = [
  'package:connect_kit/src/models/ck_categories.dart',
  'package:connect_kit/src/models/records/ck_data_record.dart',
  'package:connect_kit/src/models/schema/ck_source.dart',
  'package:connect_kit/src/models/schema/ck_type.dart',
  'package:connect_kit/src/models/schema/ck_unit.dart',
  'package:connect_kit/src/models/schema/ck_value.dart',
];

// Local enums for parsing
enum LocalValuePattern {
  quantity,
  samples,
  category,
  multiple,
  label,
  none,
}

enum LocalTimePattern {
  instantaneous,
  interval,
}

class TypeDefinition {
  final String name;
  final LocalValuePattern pattern;
  final LocalTimePattern timePattern;
  final List<PropertyDefinition> properties;

  TypeDefinition({
    required this.name,
    required this.pattern,
    required this.timePattern,
    required this.properties,
  });
}

class PropertyDefinition {
  final String name;
  final String pattern;
  final String type;
  final bool isRequired;
  final bool isMainProperty;
  final bool isUnitClass;

  PropertyDefinition({
    required this.name,
    required this.pattern,
    required this.type,
    required this.isRequired,
    required this.isMainProperty,
    required this.isUnitClass,
  });
}

void main() {
  print('🔧 Starting code generation...');
  print('📦 Input: $inputFilePath');

  // Read input file
  final inputFile = File(inputFilePath);
  if (!inputFile.existsSync()) {
    print('❌ Error: $inputFilePath not found');
    exit(1);
  }

  final content = inputFile.readAsStringSync();
  print('✅ Successfully read input file (${content.length} characters)');

  // Parse types
  print('\n🔍 Parsing types...');
  final types = _parseTypes(content);
  print('✅ Found ${types.length} valid types');

  // Generate output
  print('\n🔍 Generating output...');
  final output = _generateOutput(types);
  print('✅ Generated output (${output.length} characters)');

  // Write output file
  print('\n🔍 Writing output file...');
  final outputFile = File(outputFilePath);
  outputFile.writeAsStringSync(output);
  print('✅ Successfully wrote output to $outputFilePath');

  print('\n🎉 Code generation completed successfully!');
}

List<TypeDefinition> _parseTypes(String content) {
  final types = <TypeDefinition>[];
  final lines = content.split('\n');

  // Pattern to match CKType._ constructors with exactly 3 parameters
  // More flexible - allows whitespace and comments between parameters
  final typePattern = RegExp(
    r"static\s+const\s+(\w+)\s*=\s*CKType\._\s*\(\s*'([^']+)'\s*,\s*CKValuePattern\.(\w+)\s*,\s*CKTimePattern\.(\w+)\s*,?\s*\)",
    multiLine: true,
  );

  // Pattern to match property annotations
  final propPattern = RegExp(
    r'///\s*@ck-type-prop:\s*(\w+):(\w+):([^\s]+)\s+(required|optional)\s*(main)?',
  );

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Look ahead to capture multi-line CKType._ definitions
    final blockStart = i;
    var blockEnd = i;
    var foundConstructor = false;

    // Check if this line starts a type definition
    if (line.contains('static const') && line.contains('CKType._')) {
      // Collect lines until we find the closing parenthesis and semicolon
      final blockLines = <String>[line];
      for (int j = i + 1; j < lines.length && j < i + 10; j++) {
        blockLines.add(lines[j]);
        blockEnd = j;
        if (lines[j].contains(');')) {
          foundConstructor = true;
          break;
        }
      }

      if (foundConstructor) {
        // Join the lines and try to match
        final block = blockLines.join(' ').replaceAll(RegExp(r'\s+'), ' ');
        final typeMatch = typePattern.firstMatch(block);

        if (typeMatch != null) {
          final varName = typeMatch.group(1)!;
          final typeName = typeMatch.group(2)!;
          final patternStr = typeMatch.group(3)!;
          final timePatternStr = typeMatch.group(4)!;

          // Skip composite type properties (contain dots)
          if (typeName.contains('.')) {
            i = blockEnd;
            continue;
          }

          // Parse patterns
          final pattern = _parseValuePattern(patternStr);
          final timePattern = _parseTimePattern(timePatternStr);

          // Collect property annotations from previous lines
          final properties = <PropertyDefinition>[];
          for (int j = blockStart - 1; j >= 0; j--) {
            final prevLine = lines[j];
            if (!prevLine.trim().startsWith('///')) {
              break;
            }

            final propMatch = propPattern.firstMatch(prevLine);
            if (propMatch != null) {
              final propName = propMatch.group(1)!;
              final propPattern = propMatch.group(2)!;
              final propType = propMatch.group(3)!;
              final isRequired = propMatch.group(4) == 'required';
              final isMainProperty = pattern == LocalValuePattern.multiple &&
                  (propMatch.group(5) != null && propMatch.group(5) == 'main');

              // Determine if type is a unit class or specific unit
              final isUnitClass = !propType.contains('.');

              properties.insert(
                0,
                PropertyDefinition(
                  name: propName,
                  pattern: propPattern,
                  type: propType,
                  isRequired: isRequired,
                  isMainProperty: isMainProperty,
                  isUnitClass: isUnitClass,
                ),
              );
            }
          }

          // Validate properties match pattern
          _validateProperties(typeName, pattern, properties);

          types.add(TypeDefinition(
            name: varName,
            pattern: pattern,
            timePattern: timePattern,
            properties: properties,
          ));

          print(
              '  ✓ Parsed: $varName ($pattern, $timePattern, ${properties.length} props)');
        }

        i = blockEnd;
      }
    }
  }

  return types;
}

LocalValuePattern _parseValuePattern(String patternStr) {
  switch (patternStr) {
    case 'quantity':
      return LocalValuePattern.quantity;
    case 'samples':
      return LocalValuePattern.samples;
    case 'category':
      return LocalValuePattern.category;
    case 'multiple':
      return LocalValuePattern.multiple;
    case 'label':
      return LocalValuePattern.label;
    case 'none':
      return LocalValuePattern.none;
    default:
      throw ArgumentError('Unknown value pattern: $patternStr');
  }
}

LocalTimePattern _parseTimePattern(String timePatternStr) {
  switch (timePatternStr) {
    case 'instantaneous':
      return LocalTimePattern.instantaneous;
    case 'interval':
      return LocalTimePattern.interval;
    default:
      throw ArgumentError('Unknown time pattern: $timePatternStr');
  }
}

void _validateProperties(
  String typeName,
  LocalValuePattern pattern,
  List<PropertyDefinition> properties,
) {
  switch (pattern) {
    case LocalValuePattern.quantity:
    case LocalValuePattern.samples:
    case LocalValuePattern.category:
    case LocalValuePattern.label:
      if (properties.length != 1) {
        throw StateError(
          'Type $typeName with pattern $pattern must have exactly 1 property annotation',
        );
      }
      break;
    case LocalValuePattern.multiple:
      if (properties.isEmpty) {
        throw StateError(
          'Type $typeName with pattern $pattern must have at least 1 property annotation',
        );
      }

      // Check if more than one property has isMainProperty == true
      final mainCount =
          properties.where((property) => property.isMainProperty).length;
      if (mainCount != 1) {
        final msgCount = mainCount == 0 ? 'must have' : 'cannot have more than';
        throw StateError(
          'Type $typeName with pattern $pattern $msgCount one property marked as \'main\'',
        );
      }

      break;
    case LocalValuePattern.none:
      // For none pattern, we expect the annotation but ignore property count
      break;
  }
}

String _generateOutput(List<TypeDefinition> types) {
  final buffer = StringBuffer();

  // Header
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// Generated by tool/generate_ck_record_builder.dart');
  buffer.writeln('// Generated on ${DateTime.now().toIso8601String()}');
  buffer.writeln();

  // Imports
  for (final import in imports) {
    buffer.writeln("import '$import';");
  }
  buffer.writeln();

  // Class header
  buffer.writeln('/// Factory methods for creating CKDataRecord instances');
  buffer.writeln('class $builderClass {');

  // Generate factory methods
  for (final type in types) {
    buffer.writeln(_generateFactoryMethod(type));
    buffer.writeln();
  }

  buffer.writeln('}');

  return buffer.toString();
}

String _generateFactoryMethod(TypeDefinition type) {
  final buffer = StringBuffer();

  // Documentation
  buffer.writeln('  /// Creates a ${type.name} record.');
  buffer.writeln('  ///');

  // Document data properties first
  for (final prop in type.properties) {
    if (prop.pattern != 'none') {
      buffer.writeln('  /// [${prop.name}] ${_getPropertyDescription(prop)}');
    }
  }

  // Document time properties
  if (type.timePattern == LocalTimePattern.instantaneous) {
    buffer.writeln('  /// [time] The time of the ${type.name}.');
    buffer.writeln('  /// [zoneOffset] Optional timezone offset at the time.');
  } else {
    buffer.writeln('  /// [startTime] The start time of the ${type.name}.');
    buffer.writeln('  /// [endTime] The end time of the ${type.name}.');
    buffer.writeln(
        '  /// [startZoneOffset] Optional timezone offset at start time.');
    buffer
        .writeln('  /// [endZoneOffset] Optional timezone offset at end time.');
  }

  buffer.writeln('  /// [source] The source of the ${type.name} data.');
  buffer.writeln('  ///');
  buffer
      .writeln('  /// Returns a [CKDataRecord] representing the ${type.name}.');

  if (type.pattern == LocalValuePattern.none) {
    buffer.writeln(
        '  /// Note: No data properties are accepted for this record type.');
  }

  // Method signature
  buffer.writeln('  static CKDataRecord ${type.name}({');

  // Parameters - data properties first
  for (final param in _generateParameters(type)) {
    buffer.writeln('    $param,');
  }

  buffer.writeln('  }) {');

  // Method body
  buffer.write(_generateMethodBody(type));

  buffer.writeln('  }');

  return buffer.toString();
}

String _getPropertyDescription(PropertyDefinition prop) {
  switch (prop.pattern) {
    case 'quantity':
      return 'The ${prop.name} value.';
    case 'samples':
      return 'The ${prop.name} samples.';
    case 'category':
      return 'The ${prop.name} category.';
    case 'label':
      return 'The ${prop.name} label.';
    default:
      return 'The ${prop.name}.';
  }
}

List<String> _generateParameters(TypeDefinition type) {
  final params = <String>[];

  // Data properties
  if (type.pattern == LocalValuePattern.quantity) {
    final prop = type.properties.first;
    params.add('required num ${prop.name}');
    if (prop.isUnitClass) {
      params.add('required ${prop.type} ${prop.name}Unit');
    }
  } else if (type.pattern == LocalValuePattern.samples) {
    final prop = type.properties.first;
    params.add('required List<CKSample> ${prop.name}');
    if (prop.isUnitClass) {
      params.add('required ${prop.type} ${prop.name}Unit');
    }
  } else if (type.pattern == LocalValuePattern.category) {
    final prop = type.properties.first;
    params.add('required ${prop.type} ${prop.name}');
  } else if (type.pattern == LocalValuePattern.label) {
    final prop = type.properties.first;
    final paramType = prop.type == 'String' ? 'String' : prop.type;
    if (prop.isRequired) {
      params.add('required $paramType ${prop.name}');
    } else {
      params.add('$paramType? ${prop.name}');
    }
  } else if (type.pattern == LocalValuePattern.multiple) {
    for (final prop in type.properties) {
      if (prop.pattern == 'quantity') {
        if (prop.isRequired) {
          params.add('required num ${prop.name}');
        } else {
          params.add('num? ${prop.name}');
        }
        if (prop.isUnitClass && prop.isRequired) {
          params.add('required ${prop.type} ${prop.name}Unit');
        } else if (prop.isUnitClass) {
          params.add('${prop.type}? ${prop.name}Unit');
        }
      } else if (prop.pattern == 'category') {
        if (prop.isRequired) {
          params.add('required ${prop.type} ${prop.name}');
        } else {
          params.add('${prop.type}? ${prop.name}');
        }
      } else if (prop.pattern == 'label') {
        final paramType = prop.type == 'String' ? 'String' : prop.type;
        if (prop.isRequired) {
          params.add('required $paramType ${prop.name}');
        } else {
          params.add('$paramType? ${prop.name}');
        }
      }
    }
  }

  // Time properties
  if (type.timePattern == LocalTimePattern.instantaneous) {
    params.add('required DateTime time');
    params.add('Duration? zoneOffset');
  } else {
    params.add('required DateTime startTime');
    params.add('required DateTime endTime');
    params.add('Duration? startZoneOffset');
    params.add('Duration? endZoneOffset');
  }

  // Source
  params.add('required CKSource source');

  // Metadata
  // params.add('Map<String, Object>? metadata');

  return params;
}

String _generateMethodBody(TypeDefinition type) {
  final buffer = StringBuffer();
  var requiresMetadata = false;

  if (type.pattern == LocalValuePattern.multiple) {
    // Build data map for multiple pattern
    buffer.writeln('    final data = <String, CKValue>{');

    String? mainProperty;

    for (final prop in type.properties) {
      if (prop.isRequired) {
        if (prop.pattern == 'quantity') {
          final unit = prop.isUnitClass ? '${prop.name}Unit' : prop.type;
          buffer.writeln(
              "      '${prop.name}': CKQuantityValue(${prop.name}, $unit),");
        } else if (prop.pattern == 'category') {
          buffer
              .writeln("      '${prop.name}': CKCategoryValue(${prop.name}),");
        } else if (prop.pattern == 'label') {
          final value =
              prop.type == 'String' ? prop.name : '${prop.name}.toString()';
          buffer.writeln("      '${prop.name}': CKLabelValue($value),");
        }
      }
    }

    buffer.writeln('    };');
    buffer.writeln();

    // Add optional properties
    for (final prop in type.properties) {
      if (prop.isMainProperty) mainProperty = prop.name;

      if (!prop.isRequired) {
        buffer.writeln('    if (${prop.name} != null) {');
        if (prop.pattern == 'quantity') {
          final unit = prop.isUnitClass ? '${prop.name}Unit!' : prop.type;
          buffer.writeln(
              "      data['${prop.name}'] = CKQuantityValue(${prop.name}!, $unit);");
        } else if (prop.pattern == 'category') {
          buffer.writeln(
              "      data['${prop.name}'] = CKCategoryValue(${prop.name}!);");
        } else if (prop.pattern == 'label') {
          final value = prop.type == 'String'
              ? '${prop.name}!'
              : '${prop.name}!.toString()';
          buffer.writeln("      data['${prop.name}'] = CKLabelValue($value);");
        }
        buffer.writeln('    }');
        buffer.writeln();
      }
    }

    if (mainProperty != null) {
      requiresMetadata = true;
      buffer.writeln(
          '    final metadata = {\'mainProperty\': \'$mainProperty\'};');
      // buffer.writeln('    metadata = metadata  != null');
      // buffer.writeln(
      //     '      ? { ...metadata, \'mainProperty\': \'$mainProperty\' }');
      // buffer.writeln('      : { \'mainProperty\': \'$mainProperty\' };');
      buffer.writeln();
    }
  }

  // Return statement
  if (type.timePattern == LocalTimePattern.instantaneous) {
    buffer.writeln('    return CKDataRecord.instantaneous(');
  } else {
    buffer.writeln('    return CKDataRecord(');
  }

  buffer.writeln('      type: CKType.${type.name},');

  // Data parameter
  if (type.pattern == LocalValuePattern.quantity) {
    final prop = type.properties.first;
    final unit = prop.isUnitClass ? '${prop.name}Unit' : prop.type;
    buffer.writeln('      data: CKQuantityValue(${prop.name}, $unit),');
  } else if (type.pattern == LocalValuePattern.samples) {
    final prop = type.properties.first;
    final unit = prop.isUnitClass ? '${prop.name}Unit' : prop.type;
    buffer.writeln('      data: CKSamplesValue(${prop.name}, $unit),');
  } else if (type.pattern == LocalValuePattern.category) {
    final prop = type.properties.first;
    buffer.writeln('      data: CKCategoryValue(${prop.name}),');
  } else if (type.pattern == LocalValuePattern.label) {
    final prop = type.properties.first;
    final value = prop.type == 'String' ? prop.name : '${prop.name}.toString()';
    buffer.writeln('      data: CKLabelValue($value),');
  } else if (type.pattern == LocalValuePattern.multiple) {
    buffer.writeln('      data: CKMultipleValue(data),');
  } else if (type.pattern == LocalValuePattern.none) {
    buffer.writeln(
        "      data: CKLabelValue('noop'), // Value will be ignored by the SDK");
  }

  // Time parameters
  if (type.timePattern == LocalTimePattern.instantaneous) {
    buffer.writeln('      time: time,');
    buffer.writeln('      zoneOffset: zoneOffset,');
  } else {
    buffer.writeln('      startTime: startTime,');
    buffer.writeln('      endTime: endTime,');
    buffer.writeln('      startZoneOffset: startZoneOffset,');
    buffer.writeln('      endZoneOffset: endZoneOffset,');
  }

  buffer.writeln('      source: source,');
  if (requiresMetadata) {
    buffer.writeln('      metadata: metadata,');
  }
  buffer.writeln('    );');

  return buffer.toString();
}
