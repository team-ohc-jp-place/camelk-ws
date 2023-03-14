## Recipient List パターン
---

### 1. 目的

[RecipientList](https://camel.apache.org/components/{{ CAMEL_VERSION }}/eips/recipientList-eip.html){:target="_blank"} を使用して、Camel K で Route を動的に指定して分岐する方法を理解することを目的とします。

![](images/RecipientList.gif)
![karavan]({% image_path RecipientList.gif %})

---

### 2. Recipient　List を使用して Route を動的に指定する

OpenShift DevSpaces 左のエクスプローラー上で、右クリックをして、メニューから `Karavan: Create Integration` を選択し、`recipientlist` と入力して Enter を押してください。`recipientlist.camel.yaml` という名前のファイルが作成されて、Karavan Designer のGUIが開きます。

続いて、Karavan Designer のGUIが開いたら、上部の `Create route` をクリックして、Route を作成しましょう。

`components` タブから `File` を探して選択をしてください。
右上のテキストボックスに `File` と入力をすると、絞り込みができます。

![](images/06-recipientlist-001.png)
![karavan]({% image_path 06-recipientlist-001.png %}){:width="800px"}

Route の source として、File コンポーネントが配置されます。
Route の File シンボルをクリックすると、右側にプロパティが表示されますので、確認してください。

Parameters は、以下を入力してください。

* **Directory Name**: data/input

> [Fileコンポーネント]({{ HOSTNAME_SUFFIX }}/workshop/camel-k/lab/file-component){:target="_blank"} の章で `data/input` フォルダを作成していない場合は、ワークスペースのルートフォルダ直下に、`data` フォルダを作成し、さらにdata フォルダの配下に、`input` フォルダを作成してください。

次に、別の Route を動的に呼び出しをするための Recipient List を追加します。
Route にマウスカーソルを持っていくと、File シンボルの下に小さな＋ボタンが現れますので、それをクリックし、`Routing` のタブから `Recipient List` を探して選択をしてください。

![](images/06-recipientlist-002.png)
![karavan]({% image_path 06-recipientlist-002.png %}){:width="800px"}

`Recipient List` のシンボルが File に続いて配置されます。
Recipient List シンボルをクリックすると、右側にプロパティが表示されますので、確認してください。

Parameters は、以下のように設定をします。
他の項目は、デフォルトのままで構いません。

* **Language**: simple
* **Expression**: ${bodyAs(String)}
* **Delimiter**: ; (セミコロン)

![](images/06-recipientlist-003.png)
![karavan]({% image_path 06-recipientlist-003.png %}){:width="1200px"}

次に、分岐先の Route を定義していきます。

`+ Create route` をクリックしてください。
source は、`components` タブから `Direct` を探して選択をしてください。
右上のテキストボックスに `Direct` と入力をすると、絞り込みができます。

![](images/06-recipientlist-004.png)
![karavan]({% image_path 06-recipientlist-004.png %}){:width="800px"}

新しい Route が作成されますので、source の `Direct` シンボルをクリックして、右側のプロパティを確認します。

Parameters は、以下のように設定をします。
他の項目は、デフォルトのままで構いません。

* **Name**: a

![](images/06-recipientlist-005.png)
![karavan]({% image_path 06-recipientlist-005.png %}){:width="1200px"}

また作成した Route の上部の Route名をクリックして、右側の Description に `direct:a` と入力してください。

![](images/06-recipientlist-006.png)
![karavan]({% image_path 06-recipientlist-006.png %}){:width="1200px"}

それでは、direct:a の Route が呼び出されかどうかを確認するための Log を出力しておきます。

Direct シンボルの下に小さな＋ボタンが現れますので、それをクリックし、`Routing` のタブから `Log` を探して選択をしてください。

Log の Messege は、`direct:a invoked` と入力をしておきます。

![](images/06-recipientlist-007.png)
![karavan]({% image_path 06-recipientlist-007.png %}){:width="1200px"}

同様にして、`+ Create route` をクリックし、`drect:b`、`direct:c` の Route を作成します。
Log を表示するのも忘れずに追加してください。

![](images/06-recipientlist-008.png)
![karavan]({% image_path 06-recipientlist-008.png %}){:width="1200px"}

テスト用のテキストファイルは、`file` フォルダに `test_03_recipientlist.txt` というファイルが用意されていますので、それを使用しましょう。

ファイルの中身は、

```
direct:a;direct:b
```
というテキストが格納されています。


それでは、実際に動かしてみます。
右上の ロケットのアイコン のボタンを押してください。

ターミナルが開き、作成したインテグレーションが JBang を通して実行されます。
特にエラーなく実行されたら、左のエクスプローラー上で、`file/test_03_recipientlist.txt` を右クリックして、`Copy` し、`data/input` フォルダの中に `Paste` して、ファイルを指定のフォルダに格納してください。

ターミナルが開き、作成したインテグレーションが JBang を通して実行されます。
特にエラーなく実行されたら、先ほど作成した `recipient.txt` を `data/input` フォルダに移動して格納をしてください。
ファイルが取得され、Route が実行されますので、ターミナルの Log を確認してください。
`direct:a invoked`、`direct:b invoked`、 の文字列が表示されていれば、OKです。 

![](images/06-recipientlist-009.png)
![karavan]({% image_path 06-recipientlist-009.png %}){:width="1200px"}

それでは、今度は `file/test_03_recipientlist.txt` の中身を、

```
direct:b;direct:c
```

に変更て保存し、再び `data/input` フォルダに移動して格納をしてください。
ターミナルの Log を確認すると、今後は `direct:b invoked`、`direct:c invoked`、 の文字列が表示されているはずです。 

![](images/06-recipientlist-010.png)
![karavan]({% image_path 06-recipientlist-010.png %}){:width="1200px"}

Logの確認後、`Ctrl+C` もしくは、ターミナル右上のゴミ箱のアイコンをクリックして、終了してください。
また、作成した `recipientlist.camel.yaml` を `temp` フォルダに移動をしておいてください。 