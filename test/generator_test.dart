import 'package:test/test.dart';
import 'package:firestore_entity_gen/firestore_entity_annotations.dart';

void main() {
  test('annotation default', () {
    final a = FirestoreEntity();
    expect(a.collection, isNull);
  });
}
