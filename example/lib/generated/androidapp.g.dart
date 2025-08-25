part of 'androidapp.dart';

extension AndroidAppFirestoreExtension on AndroidApp {
  Map<String, dynamic> toFirestore() => {
    'comment': comment,
    'web': web,
    'explanation': explanation,
    'appType': appType,
    'detail': detail,
    'publicationState': publicationState,
    'time': time,
    'images': images,
    'appState': appState,
    'icon': icon,
    'appTitle': appTitle,
  };
}

AndroidApp _$AndroidAppFromFirestore(Map<String, dynamic> map) {
  return AndroidApp(
    id: map['id'] as String,
    comment: map['comment'] as String,
    web: map['web'] as String,
    explanation: map['explanation'] as String,
    appType: map['appType'] as int,
    detail: map['detail'] as String,
    publicationState: map['publicationState'] as int,
    time: map['time'] as String,
    images: map['images'] as String,
    appState: map['appState'] as int,
    icon: map['icon'] as String,
    appTitle: map['appTitle'] as String,
  );
}
