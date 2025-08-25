import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

Future<String?> _getAccessToken({Map<String, String>? env}) async {
  // Use gcloud application-default credentials
  final result = await Process.run('gcloud', ['auth', 'application-default', 'print-access-token'], environment: env);
  if (result.exitCode != 0) return null;
  return (result.stdout as String).trim();
}

String _pascal(String s) => s.split(RegExp(r'[_\-\s]+')).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
// naive singularizer: drop trailing 's' if present
String _pascalSingular(String s) {
  var base = _pascal(s);
  if (base.length > 1 && base.endsWith('s')) base = base.substring(0, base.length - 1);
  return base;
}

String _mergeTypes(Set<String> types) {
  if (types.contains('dynamic')) return 'dynamic';
  if (types.contains('double') && types.contains('int')) return 'double';
  if (types.length == 1) return types.first;
  return 'dynamic';
}

String _determineListType(List<dynamic> values) {
  final elementTypes = <String>{};
  for (var e in values) {
    elementTypes.add(_simpleType(e));
  }
  final merged = _mergeTypes(elementTypes);
  return 'List<$merged>';
}

String _simpleType(dynamic v) {
  if (v == null) return 'dynamic';
  if (v is String) return 'String';
  if (v is DateTime) return 'DateTime';
  if (v is int) return 'int';
  if (v is double) return 'double';
  if (v is bool) return 'bool';
  if (v is List) return _determineListType(v);
  if (v is Map) return 'Map<String, dynamic>';
  return 'dynamic';
}

Map<String, dynamic> _parseFirestoreDocument(Map<String, dynamic> doc) {
  final res = <String, dynamic>{};
  // extract document id from the document name, if present
  if (doc.containsKey('name') && doc['name'] is String) {
    final name = doc['name'] as String;
    // name format: projects/{proj}/databases/{db}/documents/{collection}/{docId}[/...]
    final parts = name.split('/');
    if (parts.isNotEmpty) {
      res['id'] = parts.last;
    }
  }
  final fieldsObj = doc['fields'] as Map<String, dynamic>?;
  if (fieldsObj == null) return res;
  fieldsObj.forEach((k, v) {
  if (v is Map<String, dynamic>) {
      if (v.containsKey('stringValue')) {
        res[k] = v['stringValue'];
      } else if (v.containsKey('integerValue')) {
        res[k] = int.tryParse(v['integerValue'].toString()) ?? 0;
      } else if (v.containsKey('doubleValue')) {
        res[k] = double.tryParse(v['doubleValue'].toString()) ?? 0.0;
      } else if (v.containsKey('booleanValue')) {
        res[k] = v['booleanValue'] as bool;
      } else if (v.containsKey('mapValue')) {
        final inner = (v['mapValue'] as Map<String, dynamic>)['fields'] as Map<String, dynamic>?;
        res[k] = (inner ?? {}).map((ik, iv) => MapEntry(ik, (iv is Map && iv.containsKey('stringValue')) ? iv['stringValue'] : iv));
      } else if (v.containsKey('arrayValue')) {
        final values = (v['arrayValue'] as Map<String, dynamic>)['values'] as List? ?? [];
        final parsed = values.map((vv) {
          if (vv is Map && vv.containsKey('stringValue')) return vv['stringValue'];
          if (vv is Map && vv.containsKey('integerValue')) return int.tryParse(vv['integerValue'].toString()) ?? 0;
          return vv;
        }).toList();
        res[k] = parsed;
      } else if (v.containsKey('timestampValue')) {
        res[k] = DateTime.parse(v['timestampValue'] as String);
      } else {
        res[k] = null;
      }
    } else {
      res[k] = null;
    }
  });
  return res;
}

