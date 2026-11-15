import 'dart:io';

// ================= MODELOS DE DOMINIO =================

class CropArea {
  final String name;
  final double plantedArea;

  CropArea({
    required String name,
    required this.plantedArea,
  }) : name = name.trim() {
    if (this.name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Name is required.');
    }

    if (!plantedArea.isFinite || plantedArea <= 0) {
      throw ArgumentError.value(
        plantedArea,
        'plantedArea',
        'Area must be positive and finite.',
      );
    }
  }
}

class AgriculturalRecord {
  final String municipality;
  final int year;
  final List<CropArea> crops;

  AgriculturalRecord({
    required String municipality,
    required this.year,
    required List<CropArea> crops,
  })  : municipality = municipality.trim(),
        crops = List<CropArea>.unmodifiable(crops) {
    if (this.municipality.isEmpty) {
      throw ArgumentError.value(
        municipality,
        'municipality',
        'Municipality is required.',
      );
    }

    if (year < 2000 || year > 2100) {
      throw ArgumentError.value(year, 'year', 'Invalid year.');
    }

    if (this.crops.isEmpty) {
      throw ArgumentError.value(crops, 'crops', 'At least one crop is required.');
    }

    Set<String> uniqueNames = <String>{};
    for (final crop in this.crops) {
      String normalizedName = crop.name.toLowerCase();
      if (!uniqueNames.add(normalizedName)) {
        throw ArgumentError.value(crop.name, 'crop', 'Duplicate crop name.');
      }
    }

    if (!totalArea.isFinite) {
      throw ArgumentError('Total area must be finite.');
    }
  }

  double get totalArea {
    double total = 0.0;
    for (final crop in crops) {
      total += crop.plantedArea;
    }
    return total;
  }

  double get averageArea => totalArea / crops.length;

  CropArea get largestCrop {
    CropArea largest = crops.first;
    for (final crop in crops.skip(1)) {
      if (crop.plantedArea > largest.plantedArea) {
        largest = crop;
      }
    }
    return largest;
  }

  double get largestShare => largestCrop.plantedArea / totalArea * 100;
}

class ObservationCatalog {
  final Map<String, AgriculturalRecord> _records =
      <String, AgriculturalRecord>{};

  String _buildKey(String municipality, int year) {
    String normalized = municipality.trim().toLowerCase();
    return '$normalized ($year)';
  }

  int get count => _records.length;

  bool add(AgriculturalRecord record) {
    String key = _buildKey(record.municipality, record.year);
    if (_records.containsKey(key)) {
      return false;
    }
    _records[key] = record;
    return true;
  }

  AgriculturalRecord? find(String municipality, int year) {
    String key = _buildKey(municipality, year);
    return _records[key];
  }

  bool remove(String municipality, int year) {
    String key = _buildKey(municipality, year);
    return _records.remove(key) != null;
  }

  List<AgriculturalRecord> listRecords() {
    List<AgriculturalRecord> result = _records.values.toList();
    result.sort((first, second) {
      String firstKey = _buildKey(first.municipality, first.year);
      String secondKey = _buildKey(second.municipality, second.year);
      return firstKey.compareTo(secondKey);
    });
    return List<AgriculturalRecord>.unmodifiable(result);
  }

  List<String> get uniqueCropNames {
    Set<String> names = <String>{};
    for (final record in _records.values) {
      for (final crop in record.crops) {
        names.add(crop.name.toLowerCase());
      }
    }
    List<String> sortedNames = names.toList()..sort();
    return List<String>.unmodifiable(sortedNames);
  }
}

// ================= LECTORES DE CONSOLA =================

String? readRequiredText(String prompt) {
  while (true) {
    stdout.write(prompt);
    String? input = stdin.readLineSync();
    if (input == null) return null;

    String trimmed = input.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    print('Error: Text cannot be empty.');
  }
}

int? readIntInRange(String prompt, int minimum, int maximum) {
  while (true) {
    stdout.write(prompt);
    String? input = stdin.readLineSync();
    if (input == null) return null;

    int? value = int.tryParse(input.trim());
    if (value != null && value >= minimum && value <= maximum) {
      return value;
    }
    print('Error: Enter an integer between $minimum and $maximum.');
  }
}

double? readPositiveArea(String prompt) {
  while (true) {
    stdout.write(prompt);
    String? input = stdin.readLineSync();
    if (input == null) return null;

    double? value = double.tryParse(input.trim());
    if (value != null && value.isFinite && value > 0) {
      return value;
    }
    print('Error: Enter a valid positive number.');
  }
}

