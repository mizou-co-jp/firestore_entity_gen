# firestore_entity_gen

Firestore のデータから Dart のエンティティクラスを自動生成する CLI ファーストなツールです。

要点（必読）
- 利用者は通常モデルクラスを手で書きません。`bin/gen_from_firestore.dart` を使い、Firestore（REST）またはローカル JSON から型推論して自動生成するワークフローを想定しています。
- ライブラリ側の `@FirestoreEntity`（source_gen）サポートは補助機能です。推奨ワークフローは CLI による生成です。

クイックスタート

1) 依存を取得

```bash
fvm dart pub get
```

2) ローカル JSON から生成（テスト用）

```bash
fvm dart run bin/gen_from_firestore.dart -j tmp/sample_docs.json -c users -o example/lib/generated
```
# firestore_entity_gen

Firestore のデータから Dart のエンティティクラスを自動生成する CLI ファーストなツールです。

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
brew install --cask google-cloud-sdk
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
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

トークン取得を確認して動作を検証:

```bash
gcloud auth application-default print-access-token
```

トークンが表示されれば CLI を使って生成できます:

```bash
fvm dart run bin/gen_from_firestore.dart -p your-gcp-project -c users -o example/lib/generated
```

注: `gcloud auth application-default login` が失敗する場合は、ネットワークや gcloud のバージョン、既存の認証状態（`gcloud auth list`）を確認してください。

主な CLI オプション
- `-p, --project <id>` : GCP プロジェクト（REST モードで必須）
- `-c, --collection <id>` : コレクション名（必須）
- `-o, --out <dir>` : 出力先（デフォルト `lib/generated`）
- `--enum` : 文字列フィールドで限定的に enum を生成

認証の仕組み
- REST モードは `gcloud auth application-default print-access-token` を呼び、得たトークンで Firestore REST API を呼び出します。gcloud のセットアップ（インストール & ログイン）が前提です。

出力と運用方針
- 生成されるファイルは `<collection>.dart` と `<collection>.g.dart` の2ファイルです。
- 生成物は再生成可能であるため、サンプルは `example/lib/generated/` に置く運用を推奨します。公開ライブラリの `lib/` に生成物を恒久的に置く必要は通常ありません。

制限事項
- ページネーション（大量ドキュメントの多ページ取得）は現状未実装です。
- 型推論は基本ケース向けです（DateTime, List, Map, enum 等の簡易対応）。複雑なネストやカスタム変換は生成後に手動調整してください。

検証コマンド

```bash
fvm dart analyze
fvm dart test
```

追記希望
- nullable / enum の具体例や、生成物をリポジトリに含めるかどうかの運用例を README に追加できます。希望があれば教えてください。
