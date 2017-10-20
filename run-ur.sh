#!/bin/bash

#===================================================================
# UR ASSEMBLY PACKAGE
#===================================================================
# OBJECTIVE: RUN UNIVERSAL RECOMMENDER WITH PROPER DEPENDENCIES
#===================================================================
# Author: Nuno Gonçalves
# Email: nuno.goncalves@g.xarevision.pt
#===================================================================

set -ex

real_path() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

REL_SCRIPT_PATH="$(dirname $0)"
SCRIPTPATH=$(real_path $REL_SCRIPT_PATH)
DEPENDENCIES_FOLDER="${SCRIPTPATH}/dependencies"
DEPENDENCIES_LIB="${SCRIPTPATH}/lib"

execution_result(){
  EXITCODE=$?
  if [ $EXITCODE -ne 0 ]; then
    echo "Something went wrong!"
    cd $SCRIPTPATH
    exit $EXITCODE
  fi
}


compile_manhout(){
  pushd . 

  cd ${DEPENDENCIES_FOLDER}
  [[ ! -d "mahout" ]] && git clone https://github.com/apache/mahout mahout
  cd mahout
  
  if [[ ! $(ls $DEPENDENCIES_LIB | grep -cE ".*${1:0:4}.*.jar") -eq 4 ]];
  then
      echo "EXECUTING: mvn -Pscala-${1:0:4} -Pspark-${2:0:3} clean install -DskipTests"
      mvn -Pscala-${1:0:4} -Pspark-${2:0:3} clean install -DskipTests #THIS LINE NOT WORK IF SCALA VERSION IS UNDER 2.10; eg: 2.9.x
      execution_result
      cp -pf *.jar "${DEPENDENCIES_LIB}/"
  fi
 
  PIO_MAHOUT_VERSION=$(mvn help:evaluate -Dexpression=project.version | grep -v "^\[" | sed -E 's/(.*)(-.*)/\1/')
  
  popd
}


usage(){
cat<<EOF
USAGE: run-ur.sh -l [PredictionIO-scala-version] -s [PredictionIO-spark-version] -e [PredictionIO-elastic-version]

  l,		Version of scala that PredictionIO is running
  s,		Version of spark that PredictionIO is running
  e,		Version of elasticsearch that PredictionIO is running
  h,		Help

PLEASE: Clone the project from the git to be able to undo changes.

EXAMPLE: run-ur.sh -l 2.11.8 -s 2.1.0 -e 1.7.5
EOF

exit
}

while getopts :l:s:e:h FLAG;
do
  case $FLAG in
	l) PIO_SCALA_VERSION=${OPTARG}  			;;
	s) PIO_SPARK_VERSION=${OPTARG}  	        	;;
	e) PIO_ELASTIC_VERSION=${OPTARG}   			;;
	h) usage       						;;
	\?) echo "Invalid option: -$OPTARG"; usage >&2          ;;
  esac
done

shift $((OPTIND-1))

[[ -z "$PIO_SCALA_VERSION" ]]   &&  usage
[[ -z "$PIO_SPARK_VERSION" ]]   &&  usage
[[ -z "$PIO_ELASTIC_VERSION" ]] &&  usage

PIO_VERSION=$(pio version)


if [[ ! -d "$DEPENDENCIES_FOLDER" ]]; 
then
 mkdir -v "$DEPENDENCIES_FOLDER"
fi

if [[ ! -d "$DEPENDENCIES_LIB" ]]; 
then
 mkdir -v "$DEPENDENCIES_LIB"
fi

echo "CHECK DEPENDENCIES"

if [[ "$PIO_SCALA_VERSION"="2.11.*" ]];
then
 
 compile_manhout $PIO_SCALA_VERSION $PIO_SPARK_VERSION

 cp -vfp "${SCRIPTPATH}/patches/scala${PIO_SCALA_VERSION:0:4}/es${PIO_ELASTIC_VERSION:0:1}/build.sbt" build.sbt
 execution_result # CANNOT EXISTS FOR OTHER ES VERSION THAN 1.x.x or 5.x.x

 if [[ "${PIO_ELASTIC_VERSION:0:1}" -eq 5 ]];
 then
    cp -vfp "${SCRIPTPATH}/patches/scala${PIO_SCALA_VERSION:0:4}/es${PIO_ELASTIC_VERSION:0:1}/EsClient.scala" ${SCRIPTPATH}/src/main/scala
    execution_result
 fi
 
 [[ $(grep -c "unmanagedBase" build.sbt) -eq 0 ]] && echo 'unmanagedBase := baseDirectory.value / "'$DEPENDENCIES_LIB'"' >> build.sbt

fi


echo "DEPENDENCIES OK"

export PIO_SCALA_VERSION
export PIO_SPARK_VERSION
export PIO_ELASTIC_VERSION
export PIO_MAHOUT_VERSION

echo "COMPILE UR"

sbt package assemblyPackageDependency
execution_result

echo "COMPILE OK"

echo "LAUNCH UR INTEGRATION TESTS - REMOVE user-engine.json if you run more than once"

./examples/integration-test

exit
