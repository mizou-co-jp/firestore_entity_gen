library firestore_entity_annotations;

/// Annotation used to mark a class as a Firestore entity.
///
/// Keep this intentionally small to avoid depending on analyzer-only APIs.
class FirestoreEntity {
  final String? collection;
  const FirestoreEntity({this.collection});
}
