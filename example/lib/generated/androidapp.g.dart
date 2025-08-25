part of 'androidapp.dart';

extension AndroidAppFirestoreExtension on AndroidApp {
  Map<String, dynamic> toFirestore() => {
    'images': images,
    'time': time,
    'explanation': explanation,
    'appState': appState,
    'web': web,
    'appType': appType,
    'icon': icon,
    'comment': comment,
    'detail': detail,
    'publicationState': publicationState,
    'appTitle': appTitle,
  };
}

AndroidApp _$AndroidAppFromFirestore(Map<String, dynamic> map) {
  return AndroidApp(
    id: map['id'] as String,
    images: map['images'] as String,
    time: map['time'] as String,
    explanation: map['explanation'] as String,
    appState: map['appState'] as int,
    web: map['web'] as String,
    appType: map['appType'] as int,
    icon: map['icon'] as String,
    comment: map['comment'] as String,
    detail: map['detail'] as String,
    publicationState: map['publicationState'] as int,
    appTitle: map['appTitle'] as String,
  );
}
