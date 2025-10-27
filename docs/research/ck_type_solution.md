## Solution A: Use build_runner with a custom generator

### Step 1: Create the builder package structure

Create `tool/builder/pubspec.yaml`:
```yaml
name: ck_type_builder
publish_to: none

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  build: ^2.4.0
  source_gen: ^1.4.0
  analyzer: ^6.0.0
```

### Step 2: Create the simple generator

Create `tool/builder/lib/ck_type_generator.dart`:

```dart
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';

class CKTypeRegistryGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final classElement = library.classes.firstWhere(
      (c) => c.name == 'CKType',
      orElse: () => throw Exception('CKType class not found'),
    );

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln();
    buffer.writeln('class _\$CKTypeRegistry {');
    buffer.writeln('  static final Map<String, CKType> _registry = {');

    // Get all static const fields
    for (var field in classElement.fields) {
      if (field.isStatic && field.isConst) {
        final name = field.name;
        buffer.writeln("    '$name': CKType.$name,");

        // Check if it's a composite type with components
        if (field.type.element?.name?.endsWith('Type') ?? false) {
          final compositeClass = library.classes.firstWhere(
            (c) => c.name == field.type.element?.name,
            orElse: () => null as ClassElement,
          );

          if (compositeClass != null) {
            for (var getter in compositeClass.accessors) {
              if (getter.isGetter && !getter.isSynthetic) {
                buffer.writeln("    '$name.${getter.name}': CKType.$name.${getter.name},");
              }
            }
          }
        }
      }
    }

    buffer.writeln('  };');
    buffer.writeln();
    buffer.writeln('  static CKType fromString(String inputString) {');
    buffer.writeln('    if (inputString.isEmpty) {');
    buffer.writeln("      throw ArgumentError('Type string cannot be empty');");
    buffer.writeln('    }');
    buffer.writeln('    final type = _registry[inputString];');
    buffer.writeln('    if (type == null) {');
    buffer.writeln('      throw ArgumentError(');
    buffer.writeln('        \'Unknown health type: "\$inputString". \'');
    buffer.writeln('        \'Valid types: \${_registry.keys.join(", ")}\'');
    buffer.writeln('      );');
    buffer.writeln('    }');
    buffer.writeln('    return type;');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  static CKType? fromStringOrNull(String inputString) =>');
    buffer.writeln('      _registry[inputString];');
    buffer.writeln();
    buffer.writeln('  static bool isValid(String inputString) =>');
    buffer.writeln('      _registry.containsKey(inputString);');
    buffer.writeln();
    buffer.writeln('  static List<CKType> get allTypes => _registry.values.toList();');
    buffer.writeln('}');

    return buffer.toString();
  }
}

Builder ckTypeRegistryBuilder(BuilderOptions options) {
  return LibraryBuilder(
    CKTypeRegistryGenerator(),
    generatedExtension: '.g.dart',
  );
}
```

### Step 3: Create build.yaml in your main project

Create `build.yaml` in your project root:
```yaml
builders:
  ck_type_registry:
    import: "tool/builder/lib/ck_type_generator.dart"
    builder_factories: ["ckTypeRegistryBuilder"]
    build_extensions: {".dart": [".g.dart"]}
    auto_apply: dependents
    build_to: source
```

### Step 4: Your CKType file (unchanged except for the part directive)

```dart
// ck_type.dart
import 'package:connect_kit/src/utils/string_manipulation.dart';

part 'ck_type.g.dart';

class CKType {
  final String _name;
  const CKType._(this._name);

  // ALL YOUR TYPES - UNCHANGED
  static const height = CKType._('height');
  static const weight = CKType._('weight');
  // ... etc

  static const workout = _WorkoutType._();
  static const bloodPressure = _BloodPressureType._();
  static const nutrition = _NutritionType._();

  String get displayName => camelCaseToTitleCase(_name);

  @override
  String toString() => _name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CKType && runtimeType == other.runtimeType && _name == other._name;

  @override
  int get hashCode => _name.hashCode;

  static CKType fromString(String inputString) =>
      _$CKTypeRegistry.fromString(inputString);

  static CKType? fromStringOrNull(String inputString) =>
      _$CKTypeRegistry.fromStringOrNull(inputString);

  static bool isValid(String inputString) =>
      _$CKTypeRegistry.isValid(inputString);
}

// Composite types unchanged
```

### Step 5: Run the generator

```bash
dart run build_runner build
```

---

**But WAIT.** There is a different soluiton, still using a generator, but a custom one:

## Solution B: Single Dart Script

Create `tool/generate_types.dart`:

```dart
import 'dart:io';

void main() {
  final file = File('lib/src/ck_type.dart');
  final content = file.readAsStringSync();

  // Extract static const declarations
  final regex = RegExp(r"static const (\w+) = (?:CKType\._\('(\w+)'\)|_(\w+)Type\._\(\));");
  final types = <String, String>{};

  for (final match in regex.allMatches(content)) {
    final name = match.group(1)!;
    types[name] = name;
  }

  // Extract composite sub-types (e.g., workout.distance)
  final subTypeRegex = RegExp(r"CKType get (\w+) => (?:const )?CKType\._\('([\w.]+)'\);");
  for (final match in subTypeRegex.allMatches(content)) {
    final fullPath = match.group(2)!;
    types[fullPath] = fullPath;
  }

  // Generate code
  final output = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('part of \'ck_type.dart\';')
    ..writeln()
    ..writeln('class _\$CKTypeRegistry {')
    ..writeln('  static final _registry = <String, CKType>{');

  for (final entry in types.entries) {
    final path = entry.key.split('.');
    final accessor = path.length == 1
        ? 'CKType.${path[0]}'
        : 'CKType.${path[0]}.${path[1]}';
    output.writeln("    '${entry.value}': $accessor,");
  }

  output
    ..writeln('  };')
    ..writeln()
    ..writeln('  static CKType fromString(String s) {')
    ..writeln('    final type = _registry[s];')
    ..writeln("    if (type == null) throw ArgumentError('Unknown type: \$s');")
    ..writeln('    return type;')
    ..writeln('  }')
    ..writeln()
    ..writeln('  static CKType? fromStringOrNull(String s) => _registry[s];')
    ..writeln('  static bool isValid(String s) => _registry.containsKey(s);')
    ..writeln('  static List<CKType> get allTypes => _registry.values.toList();')
    ..writeln('}');

  File('lib/src/ck_type.g.dart').writeAsStringSync(output.toString());
  print('✓ Generated registry with ${types.length} types');
}
```

Run it:
```bash
dart run tool/generate_types.dart
```

**This is 40 lines.** No dependencies. One command. Done.
