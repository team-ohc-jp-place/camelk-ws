#!/bin/bash

# Operator Install
oc apply -f ./openshift/01_operator/01_subs_camelk.yaml
oc apply -f ./openshift/01_operator/02_subs_amqstreams.yaml
oc apply -f ./openshift/01_operator/03_subs_devspaces.yaml
# cluster-admin でないユーザーに権限がない？
## Unable to retrieve the operator version: integrationplatforms.camel.apache.org "camel-k" is forbidden: User "user1" cannot get resource "integrationplatforms" in API group "camel.apache.org" in the namespace "default"
## Error: integrations.camel.apache.org "test" is forbidden: User "user1" cannot get resource "integrations" in API group "camel.apache.org" in the namespace "default"

# Waiting for getting operator subscription
echo "Waiting for getting operator subscription"
while [ true ] ; do
  if [ "$(oc -n openshift-operators get subscription amq-streams -o=jsonpath='{.status.installPlanRef.name}')" ] ; then
    if [ "$(oc -n openshift-operators get subscription camel-k -o=jsonpath='{.status.installPlanRef.name}')" ] ; then
      if [ "$(oc -n openshift-operators get subscription devspaces -o=jsonpath='{.status.installPlanRef.name}')" ] ; then
        break
      fi
    fi
  fi
  echo waiting...
  sleep 10
done

# Project Name
export PRJ_NAME=user1-dev
export OPENSHIFT_USER=user1
export OPENSHIFT_PASSWORD=openshift

# Create Project (各user)
oc new-project $PRJ_NAME

sleep 10

oc adm policy add-role-to-user view $OPENSHIFT_USER -n $PRJ_NAME

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
    break
  fi
  echo waiting...
  sleep 10
done

## kafdrop
oc process -n $PRJ_NAME -f ./openshift/03_amqstreams/02_kafdrop.yaml --param=PJ_NAME=$PRJ_NAME | oc apply -f -
oc set env dc/kafdrop KAFKA_BROKERCONNECT=kafka-cluster-kafka-bootstrap.$PRJ_NAME.svc:9092 -n $PRJ_NAME

# Devspaces Create Workspaces
while [ 1 ]; do
  CSV=$(oc -n openshift-operators get subscription devspaces -o=jsonpath='{.status.currentCSV}')
  STAT=$(oc -n openshift-operators get ClusterServiceVersion $CSV -o=jsonpath='{.status.phase}')
  if [ "$STAT" = "Succeeded" ] ; then
    oc apply -f ./openshift/02_devspaces/01_che_cluster.yaml -n $PRJ_NAME
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
  -e KAFKA_TOPIC=my-topic \
  -e RATE=10 \
  -n $PRJ_NAME

# QuarkusApp（各user）
oc new-app --as-deployment-config --name quarkusapp \
    --docker-image="kamorisan/quarkusapp:v2" \
    -e KAFKA_BROKERS=kafka-cluster-kafka-bootstrap.$PRJ_NAME.svc:9092 \
    -e KAFKA_TOPIC=my-topic \
    -n $PRJ_NAME

oc apply -f ./openshift/05_quarkusapp/01_service_quarkusapp.yaml -n $PRJ_NAME
oc apply -f ./openshift/05_quarkusapp/02_route_quarkusapp.yaml -n $PRJ_NAME

# Guides
# get routing suffix
oc create route edge dummy --service=dummy --port=8080 -n $PRJ_NAME
ROUTE=$(oc get route dummy -o=go-template --template='{{ .spec.host }}' -n $PRJ_NAME)
HOSTNAME_SUFFIX=$(echo $ROUTE | sed 's/^dummy-'$PRJ_NAME'\.//g')
MASTER_URL=$(oc whoami --show-server)
CONSOLE_URL=$(oc whoami --show-console)
oc delete route dummy

# Guide Provision
oc -n $PRJ_NAME new-app quay.io/osevg/workshopper --name=guides \
    -e POSTGRESQL_SERVER=$POSTGRESQL_SERVER \
    -e MASTER_URL=$MASTER_URL \
    -e CONSOLE_URL=$CONSOLE_URL \
    -e ROUTE_SUBDOMAIN=$HOSTNAME_SUFFIX \
    -e CAMEL_VERSION="3.18.x" \
    -e KAMELETS_VERSION="0.9.x" \
    -e OPENSHIFT_USER=$OPENSHIFT_USER \
    -e OPENSHIFT_PASSWORD=$OPENSHIFT_PASSWORD \
    -e CONTENT_URL_PREFIX="https://raw.githubusercontent.com/team-ohc-jp-place/camelk-ws/devspaces_v1" \
    -e WORKSHOPS_URLS="https://raw.githubusercontent.com/team-ohc-jp-place/camelk-ws/devspaces_v1/_camelk-workshop-guides.yml" \
    -e LOG_TO_STDOUT=true

oc -n $PRJ_NAME expose svc/guides

echo "Completed... \n"
echo "http://guides-$PRJ_NAME.$HOSTNAME_SUFFIX/workshop/camel-k" 

# Label
oc label deployment/emitter app.openshift.io/runtime=python --overwrite -n $PRJ_NAME
oc label dc/quarkusapp app.openshift.io/runtime=quarkus --overwrite -n $PRJ_NAME
oc label dc/postgresql app.openshift.io/runtime=postgresql --overwrite -n $PRJ_NAME
oc label dc/kafdrop app.openshift.io/runtime=amq --overwrite -n $PRJ_NAME

##
# PostgreSQLへの接続がOpenShift上でうまくできない
# postgresql.$PRJ_NAME.svc.cluster.local　これでOK
# oc exec -it $(oc get pods --field-selector status.phase=Running --no-headers -o=custom-columns=NAME:.metadata.name | grep postgresql) -- /bin/bash