String _genDartFiles(String collection, Map<String, String> finalTypes, Map<String, Set<String>> distinctValues, bool emitEnum) {
  final className = _pascalSingular(collection);
  final partFile = '${collection.toLowerCase()}.g.dart';

  final libBuffer = StringBuffer();
  libBuffer.writeln("part '$partFile';\n");
  // Doc comment: explain purpose of `id` field
  libBuffer.writeln('/// Generated entity for collection `$collection`.');
  libBuffer.writeln('///');
  libBuffer.writeln(
      '/// The `id` field holds the Firestore document ID. When generating from Firestore REST responses, the CLI will extract the document ID from the document `name` and include it as the `id` field in the parsed map so that the generated ' + '_\$' + className + 'FromFirestore' + ' can read it.');
  libBuffer.writeln('/// If you construct maps manually, include an `id` key with the document id.');
  libBuffer.writeln('class $className {');
  // ensure 'id' is treated like other fields and included in sorting
  finalTypes.putIfAbsent('id', () => 'String');
  final fieldKeys = finalTypes.keys.toList()..sort();
  for (final k in fieldKeys) {
    final t = finalTypes[k]!;
    libBuffer.writeln('  final $t $k;');
  }
  libBuffer.writeln('');
  final ctorParams = fieldKeys.map((k) => 'required this.$k').join(', ');
  libBuffer.writeln('  $className({${ctorParams}});');
  libBuffer.writeln('}');

  final genBuffer = StringBuffer();
  genBuffer.writeln("part of '${collection.toLowerCase()}.dart';\n");

  // enum declarations (stable order)
  if (emitEnum) {
    final identRe = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
    final keysForEnum = distinctValues.keys.toList()..sort();
    for (final k in keysForEnum) {
      final values = distinctValues[k] ?? <String>{};
      final t = finalTypes[k] ?? '';
      final isStringField = t.startsWith('String');
      if (!isStringField) continue;
      if (values.isNotEmpty && values.length <= 20) {
        final sortedValues = values.whereType<String>().toList()..sort();
        final allSafe = sortedValues.every((v) => identRe.hasMatch(v));
        if (!allSafe) continue;
        final enumName = _pascal(k);
        genBuffer.writeln('enum $enumName {');
        for (final v in sortedValues) {
          final constName = v.toString();
          genBuffer.writeln('  $constName,');
        }
        genBuffer.writeln('}\n');
      }
    }
  }

  // toFirestore (stable field order)
  genBuffer.writeln('extension ${className}FirestoreExtension on $className {');
  genBuffer.writeln('  Map<String, dynamic> toFirestore() => {');
  for (final k in fieldKeys) {
    final t = finalTypes[k]!;
    if (t == 'DateTime' || t == 'DateTime?') {
      genBuffer.writeln("    '$k': $k${t.endsWith('?') ? ' == null ? null : ' : '.'}toIso8601String(),");
    } else if (t.startsWith('List<DateTime')) {
      genBuffer.writeln("    '$k': $k.map((e) => e.toIso8601String()).toList(),");
    } else {
      genBuffer.writeln("    '$k': $k,");
    }
  }
  genBuffer.writeln('  };');
  genBuffer.writeln('}\n');

  // from map (stable order)
  genBuffer.writeln('$className _\$${className}FromFirestore(Map<String, dynamic> map) {');
  genBuffer.writeln('  return $className(');
  for (final k in fieldKeys) {
    final t = finalTypes[k]!;
    String expr;
    if (t == 'String') expr = "map['$k'] as String";
    else if (t == 'int') expr = "map['$k'] as int";
    else if (t == 'double') expr = "map['$k'] as double";
    else if (t == 'bool') expr = "map['$k'] as bool";
    else if (t == 'DateTime') expr = "DateTime.parse(map['$k'] as String)";
    else if (t == 'DateTime?') expr = "(map['$k'] == null) ? null : DateTime.parse(map['$k'] as String)";
    else if (t.startsWith('List<')) expr = "List.from(map['$k'] as List)";
    else if (t.startsWith('Map<')) expr = "(map['$k'] as Map<String, dynamic>)";
    else expr = "map['$k']";
    genBuffer.writeln("    $k: $expr,");
  }
  genBuffer.writeln('  );');
  genBuffer.writeln('}');

  return jsonEncode({'lib': libBuffer.toString(), 'gen': genBuffer.toString()});
}

