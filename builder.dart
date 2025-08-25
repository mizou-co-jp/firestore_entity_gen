import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:firestore_entity_gen/src/firestore_entity_generator.dart';

Builder firestoreEntityBuilder(BuilderOptions options) =>
    SharedPartBuilder([FirestoreEntityGenerator()], 'firestore_entity_gen');
