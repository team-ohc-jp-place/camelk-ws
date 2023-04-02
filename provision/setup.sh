#!/bin/bash

if [ $# != 1 ]; then
    echo "引数にユーザー数を指定してください"
    echo 例 \: $0 5
    exit 1
fi

# config
export USER_COUNT=$1

# Create Project

for m in $(eval echo "{1..$USER_COUNT}"); do
  # Create Project (各user)
  oc new-project user${m}-dev
  oc new-project user${m}-devspaces
done
oc new-project devspaces
oc new-project knative-serving
oc new-project knative-eventing

# Operator Install
oc apply -f ./openshift/01_operator/01_subs_camelk.yaml
oc apply -f ./openshift/01_operator/02_subs_amqstreams.yaml
oc apply -f ./openshift/01_operator/03_subs_devspaces.yaml
oc apply -f ./openshift/01_operator/04_subs_serverless.yaml

# Waiting for getting operator subscription
echo "Waiting for getting operator subscription"
while [ true ] ; do
  if [ "$(oc -n openshift-operators get subscription amq-streams -o=jsonpath='{.status.installPlanRef.name}')" ] ; then
    if [ "$(oc -n openshift-operators get subscription red-hat-camel-k -o=jsonpath='{.status.installPlanRef.name}')" ] ; then
      if [ "$(oc -n openshift-operators get subscription devspaces -o=jsonpath='{.status.installPlanRef.name}')" ] ; then
        if [ "$(oc -n openshift-serverless get subscription serverless-operator -o=jsonpath='{.status.installPlanRef.name}')" ] ; then
          sleep 10
          break
        fi
      fi
    fi
  fi

  echo waiting...
  sleep 10
done

# Etherpad
oc new-project gpte-etherpad --display-name "OpenTLC Shared Etherpad"
oc new-app --template=postgresql-persistent \
  --param POSTGRESQL_USER=ether \
  --param POSTGRESQL_PASSWORD=ether \
  --param POSTGRESQL_DATABASE=etherpad \
  --param POSTGRESQL_VERSION=10 \
  --param VOLUME_CAPACITY=10Gi \
  --labels=app=etherpad_db

sleep 15

oc new-app -f https://raw.githubusercontent.com/wkulhanek/docker-openshift-etherpad/master/etherpad-template.yaml \
  -p DB_TYPE=postgres \
  -p DB_HOST=postgresql \
  -p DB_PORT=5432 \
  -p DB_DATABASE=etherpad \
  -p DB_USER=ether \
  -p DB_PASS=ether \
  -p ETHERPAD_IMAGE=quay.io/wkulhanek/etherpad:1.8.4 \
  -p ADMIN_PASSWORD=secret

# Devspaces Create Workspaces
oc project devspaces
while [ 1 ]; do
  CSV=$(oc -n openshift-operators get subscription devspaces -o=jsonpath='{.status.currentCSV}')
  STAT=$(oc -n openshift-operators get ClusterServiceVersion $CSV -o=jsonpath='{.status.phase}')
  if [ "$STAT" = "Succeeded" ] ; then
    sleep 10
    oc apply -f ./openshift/02_devspaces/01_che_cluster.yaml -n devspaces
    break
  fi
  echo waiting...
  sleep 5
done

# OpenShift Serverless
oc apply -f ./openshift/07_serverless/01_knative_serving.yaml
oc apply -f ./openshift/07_serverless/02_knative_eventing.yaml

for m in $(eval echo "{1..$USER_COUNT}"); do

  # config for user
  export PRJ_NAME=user${m}-dev
  export DEVSPACES_NAME=user${m}-devspaces
  export OPENSHIFT_USER=user${m}
  export OPENSHIFT_PASSWORD=openshift

  oc project $PRJ_NAME

  sleep 10

  oc adm policy add-role-to-user view $OPENSHIFT_USER -n $PRJ_NAME
  oc adm policy add-role-to-user view $OPENSHIFT_USER -n devspaces
  oc create sa camelk-user -n $PRJ_NAME
  oc adm policy add-scc-to-user anyuid -z camelk-user
  oc adm policy add-scc-to-user anyuid -z camelk-user -n $PRJ_NAME

  # Kafka (各user)
  ## kafka-cluster
  echo "Waiting for preparing amq-streams"
  while [ 1 ]; do
    CSV=$(oc -n openshift-operators get subscription amq-streams -o=jsonpath='{.status.currentCSV}')
    STAT=$(oc -n openshift-operators get ClusterServiceVersion $CSV -o=jsonpath='{.status.phase}')
    if [ "$STAT" = "Succeeded" ] ; then
      oc apply -f ./openshift/03_amqstreams/01_kafka_cluster.yaml -n $PRJ_NAME
      break
    fi
    echo waiting...
    sleep 5
  done

  # Waiting for deploying kafka-cluster
  echo "Waiting for deploying kafka-cluster"
  while [ true ] ; do
    if [ "$(oc -n $PRJ_NAME get kafka kafka-cluster -o=jsonpath='{@.status.clusterId}')" ] ; then
      sleep 10
      break
    fi
    echo waiting...
    sleep 10
  done

  ## kafdrop
  oc process -n $PRJ_NAME -f ./openshift/03_amqstreams/02_kafdrop.yaml --param=PJ_NAME=$PRJ_NAME | oc apply -f -
  oc set env dc/kafdrop KAFKA_BROKERCONNECT=kafka-cluster-kafka-bootstrap.$PRJ_NAME.svc:9092 -n $PRJ_NAME

  # Camel K (各user)
  oc apply -f ./openshift/06_camelk/01_role.yaml -n $PRJ_NAME
  sleep 5
  oc policy add-role-to-user workshop-user $OPENSHIFT_USER --role-namespace=$PRJ_NAME -n $PRJ_NAME

  ## examle
  echo "Waiting for preparing camel-k"
  while [ 1 ]; do
    CSV=$(oc -n openshift-operators get subscription red-hat-camel-k -o=jsonpath='{.status.currentCSV}')
    STAT=$(oc -n openshift-operators get ClusterServiceVersion $CSV -o=jsonpath='{.status.phase}')
    if [ "$STAT" = "Succeeded" ] ; then
      oc apply -f ./openshift/06_camelk/02_example.yaml -n $PRJ_NAME
      break
    fi
    echo waiting...
    sleep 5
  done

  # PostgreSQL (各user)
  ## PostgreSQL deploy
  oc process -f ./openshift/04_postgresql/01_postgresql.yaml -l app=postgresql \
      -p DATABASE_SERVICE_NAME=postgresql \
      -p POSTGRESQL_USER=demo \
      -p POSTGRESQL_PASSWORD=demo \
      -p POSTGRESQL_DATABASE=sampledb \
      | oc create -f -

  sleep 10

  ## PostgreSQL DataInput
  oc create configmap postgresql-config-map --from-file=./openshift/04_postgresql/02_provision_data.sh -n $PRJ_NAME
  oc set volume dc/postgresql --name=postgresql-config-volume --add -m /tmp/config-files -t configmap --configmap-name=postgresql-config-map -n $PRJ_NAME
  oc set env --from=configmap/postgresql-config-map dc/postgresql -n $PRJ_NAME
  oc set deployment-hook dc/postgresql --post -c postgresql \
    -e POSTGRESQL_HOSTNAME=postgresql.$PRJ_NAME.svc.cluster.local \
    -e POSTGRESQL_USER=demo \
    -e POSTGRESQL_PASSWORD=demo \
    --volumes=postgresql-config-volume \
    --failure-policy=abort -- /bin/bash /tmp/config-files/02_provision_data.sh -n $PRJ_NAME

  echo "Waiting for PostgreSQL to be running..."
  while [ 1 ]; do
    STAT=$(oc get pod postgresql-2-deploy --ignore-not-found --no-headers -o=custom-columns=STATUS:.status.phase)
    if [ "$STAT" = "Succeeded" ] ; then
      oc rollout latest dc/postgresql -n $PRJ_NAME
      break
    fi
    STAT=$(oc get pod postgresql-3-deploy --ignore-not-found --no-headers -o=custom-columns=STATUS:.status.phase)
    if [ "$STAT" = "Succeeded" ] ; then
      break
    fi
    echo "..."
    sleep 5
  done

  # Emmiter (各user)
  oc new-app centos/python-36-centos7~https://github.com/kamorisan/event-emmiter \
    --name=emitter \
    -e KAFKA_BROKERS=kafka-cluster-kafka-bootstrap.$PRJ_NAME.svc:9092 \
    -e KAFKA_TOPIC=incoming-topic \
    -e RATE=10 \
    -n $PRJ_NAME

  # QuarkusApp（各user）
  oc new-app --as-deployment-config --name quarkusapp \
      --docker-image="kamorisan/quarkusapp:v2" \
      -e KAFKA_BROKERS=kafka-cluster-kafka-bootstrap.$PRJ_NAME.svc:9092 \
      -e KAFKA_TOPIC=outcoming-topic \
      -n $PRJ_NAME

  oc apply -f ./openshift/05_quarkusapp/01_service_quarkusapp.yaml -n $PRJ_NAME
  oc apply -f ./openshift/05_quarkusapp/02_route_quarkusapp.yaml -n $PRJ_NAME

  # MinIo
  oc apply -f ./openshift/08_minio/01_minio.yaml -n $PRJ_NAME

  # Guides
  # get routing suffix
  oc create route edge dummy --service=dummy --port=8080 -n $PRJ_NAME
  ROUTE=$(oc get route dummy -o=go-template --template='{{ .spec.host }}' -n $PRJ_NAME)
  KAFDROP_URL=$(oc get route kafdrop -o=go-template --template='{{ .spec.host }}' -n $PRJ_NAME)
  WEBUI_URL=$(oc get route quarkusapp -o=go-template --template='{{ .spec.host }}' -n $PRJ_NAME)
  DEVSPACES_URL=$(oc get route devspaces -o=go-template --template='{{ .spec.host }}' -n devspaces)
  HOSTNAME_SUFFIX=$(echo $ROUTE | sed 's/^dummy-'$PRJ_NAME'\.//g')
  MASTER_URL=$(oc whoami --show-server)
  CONSOLE_URL=$(oc whoami --show-console)
  oc delete route dummy

  # Guide Provision
  oc -n $PRJ_NAME new-app quay.io/osevg/workshopper --name=guides \
      -e POSTGRESQL_SERVER=$POSTGRESQL_SERVER \
      -e MASTER_URL=$MASTER_URL \
      -e CONSOLE_URL=$CONSOLE_URL \
      -e KAFDROP_URL=$KAFDROP_URL \
      -e WEBUI_URL=$WEBUI_URL \
      -e DEVSPACES_URL=$DEVSPACES_URL \
      -e DEVSPACES_REPO="https://github.com/team-ohc-jp-place/camelk-ws-devspaces.git" \
      -e ROUTE_SUBDOMAIN=$HOSTNAME_SUFFIX \
      -e CAMEL_VERSION="3.20.x" \
      -e CAMELK_VERSION="1.11.x" \
      -e KAMELETS_VERSION="0.9.x" \
      -e OPENSHIFT_USER=$OPENSHIFT_USER \
      -e OPENSHIFT_PASSWORD=$OPENSHIFT_PASSWORD \
      -e CONTENT_URL_PREFIX="https://raw.githubusercontent.com/team-ohc-jp-place/camelk-ws/devspaces_v1" \
      -e WORKSHOPS_URLS="https://raw.githubusercontent.com/team-ohc-jp-place/camelk-ws/devspaces_v1/_camelk-workshop-guides.yml" \
      -e LOG_TO_STDOUT=true

  oc -n $PRJ_NAME expose svc/guides

  # Label
  oc label deployment/emitter app.openshift.io/runtime=python --overwrite -n $PRJ_NAME
  oc label dc/quarkusapp app.openshift.io/runtime=quarkus --overwrite -n $PRJ_NAME
  oc label dc/postgresql app.openshift.io/runtime=postgresql --overwrite -n $PRJ_NAME
  oc label dc/kafdrop app.openshift.io/runtime=amq --overwrite -n $PRJ_NAME

  oc delete Integration example -n $PRJ_NAME
  oc delete LimitRanges $PRJ_NAME-core-resource-limits -n $PRJ_NAME
  oc delete LimitRanges $DEVSPACES_NAME-core-resource-limits -n $DEVSPACES_NAME

  echo "Completed... \n"
  echo "http://guides-$PRJ_NAME.$HOSTNAME_SUFFIX/workshop/camel-k"

done
