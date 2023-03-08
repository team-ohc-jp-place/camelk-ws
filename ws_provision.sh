#!/bin/bash

# Operator Install
oc apply -f ./openshift/01_operator/01_subs_camelk.yaml
oc apply -f ./openshift/01_operator/02_subs_amqstreams.yaml
oc apply -f ./openshift/01_operator/03_subs_devspaces.yaml
# cluster-admin でないユーザーに権限がない？
## Unable to retrieve the operator version: integrationplatforms.camel.apache.org "camel-k" is forbidden: User "user1" cannot get resource "integrationplatforms" in API group "camel.apache.org" in the namespace "default"
## Error: integrations.camel.apache.org "test" is forbidden: User "user1" cannot get resource "integrations" in API group "camel.apache.org" in the namespace "default"

# Waiting for getting operator subscription
echo "Waiting for getting amq-streams operator subscription"
while [ true ] ; do
  if [ "$(oc -n openshift-operators get subscription amq-streams -o=jsonpath='{.status.installPlanRef.name}')" ] ; then
    if [ "$(oc -n openshift-operators get subscription camel-k -o=jsonpath='{.status.installPlanRef.name}')" ] ; then
      if [ "$(oc -n openshift-operators get subscription devspaces -o=jsonpath='{.status.installPlanRef.name}')" ] ; then
        break
      fi
    fi
  fi
  echo -n .
  sleep 10
done

export PRJ_NAME=user1-dev

# Create Project (各user)
oc new-project $PRJ_NAME

sleep 10

# Kafka (各user)
## kafka-cluster
oc apply -f ./openshift/03_amqstreams/01_kafka_cluster.yaml -n $PRJ_NAME

# Waiting for deploying kafka-cluster
echo "Waiting for deploying kafka-cluster"
while [ true ] ; do
  if [ "$(oc -n $PRJ_NAME get kafka kafka-cluster -o=jsonpath='{@.status.clusterId}')" ] ; then
    break
  fi
  echo -n .
  sleep 10
done

## kafdrop
oc process -n $PRJ_NAME -f ./openshift/03_amqstreams/02_kafdrop.yaml --param=PJ_NAME=$PRJ_NAME | oc apply -f -
oc set env dc/kafdrop KAFKA_BROKERCONNECT=kafka-cluster-kafka-bootstrap.$PRJ_NAME.svc:9092 -n $PRJ_NAME

# Devspaces Create Workspaces
oc apply -f ./openshift/02_devspaces/01_che_cluster.yaml -n $PRJ_NAME

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

# Label
oc label deployment/emitter app.openshift.io/runtime=python --overwrite -n $PRJ_NAME
oc label dc/quarkusapp app.openshift.io/runtime=quarkus --overwrite -n $PRJ_NAME
oc label dc/postgresql app.openshift.io/runtime=postgresql --overwrite -n $PRJ_NAME
oc label dc/kafdrop app.openshift.io/runtime=amq --overwrite -n $PRJ_NAME

##
# PostgreSQLへの接続がOpenShift上でうまくできない
# postgresql.$PRJ_NAME.svc.cluster.local　これでOK
# oc exec -it $(oc get pods --field-selector status.phase=Running --no-headers -o=custom-columns=NAME:.metadata.name | grep postgresql) -- /bin/bash