Future<void> main(List<String> args) async {
  final p = ArgParser()
    ..addOption('project', abbr: 'p', help: 'GCP project id')
    ..addOption('database', abbr: 'd', defaultsTo: '(default)', help: 'Firestore database id')
    ..addOption('collection', abbr: 'c', help: 'Collection id to fetch')
    ..addOption('out', abbr: 'o', defaultsTo: 'lib/generated', help: 'Output directory')
    ..addOption('json-file', abbr: 'j', help: 'Use local JSON file (array of Firestore documents) instead of REST')
    ..addFlag('enum', help: 'Generate enums for string fields with limited distinct values', negatable: false)
    ..addOption('enum-threshold', defaultsTo: '20', help: 'Max distinct values to consider for enum')
    ..addOption('service-account', help: 'Path to service account JSON to set GOOGLE_APPLICATION_CREDENTIALS for gcloud token')
    ..addFlag('help', abbr: 'h', negatable: false);

  final opts = p.parse(args);
  if (opts['help']) {
    print('Usage: gen_from_firestore -p project -c collection [-d database] [-o out] [--json-file file] [--enum]');
    print(p.usage);
    return;
  }

  final project = opts['project'] as String?;
  final collection = opts['collection'] as String?;
  final out = opts['out'] as String;
  final database = opts['database'] as String;
  final jsonFile = opts['json-file'] as String?;
  final emitEnum = opts['enum'] as bool;
  final enumThreshold = int.tryParse(opts['enum-threshold'] as String) ?? 20;
  final sa = opts['service-account'] as String?;

  if (collection == null) {
    stderr.writeln('collection is required');
    exit(1);
  }

  List<Map<String, dynamic>> docs = [];
  if (jsonFile != null) {
    final content = File(jsonFile).readAsStringSync();
    final parsed = json.decode(content);
    if (parsed is List) {
      docs = List<Map<String, dynamic>>.from(parsed);
    } else {
      stderr.writeln('json-file must contain an array of Firestore document objects');
      exit(1);
    }
  } else {
    if (project == null) {
      stderr.writeln('project is required when using REST mode');
      exit(1);
    }
    final env = <String, String>{};
    if (sa != null) env['GOOGLE_APPLICATION_CREDENTIALS'] = sa;
  final token = await _getAccessToken(env: env);
    if (token == null) {
      stderr.writeln('Failed to get access token via gcloud. Ensure gcloud is installed and logged in.');
      exit(1);
    }
    final url = Uri.https('firestore.googleapis.com', '/v1/projects/$project/databases/$database/documents/$collection');
    final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) {
      stderr.writeln('Failed to fetch documents: ${res.statusCode} ${res.body}');
      exit(1);
    }
    final body = json.decode(res.body) as Map<String, dynamic>;
    docs = (body['documents'] as List? ?? []).map((e) => e as Map<String, dynamic>).toList();
  }

  if (docs.isEmpty) {
    stderr.writeln('No documents found in collection.');
    exit(1);
  }

  final fieldTypes = <String, Set<String>>{};
  final presence = <String, int>{};
  final distinctValues = <String, Set<String>>{};
  final total = docs.length;

  for (final d in docs) {
    final parsed = _parseFirestoreDocument(d);
  for (final entry in parsed.entries) {
      final k = entry.key;
      final v = entry.value;
      presence[k] = (presence[k] ?? 0) + 1;
      final t = _simpleType(v);
      fieldTypes.putIfAbsent(k, () => {}).add(t);
      if (v is String) {
        distinctValues.putIfAbsent(k, () => {}).add(v);
      }
    }
  }

  final finalTypes = <String, String>{};
  fieldTypes.forEach((k, types) {
    var merged = _mergeTypes(types);
    final nullable = (presence[k] ?? 0) < total;
    if (merged == 'dynamic') {
      finalTypes[k] = nullable ? 'dynamic' : 'dynamic';
    } else {
      finalTypes[k] = merged + (nullable ? '?' : '');
    }
  });

  // enum decision: only emit enums when flag set and distinct values per-field <= threshold
  final shouldEmitEnum = emitEnum;
  if (emitEnum) {
    // prune distinctValues to only those within threshold
    distinctValues.removeWhere((k, v) => v.length > enumThreshold);
  }

  final encoded = _genDartFiles(collection, finalTypes, distinctValues, shouldEmitEnum);
  final decoded = json.decode(encoded) as Map<String, dynamic>;
  final libContent = decoded['lib'] as String;
  final genContent = decoded['gen'] as String;

  final outDir = Directory(out);
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final libFile = File('${outDir.path}/${collection.toLowerCase()}.dart');
  final genFile = File('${outDir.path}/${collection.toLowerCase()}.g.dart');
  libFile.writeAsStringSync(libContent);
  genFile.writeAsStringSync(genContent);

  stdout.writeln('Generated ${libFile.path} and ${genFile.path}');
}
