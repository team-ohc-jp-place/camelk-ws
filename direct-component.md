## Direct コンポーネント
---

### 1. 目的

[Direct](https://camel.apache.org/components/{{ CAMEL_VERSION }}/direct-component.html){:target="_blank"} を使用して、Camel K で Route を分岐する方法を理解することを目的とします。

![](images/direct.jpg)
![karavan]({% image_path direct.jpg %})

---

### 2. Direct を使用して Route を分岐する

OpenShift DevSpaces 左のエクスプローラー上で、右クリックをして、メニューから `Karavan: Create Integration` を選択し、`direct` と入力して Enter を押してください。`direct.camel.yaml` という名前のファイルが作成されて、Karavan Designer のGUIが開きます。

続いて、Karavan Designer のGUIが開いたら、上部の `Create route` をクリックして、Route を作成しましょう。

`components` タブから `Timer` を探して選択をしてください。
右上のテキストボックスに `Timer` と入力をすると、絞り込みができます。

![](images/05-direct-001.png)
![karavan]({% image_path 05-direct-001.png %}){:width="800px"}

Route の source として、Timer コンポーネントが配置されます。
Route の Timer シンボルをクリックすると、右側にプロパティが表示されますので、確認してください。

Parameters は、以下のように設定をします。

* **Timer Name**: 任意の名称
* **Repeat Count**: 1

![](images/05-direct-002.png)
![karavan]({% image_path 05-direct-002.png %}){:width="1200px"}

次に、別の Route を呼び出しするための `Direct` を追加します。
Route にマウスカーソルを持っていくと、`Timer` シンボルの下に小さな＋ボタンが現れますので、それをクリックします。

`components` タブから `Direct` を探して選択をしてください。
右上のテキストボックスに `Direct` と入力をすると、絞り込みができます。

![](images/05-direct-003.png)
![karavan]({% image_path 05-direct-003.png %}){:width="800px"}

`Direct` のシンボルが Timer に続いて配置されます。

Direct プロパティ の `Name` に、`secoundRoute` と入力をしてください。
すると入力欄のすぐ下に、`Create "secoundRoute"` と表示されますので、それをクリックします。

![](images/05-direct-004.png)
![karavan]({% image_path 05-direct-004.png %}){:width="1200px"}

scoundRoute が作成されて、source として Direct コンポーネントが配置されます。

![](images/05-direct-005.png)
![karavan]({% image_path 05-direct-005.png %}){:width="1200px"}

それでは、scoundRoute が呼び出されかどうかを確認するための Log を出力しておきます。

scoundRoute の Direct シンボルの下に小さな＋ボタンが現れますので、それをクリックし、`Routing` のタブから `Log` を探して選択をしてください。

Log の Messege は、`scoundRoute invoked` と入力をしておきます。

![](images/05-direct-006.png)
![karavan]({% image_path 05-direct-006.png %}){:width="1200px"}

それでは、実際に動かしてみます。
右上の ロケットのアイコン のボタンを押してください。

ターミナルが開き、作成したインテグレーションが JBang を通して実行されます。
特にエラーなく実行されたら、ターミナルの Log を確認してください。
`scoundRoute invoked` の文字列が表示されていれば、OKです。 

![](images/05-direct-007.png)
![karavan]({% image_path 05-direct-007.png %}){:width="1200px"}

Logの確認後、`Ctrl+C` もしくは、ターミナル右上のゴミ箱のアイコンをクリックして、終了してください。
また、作成した `direct.camel.yaml` を `temp` フォルダに移動をしておいてください。 

---

### 3. 参考

[Direct](https://camel.apache.org/components/{{ CAMEL_VERSION }}/direct-component.html){:target="_blank"} は、プロデューサーがメッセージ交換を送信するときに、任意のコンシューマーの同期的な呼び出しを提供します。

非同期な呼び出しを実施する場合は、[SEDA](https://camel.apache.org/components/{{ CAMEL_VERSION }}/seda-component.html){:target="_blank"} コンポーネントを使用することができます。

![](images/seda.jpg)
![karavan]({% image_path seda.jpg %})