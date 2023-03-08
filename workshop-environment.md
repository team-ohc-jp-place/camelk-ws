## 利用環境 について
---

このワークショップでは、簡単な Camel K インテグレーションを作成し、動作を確認すると共に、Karavan Designer を使用した 実装のイメージを把握していただきます。

本ワークショップの開発環境は、オープンソースの[Eclipse Che](https://www.eclipse.org/che/)プロジェクトに基づいた、OpenShift Container Platform で動作するWebベースの統合開発環境(IDE)である、[Red Hat OpenShift DevSpaces](https://developers.redhat.com/products/openshift-dev-spaces/overview) を使用します。

* OpenShift DevSpaces の特徴
  * あらかじめ定義された設定でワークスペースを作成するため、オンボーディングを高速にできるとともに、個々の開発者の開発環境を統一できます。
  * Gitからクローンされるソースコードは、ブラウザからアクセスするワークスペース上で管理されるため、ローカル環境への複製が不要です。
  * Visual Studio Code 拡張機能と互換性があり、VSCodeユーザーでも利用しやすいです。

![](images/09-devspaces-001.png)
![karavan]({% image_path 09-devspaces-001.png %}){:width="800px"}

ワークショップを開始する前の事前準備として、OpenShift DevSpaces のワークスペースを作成しておきます。
こちらのリンクから、[OpenShift Web Console]({{ CONSOLE_URL }}) にアクセスをしてください。
OpenShift Web Console にアクセスするための情報は以下の通りです。

* **Username**: {{ OPENSHIFT_USER }}
* **Password**: {{ OPENSHIFT_PASSWORD }}

![](images/09-devspaces-002.png)
![karavan]({% image_path 09-devspaces-002.png %}){:width="600px"}

OpenShift Web Console にログイン後、左のメニュから `Developer` パースペクティブを選択し、その下のメニューから `Topology` ビューを開きます。Project名は `{{ OPENSHIFT_USER }}_dev` を選択してください。

![](images/09-devspaces-003.png)
![karavan]({% image_path 09-devspaces-003.png %}){:width="800px"}

### リソースについて

* **guides**: 本ワークショップのガイドドキュメント
* **devspaces**: OpenShift DevSpaces の インスタンス
* **kafka-cluster**: Kafka のクラスター
* **kafdrop**: Kafka 用の Web UI でブローカーやトピックなどの情報やメッセージの表示を行います
* **emitter**: Kafka トピックにメッセージを発信するPythonアプリ
* **quarkusapp**: Kafka トピックに送信されたメッセージを受信して表示するWebアプリ
* **postgresql**: サンプルデータが格納されたPostgreSQL

あらかじめ、KafkaやPostgreSQLといったリソースが用意されています。
ワークショップの中で、これらのデータソースを用いた連携をCamel Kで作成していきます。

### OpenShift DevSpacesの準備

こちらのリンクから、[OpenShift DevSpaces]({{ DEVSPACES_URL }}) のDashboard にログインします。
`Topology` ビューの OpenShift DevSpaces インスタンスの Route からもアクセスすることができます。

![](images/09-devspaces-004.png)
![karavan]({% image_path 09-devspaces-004.png %}){:width="800px"}

初回にアクセスすると、以下のような画面が表示されますので、`Log In with OpenShift` をクリックします。

![](images/09-devspaces-005.png)
![karavan]({% image_path 09-devspaces-005.png %}){:width="600px"}

`Username` と `Password` は、先ほどの OpenShift の 認証情報を入力してください。
ログインに成功すると、以下のような画面が表示されますので、`Allow selected permissions` をクリックしてください。

![](images/09-devspaces-006.png)
![karavan]({% image_path 09-devspaces-006.png %}){:width="600px"}

OpenShift DevSpaces の Dashboard が表示されます。
まだワークスペースは作成されておりません。
今回は、あらかじめ設定を用意したワークスペースをインポートしていきます。
`Import from Git` のテキスト欄に、`{{ DEVSPACES_REPO }}` と入力して、`Create & Open` をクリックします。

![](images/09-devspaces-007.png)
![karavan]({% image_path 09-devspaces-007.png %}){:width="600px"}

ワークスペースの作成が始まりますので、完了までしばらく待ちます。

![](images/09-devspaces-008.png)
![karavan]({% image_path 09-devspaces-008.png %}){:width="600px"}

ワークスペースの作成が完了すると、自動で以下のような画面にジャンプします。
`Trust the authors of all files in the parent folder 'projects'` にチェックを入れて、
`Yes, I trust the authors` をクリックします。その後、`Mark Done` をクリックしてください。
（エディタの外観を変えたい方は、設定を変更してみてください）

![](images/09-devspaces-009.png)
![karavan]({% image_path 09-devspaces-009.png %}){:width="600px"}

### Karavan Designer のインストール

[Karavan](https://github.com/apache/camel-karavan) は、Apache Camel 用の開発ツールキットです。ランタイムおよびパッケージとの統合や、イメージのビルド、kubernetesへのデプロイが可能な他、Camel K の Yaml DSL をグラフィカルに作成することができます。

![](images/we-karavan-vscode.png)
![karavan]({% image_path we-karavan-vscode.png %}){:width="800px"}

OpenShift DevSpaces の左端のVSCODE拡張機能のメニューを選択します。
RECOMMENDED に Karavan が表示されていますので、選択してインストールを実施してください。

![](images/09-devspaces-010.png)
![karavan]({% image_path 09-devspaces-010.png %}){:width="600px"}

インストールが完了すると、左端のメニューにCamelのアイコンが表示されます。
エクスプローラ上で右クリックをして、karavan のメニューが表示される様になればOKです。

![](images/09-devspaces-011.png)
![karavan]({% image_path 09-devspaces-011.png %}){:width="600px"}

### JBang　によるインテグレーション実施のテスト

[JBang](https://www.jbang.dev/)は、Javaをスクリプトのように実行できるツールです。日本での知名度はまだまだ低いですが、Quarkusのエンジニアが開発していることもあり。モダンなJava開発環境との連携が充実しています。

今回のワークショップでは、karavan Designer で作成した Camel K インテグレーションを、JBang を通して実行し、動作を確認していきます。

ワークスペースに、１秒間に１回、コンソールに **hello** と出力をするサンプル用のファイル（example.camel.yaml）があります。

エクスプローラ上で右クリックをして、`Open in Integrated terminal` を選択してください。

![](images/09-devspaces-012.png)
![karavan]({% image_path 09-devspaces-012.png %}){:width="300px"}

ターミナルが表示されますので、`jbang camel@apache/camel run example.camel.yaml` と入力をして実行してみてください。
ターミナルに以下のようなログが表示されればOKです。

![](images/09-devspaces-013.png)
![karavan]({% image_path 09-devspaces-013.png %}){:width="800px"}

ログを確認したら、`Ctrl+C` などで実行を終了してください。

#### Camel K CLI (Kamel)　による OpenShift　へのデプロイ

[CAMEL K CLI (Kamel)](https://camel.apache.org/camel-k/{{ CAMELK_VERSION }}/cli/cli.html)は、Kubernetes クラスタ上でインテグレーションを実行するためのエントリポイントです。

先ほどのサンプルを、OpenShiftへデプロイしてみます。

`kamel run example.camel.yaml -n {{ OPENSHIFT_USER }}_dev` とターミナルに入力してみてください。

ターミナルに以下のログが表示されて、OpenShiftに `example` のインテグレーションがデプロイされます。

![](images/09-devspaces-014.png)
![karavan]({% image_path 09-devspaces-014.png %}){:width="600px"}

OpenShift Web Console の [Topology view]({{ CONSOLE_URL }}/topology/ns/{{ OPENSHIFT_USER }}-dev) にアクセスして確認します。
新しく、`example` の Pod が起動していますので、 `view logs` をクリックします。

![](images/09-devspaces-015.png)
![karavan]({% image_path 09-devspaces-015.png %}){:width="800px"}

先ほどと同じように、１秒間に１回、**hello** の文字列が出力されているのを確認してください。

![](images/09-devspaces-015.png)
![karavan]({% image_path 09-devspaces-015.png %}){:width="800px"}
