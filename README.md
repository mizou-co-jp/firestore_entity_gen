# firestore_entity_gen
要点（必読）
- 利用者は通常モデルクラスを手で書きません。`bin/gen_from_firestore.dart` を使い、Firestore（REST）から型推論して自動生成するワークフローを想定しています。
- ライブラリ側の `@FirestoreEntity`（source_gen）サポートは補助機能です。推奨ワークフローは CLI による生成です。

クイックスタート (gcloud ベース)

1) 依存を取得

```bash
fvm dart pub get
```

2) gcloud の準備と認証

macOS では Homebrew を使った例:

```bash
brew install --cask gcloud
```

gcloud 初期化 (アカウントとプロジェクトを選択):

```bash
gcloud init
```

Application Default Credentials を発行 (CLI が利用するトークン):

```bash
gcloud auth application-default login
```

必要に応じてクォータプロジェクトを設定:

```bash
gcloud auth application-default set-quota-project [YOUR_PROJECT_ID]
```

トークン取得を確認して動作を検証:

```bash
gcloud auth application-default print-access-token
```

トークンが表示されれば CLI を使って生成できます:

```bash
# プロジェクトディレクトリで
fvm dart pub add firestore_entity_gen
fvm dart run firestore_entity_gen:gen_from_firestore -p [YOUR_PROJECT_ID] -c [Collection name] -o [出力バス 例：example/lib/generated]
```

備考（開発者向け）
- 開発者がリポジトリをチェックアウトして直接実行する場合は、ルートから bin を指定して呼べます:

```bash
# リポジトリのルートで
fvm dart run bin/gen_from_firestore.dart -p YOUR_PROJECT_ID -c Collection -o example/lib/generated
```

注: `gcloud auth application-default login` が失敗する場合は、ネットワークや gcloud のバージョン、既存の認証状態（`gcloud auth list`）を確認してください。

---

### `id` フィールドについて

- 生成されるクラスには `id` フィールドが含まれます。これは Firestore のドキュメントID（REST レスポンスの `name` フィールドから抽出）を表します。
- CLI は Firestore REST の各ドキュメントから `name` をパースして `id` を抽出し、生成時にパース済みマップへ `id` キーを注入します。したがって、生成された `_$ClassFromFirestore` やユーティリティは `map['id']` を参照できます。
- 手動でマップを作成して `fromFirestore` 相当の関数に渡す場合は、必ず `id` キーを含めてください（例: `{'id': '<docId>', 'name': '...'}`）。
