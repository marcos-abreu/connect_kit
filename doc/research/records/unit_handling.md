## Unit Handling Strategy

### Decision: String-Based Units with Constants

**Rationale**:
- Native platforms provide optimal unit validation and conversion
- Flexibility to support any unit without enum constraints
- Simpler API and direct platform mapping

**Implementation**:
1. **CKUnits Class**: Constants for common units (autocomplete, typo prevention)
2. **Factory Methods**: Sensible defaults for common measurements
3. **Native Validation**: Platforms catch invalid units at runtime

**Example**:
```dart
// Using constants (recommended)
CKValue.quantity(70.5, CKUnits.kilogram)

// Using factory with default
CKValue.weight(70.5)  // defaults to kg

// Custom unit
CKValue.quantity(70.5, 'kg')  // also valid
```

**Platform Mapping**:
- **iOS**: `HKUnit(from: unitString)` validates and converts
- **Android**: Strong types (`Mass`, `Energy`) handle conversion

**Benefits**:
✅ Autocomplete via constants
✅ Default units via factories
✅ Flexibility for custom units
✅ Native validation and conversion
