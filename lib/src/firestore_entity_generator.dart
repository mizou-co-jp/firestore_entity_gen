import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:firestore_entity_gen/firestore_entity_annotations.dart';
import 'package:dart_style/dart_style.dart';

class FirestoreEntityGenerator extends GeneratorForAnnotation<FirestoreEntity> {
  final _formatter = DartFormatter();

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
          'FirestoreEntity can only be applied to classes.',
          element: element);
    }

  final ClassElement classElement = element;
    final className = classElement.name;
    final fields = classElement.fields
        .where((f) => !f.isStatic && !f.isPrivate && !f.isSynthetic)
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln("part of '${buildStep.inputId.pathSegments.last}';\n");

    // toFirestore extension
    buffer.writeln('extension ${className}FirestoreExtension on $className {');
    buffer.writeln('  Map<String, dynamic> toFirestore() {');
    buffer.writeln('    return {');
    for (final f in fields) {
      final name = f.name;
      buffer.writeln("      '$name' : ${_toSerializableExpression(f)},");
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln('}\n');

    // from map factory function
    buffer.writeln('${className} ${_fromMapFuncName(className)}(Map<String, dynamic> map) {');
    buffer.writeln('  return $className(');
    for (final f in fields) {
      final name = f.name;
      final des = _fromMapExpression(f);
      buffer.writeln('    $name: $des,');
    }
    buffer.writeln('  );');
    buffer.writeln('}');

    return _formatter.format(buffer.toString());
  }

  String _fromMapFuncName(String className) => '_\$${className}FromFirestore';

  String _toSerializableExpression(FieldElement f) {
    final DartType type = f.type;
    final typeStr = type.getDisplayString(withNullability: false);
    final isNullable = f.type.nullabilitySuffix != NullabilitySuffix.none;

    // Primitive types
    if (type.isDartCoreInt || type.isDartCoreDouble || type.isDartCoreBool || type.isDartCoreString) {
      return f.name;
    }

    // Enum -> use .name
    if (type.element is EnumElement) {
      return isNullable ? '${f.name}?.name' : '${f.name}.name';
    }

    // DateTime -> serialize as ISO string; also accept Timestamp at read time
    if (typeStr == 'DateTime') {
      return isNullable ? "${f.name} == null ? null : ${f.name}!.toIso8601String()" : '${f.name}.toIso8601String()';
    }

    // List handling
    if (type is ParameterizedType && type.element?.name == 'List') {
      final arg = type.typeArguments.isNotEmpty ? type.typeArguments.first.getDisplayString(withNullability: false) : 'dynamic';
      if (arg == 'DateTime') {
        return "${f.name}.map((e) => e is DateTime ? e.toIso8601String() : e).toList()";
      }
      if (const {'int','double','bool','String','dynamic'}.contains(arg)) {
        return f.name;
      }
      // nested objects in list
      return "${f.name}.map((e) => e.toFirestore()).toList()";
    }

    // Map<String, dynamic>
    if (typeStr.startsWith('Map')) {
      return f.name;
    }

    // Fallback: nested object with toFirestore()
    return '${f.name}.toFirestore()';
  }

  String _fromMapExpression(FieldElement f) {
    final DartType type = f.type;
    final typeStr = type.getDisplayString(withNullability: false);
    final isNullable = f.type.nullabilitySuffix != NullabilitySuffix.none;

    if (type.isDartCoreInt) return "map['${f.name}'] as int${isNullable ? '?' : ''}";
    if (type.isDartCoreDouble) return "map['${f.name}'] as double${isNullable ? '?' : ''}";
    if (type.isDartCoreBool) return "map['${f.name}'] as bool${isNullable ? '?' : ''}";
    if (type.isDartCoreString) return "map['${f.name}'] as String${isNullable ? '?' : ''}";

    // Enum
    if (type.element is EnumElement) {
      final enumCtor = '${typeStr}.values.byName';
      return isNullable
          ? "(map['${f.name}'] == null) ? null : $enumCtor(map['${f.name}'] as String)"
          : "$enumCtor(map['${f.name}'] as String)";
    }

    // DateTime: accept String, DateTime, or Timestamp-like (dynamic.toDate())
    if (typeStr == 'DateTime') {
      final inner = "(map['${f.name}'] is String) ? DateTime.parse(map['${f.name}'] as String) : (map['${f.name}'] is DateTime) ? map['${f.name}'] as DateTime : (map['${f.name}'] as dynamic).toDate()";
      return isNullable ? "(map['${f.name}'] == null) ? null : $inner" : inner;
    }

    // List handling
    if (type is ParameterizedType && type.element?.name == 'List') {
      final argType = type.typeArguments.isNotEmpty
          ? type.typeArguments.first.getDisplayString(withNullability: false)
          : 'dynamic';
      if (argType == 'DateTime') {
        final expr = "(map['${f.name}'] as List).map((e) => DateTime.parse(e as String)).toList()";
        return isNullable ? "(map['${f.name}'] == null) ? null : $expr" : expr;
      }
      if (!_isDartCoreType(argType)) {
        final expr = "(map['${f.name}'] as List).map((e) => _\$${argType}FromFirestore(e as Map<String, dynamic>)).toList()";
        return isNullable ? "(map['${f.name}'] == null) ? null : $expr" : expr;
      }
      return isNullable ? "(map['${f.name}'] == null) ? null : List.from(map['${f.name}'] as List)" : "List.from(map['${f.name}'] as List)";
    }

    // Map
    if (typeStr.startsWith('Map')) {
      return isNullable ? "(map['${f.name}'] as Map<String, dynamic>?)" : "(map['${f.name}'] as Map<String, dynamic>)";
    }

    // nested object
    if (!_isDartCoreType(typeStr)) {
      final expr = "_\$${typeStr}FromFirestore(map['${f.name}'] as Map<String, dynamic>)";
      return isNullable ? "(map['${f.name}'] == null) ? null : $expr" : expr;
    }

    // fallback
    return "map['${f.name}']";
  }

  bool _isDartCoreType(String typeName) {
    return const {'int', 'double', 'bool', 'String', 'dynamic', 'num'}.contains(typeName);
  }
}
