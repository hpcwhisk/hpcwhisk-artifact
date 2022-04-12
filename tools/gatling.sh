#!/usr/bin/env bash

VERSION=3.5.1
GATLING=gatling-charts-highcharts-bundle-$VERSION
URL=https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/$VERSION/$GATLING-bundle.zip

pushd  $(dirname $0)
if ! [ -d $GATLING ]; then
    curl -O $URL
    unzip $GATLING-bundle.zip
    rm $GATLING-bundle.zip
fi

popd

exec $(dirname $0)/$GATLING/bin/gatling.sh -sf $(dirname $0)/gatling $@
