#!/bin/bash

export PRJ_NAME=$1

# get routing suffix
oc create route edge dummy --service=dummy --port=8080 -n $PRJ_NAME
ROUTE=$(oc get route dummy -o=go-template --template='{{ .spec.host }}' -n $PRJ_NAME)
HOSTNAME_SUFFIX=$(echo $ROUTE | sed 's/^dummy-'$PRJ_NAME'\.//g')
MASTER_URL=$(oc whoami --show-server)
CONSOLE_URL=$(oc whoami --show-console)
oc delete route dummy

# Guide Provision
oc -n $PRJ_NAME new-app quay.io/osevg/workshopper --name=guides \
    -e MASTER_URL=$MASTER_URL \
    -e CONSOLE_URL=$CONSOLE_URL \
    -e ROUTE_SUBDOMAIN=$HOSTNAME_SUFFIX \
    -e CAMEL_VERSION="3.18.x" \
    -e CONTENT_URL_PREFIX="https://raw.githubusercontent.com/team-ohc-jp-place/camelk-ws/main" \
    -e WORKSHOPS_URLS="https://raw.githubusercontent.com/team-ohc-jp-place/camelk-ws/main/_camelk-workshop-guides.yml" \
    -e LOG_TO_STDOUT=true
    
oc -n $PRJ_NAME expose svc/guides

# Postgresql
## pending...