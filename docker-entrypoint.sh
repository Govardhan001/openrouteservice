#!/usr/bin/env bash

graphs=/ors-core/data/graphs
tomcat_ors_config=/usr/local/tomcat/webapps/ors/WEB-INF/classes/ors-config.json
source_ors_config=/ors-core/openrouteservice/src/main/resources/ors-config.json
BBOX="${BBOX:-False}"
do_build_graphs=False

if [ -z "${CATALINA_OPTS}" ]; then
  export CATALINA_OPTS="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9001 -Dcom.sun.management.jmxremote.rmi.port=9001 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=localhost"
fi

if [ -z "${JAVA_OPTS}" ]; then
  export JAVA_OPTS="-Djava.awt.headless=true -server -XX:TargetSurvivorRatio=75 -XX:SurvivorRatio=64 -XX:MaxTenuringThreshold=3 -XX:+UseG1GC -XX:+ScavengeBeforeFullGC -XX:ParallelGCThreads=4 -Xms1g -Xmx2g"
fi

echo "CATALINA_OPTS=\"$CATALINA_OPTS\"" >/usr/local/tomcat/bin/setenv.sh
echo "JAVA_OPTS=\"$JAVA_OPTS\"" >>/usr/local/tomcat/bin/setenv.sh

if [ "${BUILD_GRAPHS}" = "True" ]; then
  rm -rf ${graphs}/*
fi

subdircount=$(find ${graphs} -maxdepth 1 -type d | wc -l)
if [[ "$subdircount" -eq 1 ]] && [ "${BBOX}" != "False" ]; then
  echo "Cut pbf with given bounding box ${BBOX}"
  rm -f /ors-core/data/osm_file.pbf
  osmium extract --bbox "${BBOX}" --progress /ors-core/osm_file.pbf --output /ors-core/data/osm_file.pbf
elif [[ "$subdircount" -eq 1 ]]; then
  echo "Using custom "
  rm -f /ors-core/data/osm_file.pbf
  cp /ors-core/osm_file.pbf /ors-core/data/osm_file.pbf
fi

echo "### openrouteservice configuration ###"
# if Tomcat built before, copy the mounted ors-config.json to the Tomcat webapp ors-config.json, else copy it from the source
if [ -d "/usr/local/tomcat/webapps/ors" ]; then
  echo "Tomcat already built: Copying /ors-conf/ors-config.json to tomcat webapp folder"
	cp -f /ors-conf/ors-config.json $tomcat_ors_config
else
  if [ ! -f /ors-conf/ors-config.json ]; then
    echo "No ors-config.json in ors-conf folder. Copy config from ${source_ors_config}"
    cp -f $source_ors_config /ors-conf/ors-config.json
  else
    echo "ors-config.json exists in ors-conf folder. Copy config to ${source_ors_config}"
    cp -f /ors-conf/ors-config.json $source_ors_config
  fi
  echo "### Package openrouteservice and deploy to Tomcat ###"
  mvn -q -f /ors-core/openrouteservice/pom.xml package -DskipTests &&
    cp -f /ors-core/openrouteservice/target/*.war /usr/local/tomcat/webapps/ors.war
  # Always set osm_file.pbf as the osm file for the first start.
  jq '.ors.services.routing.sources[0] = "data/osm_file.pbf"' $tomcat_ors_config |sponge $tomcat_ors_config
fi

/usr/local/tomcat/bin/catalina.sh run

# Keep docker running easy
exec "$@"
