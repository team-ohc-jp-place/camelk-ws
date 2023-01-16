Camel-K Workshop Guides
===

Guides のデプロイの手順

1. OpenShift にログインする（RHPDS、OpenShift Developer Sandox等）
2. Guides をデプロイするProjectを作る
3. 作成したProject名を引数に入れて、本リポジトリの `guide-deploy-sh` 実行する

```
sh ./guide-deploy.sh <Project-Name>
```