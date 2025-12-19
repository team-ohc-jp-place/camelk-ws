#!/bin/bash

# Step 1: Secret作成
oc create secret generic camel-users --from-file htpasswd=./openshift/90_user/htpasswd -n openshift-config

# Step 2: cluster-admin権限の付与
oc adm policy add-cluster-role-to-user cluster-admin admin

# Step 3: 現在のOAuth設定をファイルに出力
echo "Exporting current OAuth configuration to oauth.yaml..."
oc get oauth cluster -o yaml > ./openshift/90_user/oauth.yaml

# Step 4: spec: {} を削除してから、HTPasswdアイデンティティプロバイダーの設定を追記
echo "Removing empty spec and adding HTPasswd identity provider configuration..."
sed -i '' '/spec: {}/d' ./openshift/90_user/oauth.yaml

# Step 5: HTPasswdアイデンティティプロバイダーの設定を追記
echo "Adding HTPasswd identity provider configuration..."
cat << EOF >> ./openshift/90_user/oauth.yaml
spec:
  identityProviders:
  - htpasswd:
      fileData:
        name: camel-users # secret名
    mappingMethod: claim # アイデンティティーとユーザーオブジェクト間にマッピングが確立される方法
    name: camel-workshop # 任意のプロバイダー名
    type: HTPasswd
EOF

# Step 6: OAuth設定の更新
echo "Applying updated OAuth configuration..."
oc apply -f ./openshift/90_user/oauth.yaml

# Step 7: 更新完了メッセージ
echo "HTPasswd identity provider configuration applied successfully."