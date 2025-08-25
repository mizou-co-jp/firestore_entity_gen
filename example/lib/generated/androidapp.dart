part 'androidapp.g.dart';

/// Generated entity for collection `AndroidApp`.
///
/// The `id` field holds the Firestore document ID. When generating from Firestore REST responses, the CLI will extract the document ID from the document `name` and include it as the `id` field in the parsed map so that the generated _$AndroidAppFromFirestore can read it.
/// If you construct maps manually, include an `id` key with the document id.
class AndroidApp {
  final int appState;
  final String appTitle;
  final int appType;
  final String comment;
  final String detail;
  final String explanation;
  final String icon;
  final String id;
  final String images;
  final int publicationState;
  final String time;
  final String web;

  AndroidApp({required this.appState, required this.appTitle, required this.appType, required this.comment, required this.detail, required this.explanation, required this.icon, required this.id, required this.images, required this.publicationState, required this.time, required this.web});
}
