## Camel Workshop 

---

環境構築に OpenShift CLI （ocコマンド）が必要です。
RHPDS の AWS with OpenShift Open Environment / OpenShift 4.17 で動作確認済み。
Control Plane Count=3で立ててください。

### デプロイ方法

1. OpenShift にログインする
2. 本リポジトリ内の provisionフォルダ内の setup.sh を、実行する。引数にはユーザー数を入れてください。
   （mac なら以下のコマンドを実行）

```
cd provision
sh ./setup.sh <user-count>
```

3. 実行後、OpenShift Web Console の userX-dev プロジェクトに入り、guides の Route URL にアクセスしてください。
   ターミナルのログの最後にもURLが表示されますので、そちらからでもOKです。

---

### コンテンツ

* Camel Kについて
* 利用環境について
* Timer コンポーネント
* File コンポーネント
* Data Formats パターン
* Split パターン
* Direct コンポーネント
* Recipient List パターン
* PostgreSQL との連携
* Camel/Kafka/Debezium を使ったDBの同期
* REST API サービスの実装

---

### 更新

* 2023/1/16:
  * 作成
* 2023/1/18: 
  * Kafka のページを追加
  * PostgreSQL連携 のページを追加
* 2023/3/27: 
  * OpenShift DevSpaces版にアップデート
* 2023/5/9: 
  * Camel/Kafka/Debezium を使ったDBの同期 のページを追加
  * REST API サービスの実装 のページを追加
* 2024/4/17:
  * 開発ツールをKaravanからKaotoに変更
