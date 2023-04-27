## Camel/Kafka/Debezium を使ったDBの同期
---

### 1. 目的

**Camel/Kafka/Debezium** を使用して、データベース間の同期を行う仕組みを構築します。

![](images/11-dbsync-001.png)
![karavan]({% image_path 11-dbsync-001.png %}){:width="600px"}

#### Debezium について

[Debezium](https://debezium.io/){:target="_blank"} は **Kafka Connect** の仕組みを使用したチェンジデータキャプチャの基盤となる製品です。
データベースに発生した更新イベントをキャプチャして、その更新イベントを **Kafka** のトピックにメッセージとして送信することによって、
その変更内容を **Kafka** に接続している他のシステムに、ニアリアルタイムに連携させることができるようになります。

![](images/11-dbsync-002.png)
![karavan]({% image_path 11-dbsync-002.png %}){:width="800px"}

#### AtlasMap について

[AtlasMap](https://debezium.io/){:target="_blank"} はデータマッピングソリューションです。
データマッピングというのは、あるサービスと別のサービス（またはデータベースなど）を接続するときに、どの項目をどの項目に移送するのか、または編集を施すのか、といった作業のことです。
AtlasMap Data Mapper UI キャンバスを使用してデータマッピングを設計し、ランタイム エンジンを介してそのデータマッピングを実行することができます。
[camel-atlasmap](https://camel.apache.org/components/{{ CAMEL_VERSION }}/atlasmap-component.html){:target="_blank"} コンポーネントを使用して、Apache Camel ルートの一部としてデータ マッピングを実行することもできます。

![](images/11-dbsync-003.png)
![karavan]({% image_path 11-dbsync-003.png %}){:width="1200px"}

※ 現時点においては、**camel-atlasmap** は Red Hatのサポートではなく、コミュニティサポートです。

#### このセクションで作成する内容

* 以下のコンポーネントは既に用意されています
  * 同期元、同期先のPostgreSQL
    * postgresql
    * postgresql-replica
  * 同期元のPostgreSQLの変更ログをキャプチャするDebezium
* 実装する Camelルート
  * DBイベントを受信する Kafka Source
  * データマッピングで必要な項目を抽出
  * CREATE/DELETE/UPDATE で処理を分岐して、同期先の PostgreSQL を操作


![](images/11-dbsync-004.png)
![karavan]({% image_path 11-dbsync-004.png %}){:width="1200px"}

---

### 2. Debeziumからのログを受信する

前章の [PostgresSQL との連携]({{ HOSTNAME_SUFFIX }}/workshop/camel-k/lab/postgresql-sink){:target="_blank"} で 使用したデータベースは、`Debezium` にて変更ログをキャプチャし、Kafkaイベントに変換するようになっています。

[Kafdrop](http://{{ KAFDROP_URL }}){:target="_blank"} というツールで、Kafka トピックに送信されたメッセージの内容を確認することができます。

こちらのリンクから、[debezium.public.products](http://{{ KAFDROP_URL }}/topic/debezium.public.products/messages?partition=0&offset=0&count=100&keyFormat=DEFAULT&format=DEFAULT){:target="_blank"} の内容を確認できます。アクセスして確認してみてください。

![](images/11-dbsync-005.png)
![karavan]({% image_path 11-dbsync-005.png %}){:width="1200px"}

トピックにはメッセージが4件入っていると思います。
一番下のメッセージが、前章の最後に追加したレコードの内容に対応しています。

~~~
{
   "schema": {
      "type": "struct",
      "fields": [
         {
            "type": "int32",
            "optional": false,
            "default": 0,
            "field": "id"
         },
         {
            "type": "string",
            "optional": true,
            "field": "name"
         },
         {
            "type": "string",
            "optional": true,
            "field": "__op"
         },
         {
            "type": "string",
            "optional": true,
            "field": "__table"
         },
         {
            "type": "int64",
            "optional": true,
            "field": "__lsn"
         },
         {
            "type": "int64",
            "optional": true,
            "field": "__source_ts_ms"
         },
         {
            "type": "string",
            "optional": true,
            "field": "__deleted"
         }
      ],
      "optional": false,
      "name": "debezium.public.products.Value"
   },
   "payload": {
      "id": 4,
      "name": "melon",
      "__op": "c",
      "__table": "products",
      "__lsn": 23000152,
      "__source_ts_ms": 1682590725891,
      "__deleted": "false"
   }
}
~~~

`fields` にトピックの中の項目の属性情報があり、`payload` の中に実際の値が格納されています。
項目名の先頭に `__` がある項目は、変更イベントのメタデータです。

* **__op**: イベントが生成される原因となった操作
  * c: CREATE
  * r: READ
  * u: UPDATE
  * d: DELETE
* **__table**: 変更イベントが発生したテーブル名
* **__lsn**: Log Sequence Number
* **__source_ts_ms**: イベントのタイムスタンプ
* **__deleted**: ???

aaaa

---

### 参考リンク

* [Red Hat build of Debezium](https://access.redhat.com/documentation/en-us/red_hat_build_of_debezium){:target="_blank"}
* [AtlasMap](https://www.atlasmap.io/){:target="_blank"}