String? readUniqueCropName(
  String prompt,
  Set<String> usedNames,
) {
  while (true) {
    String? rawName = readRequiredText(prompt);
    if (rawName == null) {
      return null;
    }

    String normalizedName = rawName.trim().toLowerCase();
    if (!usedNames.add(normalizedName)) {
      print('Crop already registered in this observation.');
      continue;
    }

    return rawName.trim();
  }
}

// ================= OPERACIONES DEL MENÚ =================

bool registerObservation(ObservationCatalog catalog) {
  String? municipality = readRequiredText('Municipality: ');
  if (municipality == null) return false;

  int? year = readIntInRange('Year (2000-2100): ', 2000, 2100);
  if (year == null) return false;

  if (catalog.find(municipality, year) != null) {
    print('Observation already exists.');
    return true;
  }

  int? cropCount = readIntInRange('Number of crops (1-5): ', 1, 5);
  if (cropCount == null) return false;

  List<CropArea> currentCrops = <CropArea>[];
  Set<String> usedNames = <String>{};

  for (int index = 1; index <= cropCount; index++) {
    String? cropName = readUniqueCropName('Crop $index name: ', usedNames);
    if (cropName == null) return false;

    double? area = readPositiveArea('Crop $index area (ha): ');
    if (area == null) return false;

    currentCrops.add(CropArea(name: cropName, plantedArea: area));
  }

  AgriculturalRecord record = AgriculturalRecord(
    municipality: municipality,
    year: year,
    crops: currentCrops,
  );

  if (catalog.add(record)) {
    print('Observation registered successfully.');
  } else {
    print('Observation already exists.');
  }
  return true;
}

void listObservations(ObservationCatalog catalog) {
  List<AgriculturalRecord> records = catalog.listRecords();
  if (records.isEmpty) {
    print('No observations registered.');
    return;
  }

  print('\n--- Registered Observations (${records.length}) ---');
  for (final record in records) {
    print(
      '${record.municipality} (${record.year}): ${record.crops.length} crops',
    );
  }
}

void showObservation(AgriculturalRecord record) {
  print('\n=== Observation Summary ===');
  print('Municipality: ${record.municipality}');
  print('Year: ${record.year}');

  for (final crop in record.crops) {
    print('  * ${crop.name}: ${crop.plantedArea.toStringAsFixed(2)} ha');
  }

  print('Crops processed: ${record.crops.length}');
  print('Total area: ${record.totalArea.toStringAsFixed(2)} ha');
  print('Average area: ${record.averageArea.toStringAsFixed(2)} ha');
  print(
    'Largest crop: ${record.largestCrop.name} (${record.largestCrop.plantedArea.toStringAsFixed(2)} ha)',
  );
  print('Largest share: ${record.largestShare.toStringAsFixed(2)}%');
}

bool viewObservation(ObservationCatalog catalog) {
  if (catalog.count == 0) {
    print('No observations registered.');
    return true;
  }

  String? municipality = readRequiredText('Municipality: ');
  if (municipality == null) return false;

  int? year = readIntInRange('Year (2000-2100): ', 2000, 2100);
  if (year == null) return false;

  AgriculturalRecord? record = catalog.find(municipality, year);
  if (record == null) {
    print('Observation not found.');
    return true;
  }

  showObservation(record);
  return true;
}

bool removeObservation(ObservationCatalog catalog) {
  if (catalog.count == 0) {
    print('No observations registered.');
    return true;
  }

  String? municipality = readRequiredText('Municipality to remove: ');
  if (municipality == null) return false;

  int? year = readIntInRange('Year (2000-2100): ', 2000, 2100);
  if (year == null) return false;

  if (catalog.remove(municipality, year)) {
    print('Observation removed.');
  } else {
    print('Observation not found.');
  }
  return true;
}

void main() {
  ObservationCatalog catalog = ObservationCatalog();

  while (true) {
    print('\n================================');
    print('       AGRODIVERSA OOP');
    print('================================');
    print('1. Register observation');
    print('2. List observations');
    print('3. View observation');
    print('4. Show unique crops');
    print('5. Remove observation');
    print('0. Exit');

    int? option = readIntInRange('Option: ', 0, 5);
    if (option == null || option == 0) {
      print('Goodbye!');
      return;
    }

    switch (option) {
      case 1:
        if (!registerObservation(catalog)) return;
      case 2:
        listObservations(catalog);
      case 3:
        if (!viewObservation(catalog)) return;
      case 4:
        List<String> crops = catalog.uniqueCropNames;
        if (crops.isEmpty) {
          print('No crops available.');
        } else {
          print('\n--- Unique Crops (${crops.length}) ---');
          for (final name in crops) {
            print('- $name');
          }
        }
      case 5:
        if (!removeObservation(catalog)) return;
      default:
        print('Unknown option.');
    }
  }
}