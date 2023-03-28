## Camel K Workshop 

---

環境構築に OpenShift CLI （ocコマンド）が必要です。

### デプロイ方法

1. OpenShift にログインする　（RHPDS の OpenShift 4.11 Workshop で動作確認）
2. 本リポジトリ内の provisionフォルダ内の setup.sh を、実行する。引数にはユーザー数を入れてください。
   （mac なら以下のコマンドを実行）

```
cd provision
sh ./setup.sh <user-count>
```

3. 実行後、OpenShift Web Console の userX-dev プロジェクトに入り、guides の Route URL にアクセスしてください。
   ターミナルのログの最後にもURLが表示されますので、そちらからでもOKです。

---

### 更新

2023/1/16: 作成

2023/1/18: Kafka/PostgreSQL連携 のページを追加

2023/3/27: OpenShift DevSpaces版にアップデート