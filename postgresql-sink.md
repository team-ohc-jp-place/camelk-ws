## PostgresSQL との連携
---

### 1. 目的

Kamelet の **PostgreSQL Sink** を使用して、Camel K と Kafka との連携の方法について理解していただきます。

* [PostgreSQL Sink](https://camel.apache.org/camel-kamelets/{{ KAMELETS_VERSION }}/postgresql-sink.html){:target="_blank"}

![](images/08-postgresql-014.png)
![karavan]({% image_path 08-postgresql-014.png %}){:width="800px"}

#### このセクションで作成する内容

* 以下のコンポーネントは既に用意されています
  * PostgreSQL
* 実装する Camelルート
  * PostgreSQL のテーブルへデータを追加
  * PostgreSQL のテーブルからデータを取得

![](images/08-postgresql-016.png)
![karavan]({% image_path 08-postgresql-016.png %}){:width="1200px"}

---

### 2. PostgreSQL Sink を使用してテーブルからデータを取得する

PostgreSQL は、OpenShift上に用意されているものを使うことができます。

![](images/08-postgresql-015.png)
![karavan]({% image_path 08-postgresql-015.png %}){:width="800px"}

PostgreSQL にアクセスするための情報は以下の通りです。

* **Server Name**: postgresql.{{ OPENSHIFT_USER }}-dev.svc.cluster.local （cluster内からのみアクセス可能）
* **Server Port**: 5432
* **User Name**: demo
* **Password**: demo
* **Database Name**: sampledb

また、データベースには `products` というテーブルが用意されており、以下のデータが格納されています。

|  id (integer) |  name (varchar) |
| :---: | :---: |
|  1  |  apple  |
|  2  |  orange  |
|  3  |  lemon  |

実際に確認をしてみましょう。
OpenShift DevSpaces の Terminal を開き、postgresql の pod にログインし、postgreSQLのコマンドを実行してみてください。

```
oc exec -it -n {{ OPENSHIFT_USER }}-dev -- /bin/bash
psql sampledb
```

![](images/08-postgresql-000.png)
![karavan]({% image_path 08-postgresql-000.png %}){:width="600px"}

postgreSQL にログインしたら、`\d` と入力すると、テーブルの一覧が表示されます。

![](images/08-postgresql-001.png)
![karavan]({% image_path 08-postgresql-001.png %}){:width="400px"}

`products` テーブル の 中身を確認してみましょう。`select * from products;` と入力してください。

![](images/08-postgresql-002.png)
![karavan]({% image_path 08-postgresql-002.png %}){:width="400px"}

確認ができたら、`\q` で PostgreSQL を終了し、`exit` を入力して Pod へのアクセスを終了します。

---

それでは、OpenShift DevSpaces 左のエクスプローラー上で、右クリックをして、メニューから `Karavan: Create Integration` を選択し、`postgresql` と入力して Enter を押してください。`postgresql.camel.yaml` という名前のファイルが作成されて、Karavan Designer のGUIが開きます。

続いて、Karavan Designer のGUIが開いたら、上部の `Create route` をクリックして、Route を作成しましょう。

`components` タブから `Timer` を探して選択をしてください。
右上のテキストボックスに `Timer` と入力をすると、絞り込みができます。

Route の source として、Timer コンポーネントが配置されます。
Route の Timer シンボルをクリックすると、右側にプロパティが表示されますので、確認してください。

Parameters は、以下のように設定をします。

* **Timer Name**: 任意の名称
* **Repeat Count**: 1

![](images/08-postgresql-003.png)
![karavan]({% image_path 08-postgresql-003.png %}){:width="1200px"}

次に、PosgreSQL にアクセスするための Sink を追加します。
Route にマウスカーソルを持っていくと、Timer シンボルの下に小さな＋ボタンが現れますので、それをクリックし、`Kamelets` のタブから `PostgreSQL Sink` を探して選択をしてください。
右上のテキストボックスに `PostgreSQL Sink` と入力をすると、絞り込みができます。

![](images/08-postgresql-004.png)
![karavan]({% image_path 08-postgresql-004.png %}){:width="800px"}

`PostgreSQL` のシンボルが Timer に続いて配置されます。

PostgreSQL のシンボルをクリックすると、右側にプロパティが表示されますので、
先ほどの PostgreSQL の情報を設定していきます。
Parameters 項目に、以下の内容を設定してください。

* **Server Name**: postgresql.{{ OPENSHIFT_USER }}-dev.svc.cluster.local
* **Server Port**: 5432
* **Username**: demo
* **Password**: demo
* **Query**: select * from products
* **Database Name**: sampledb

![](images/08-postgresql-005.png)
![karavan]({% image_path 08-postgresql-005.png %}){:width="1200px"}

PostgreSQL Sink は、JSON形式のデータを Body として想定をしているため、JSON形式に変換するための Marshal が必要になります。
PostgreSQL Sink シンボルにマウスカーソルを持っていくと、左上に小さく `→` ボタンが表示されますので、クリックして、`Transformation` タブから `Marshal` を探して選択をしてください。
右上のテキストボックスに `Marshal` と入力をすると、絞り込みができます。

これで、`Timer` と `PostgreSQL Sink` の間に、`Marshal` が追加されます。

`Marshal` のシンボルをクリックすると、右側にプロパティが表示されますので、
Parameters 項目に、以下の内容を設定してください。
他の項目は、デフォルトのままで構いません。

* **Data Format**: json
* **Library**: jackson

![](images/08-postgresql-006.png)
![karavan]({% image_path 08-postgresql-006.png %}){:width="1200px"}

続いて、PostgreSQL から取得したデータを確認するための Log を追加します。
PostgreSQL Sink シンボルの下の＋ボタンをクリックし、`Routing` のタブから `Log` を探して選択をしてください。

取得した内容を表示するには、Log プロパティ の `Message` に `${body}` と入力をしてください。

![](images/08-postgresql-007.png)
![karavan]({% image_path 08-postgresql-007.png %}){:width="1200px"}

それでは、実際に動かしてみます。
右上の ロケットのアイコン のボタンを押してください。

ターミナルが開き、作成したインテグレーションが JBang を通して実行されます。
特にエラーなく実行されたら、ターミナルに以下の Log が表示されているはずです。

![](images/08-postgresql-008.png)
![karavan]({% image_path 08-postgresql-008.png %}){:width="1200px"}

Logの確認後、`Ctrl+C` もしくは、ターミナル右上のゴミ箱のアイコンをクリックして、終了してください。

### 3. PostgreSQL Sink を使用してテーブルにデータを追加する

先ほどは PosgreSQL Sink でデータを取得しましたが、今度はテーブルにレコードの追加を行う処理を作っていきます。
Karavan Designer で、先ほど作成をした `postgresql.camel.yaml` を開いてください。

まず、Set Body でテーブルに追加する内容を設定します。

Marshal シンボルにマウスカーソルを持っていくと、左上に小さく `→` ボタンが表示されますので、クリックして、`Transformation` タブから `Set Body` を探して選択をしてください。
右上のテキストボックスに `Set Body` と入力をすると、絞り込みができます。

![](images/08-postgresql-009.png)
![karavan]({% image_path 08-postgresql-009.png %}){:width="800px"}

これで、`Timer` と `Marshal` の間に、`Set Body` が追加されます。

`Set Body` のシンボルをクリックすると、右側にプロパティが表示されますので、
Parameters 項目に、以下の内容を設定してください。
他の項目は、デフォルトのままで構いません。

* **Language**: simple
* **Expression**: {"id":4, "name":"melon"}

![](images/08-postgresql-010.png)
![karavan]({% image_path 08-postgresql-010.png %}){:width="800px"}

次に、Set Body で設定した内容を PostgreSQL の products テーブルに追加してみましょう。
Marshal シンボルにマウスカーソルを持っていくと、左上に小さく `→` ボタンが表示されますので、クリックして、`Kamelets` のタブから `PostgreSQL Sink` を探して選択をしてください。
右上のテキストボックスに `PostgreSQL Sink` と入力をすると、絞り込みができます。

`PostgreSQL` のシンボルが Set Body に続いて配置されます。

PostgreSQL のシンボルをクリックすると、右側にプロパティが表示されますので、
Parameters 項目に、以下の内容を設定してください。

* **Server Name**: postgresql.{{ OPENSHIFT_USER }}-dev.svc.cluster.local
* **Server Port**: 5432
* **Username**: demo
* **Password**: demo
* **Query**: insert into products (id, name) values (:#id, :#name)
* **Database Name**: sampledb

![](images/08-postgresql-011.png)
![karavan]({% image_path 08-postgresql-011.png %}){:width="1200px"}

それでは、実際に動かしてみます。
右上の ロケットのアイコン のボタンを押してください。

ターミナルが開き、作成したインテグレーションが JBang を通して実行されます。
特にエラーなく実行されたら、ターミナルに以下の Log が表示されているはずです。

![](images/08-postgresql-012.png)
![karavan]({% image_path 08-postgresql-012.png %}){:width="1200px"}

Set Body で設定した情報が追加されて、取得してきたデータにも反映されています。
Logの確認後、`Ctrl+C` もしくは、ターミナル右上のゴミ箱のアイコンをクリックして、終了してください。

実際に、PostgreSQL にアクセスして確認をしてみましょう。
OpenShift DevSpaces の Terminal を開き、postgresql の pod にログインし、postgreSQLのコマンドを実行してみてください。

```
oc exec -it -n {{ OPENSHIFT_USER }}-dev -- /bin/bash
psql sampledb
```

products テーブル の 中身を確認してみましょう。`select * from products;` と入力してください。

![](images/08-postgresql-013.png)
![karavan]({% image_path 08-postgresql-013.png %}){:width="400px"}

確認後、`Ctrl+C` もしくは、ターミナル右上のゴミ箱のアイコンをクリックして、終了してください。
また、作成した `postgresql.camel.yaml` を `temp` フォルダに移動をしておいてください。 

---

### 参考リンク

* [Red Hat Integration - Kamelets リファレンス](https://access.redhat.com/documentation/ja-jp/red_hat_integration/2022.q4/html/kamelets_reference/postgres-sql-sink){:target="_blank"}