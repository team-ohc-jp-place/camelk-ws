## Camel K Workshop 

---

### デプロイ方法

1. OpenShift にログインする　（RHPDS の OpenShift 4.11 Workshop で動作確認）
1. Guides をデプロイするためのプロジェクトを作る
1. 本リポジトリ内の provisionフォルダ内の setup.sh を、実行する。引数にはユーザー数を入れてください。
   （mac なら以下のコマンドを実行）

```
cd provision
sh ./setup.sh <user-count>
```


---

### 更新

2023/1/16: 作成

2023/1/18: Kafka/PostgreSQL連携 のページを追加

2023/3/27: OpenShift DevSpaces版にアップデート