#!/bin/bash

export PRJ_NAME=$1

# Postgresql
oc process -f postgresql/postgresql.yaml -l app=postgresql \
    -p DATABASE_SERVICE_NAME=postgresql \
    -p POSTGRESQL_USER=demo \
    -p POSTGRESQL_PASSWORD=demo \
    -p POSTGRESQL_DATABASE=sampledb \
    | oc create -f -

sleep 10

oc create configmap postgresql-config-map --from-file=postgresql/provision_data.sh -n $PRJ_NAME
oc set volume dc/postgresql --name=postgresql-config-volume --add -m /tmp/config-files -t configmap --configmap-name=postgresql-config-map -n $PRJ_NAME
oc set env --from=configmap/postgresql-config-map dc/postgresql -n $PRJ_NAME
oc set deployment-hook dc/postgresql --post -c postgresql -e POSTGRESQL_HOSTNAME=postgresql.$PRJ_NAME.svc.cluster.local -e POSTGRESQL_USER=demo -e POSTGRESQL_PASSWORD=demo --volumes=postgresql-config-volume --failure-policy=abort -- /bin/bash /tmp/config-files/provision_data.sh -n $PRJ_NAME

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

oc expose dc/postgresql --type=LoadBalancer --name=postgresql-loadbalancer -n $PRJ_NAME

sleep 10

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
    -e CONTENT_URL_PREFIX="https://raw.githubusercontent.com/team-ohc-jp-place/camelk-ws/main" \
    -e WORKSHOPS_URLS="https://raw.githubusercontent.com/team-ohc-jp-place/camelk-ws/main/_camelk-workshop-guides.yml" \
    -e LOG_TO_STDOUT=true

oc -n $PRJ_NAME expose svc/guides

echo "Completed... \n"
echo "http://guides-$PRJ_NAME.$HOSTNAME_SUFFIX/workshop/camel-k" 