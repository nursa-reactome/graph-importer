#!/bin/bash

#-----------------------------------------------------------
# Script to initial Neo4J and import Reactome MySQL data into
# a graph database.
#
# 4 March 2015
# Florian Korninger - fkorn@ebi.ac.uk
#  
#-----------------------------------------------------------

usage="
Usage: $(basename "$0") [options]

Options:
    -h  Program help/usage
    -i  Install Neo4j. DEFAULT: false
    -j  Import Reactome data. DEFAULT: false
    -f  Overwrite existing target database. DEFAULT: false
    -r  Reactome MySQL database host. DEFAULT: localhost
    -s  Reactome MySQL database port. DEFAULT: 3306
    -t  Reactome MySQL database name. DEFAULT: reactome
    -u  Reactome MySQL database user. DEFAULT: reactome
    -p  Reactome MySQL database password. DEFAULT: reactome
    -d  Neo4j target database parent directory. DEFAULT: /var/lib/neo4j/data/
    -e  Neo4j target database name. DEFAULT: graph.db
    -n  Neo4j password (ignored unless the -i Neo4j install option is enabled)

WARNING: Do not execute as sudo, permission will be asked when required.

Note: If the -i Neo4j install option is set, then the current stable Neo4j
version will be installed. If the -n Neo4j password option is set, then the
password will be updated after the Neo4j server is installed. The Neo4j server
can be upgraded to a newer version without uninstalling it beforehand.
Installation is only supported on Linux platforms.

WARNING: If no password is specified in conjunction with the -i Neo4j
install option, then the insecure default Neo4j password will remain
unchanged.
"

_REACTOME_HOST="localhost"
_REACTOME_PORT=3306
_REACTOME_DATABASE="reactome"
_REACTOME_USER="reactome"
_REACTOME_PASSWORD="reactome"
_GRAPH_PARENT_DIR="/var/lib/neo4j/data/databases"
_GRAPH_NAME="graph.db"
_OVERWRITE=false
_IMPORT_DATA=false
_INSTALL_NEO4J=false

# :h (help) should be at the very end of the while loop
while getopts ":r:s:t:u:p:v:d:e:m:n:ijh" option; do
  case "$option" in
    h) echo "$usage"
       exit 0
       ;;
    r) _REACTOME_HOST=$OPTARG
       ;;
    s) _REACTOME_PORT=$OPTARG
       ;;
    t) _REACTOME_DATABASE=$OPTARG
       ;;
    u) _REACTOME_USER=$OPTARG
       ;;
    p) _REACTOME_PASSWORD=$OPTARG
       ;;
    v) _REACTOME_PASSWORD=$OPTARG
       # TODO - Make this an error by 2019.
       echo "Note: Option -v is deprecated. Please use -p instead."
       ;;
    d) _GRAPH_PARENT_DIR=$OPTARG
       ;;
    e) _GRAPH_NAME=$OPTARG
       ;;
    f) _OVERWRITE=true
       ;;
    i) _INSTALL_NEO4J=true
       ;;
    j) _IMPORT_DATA=true
       ;;
    n) _NEO4J_PASSWORD=$OPTARG
       ;;
   \?) echo "Invalid option: -$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done

# There must be an install or import execution type option.
if ! $_INSTALL_NEO4J && ! $_IMPORT_DATA ; then
 echo "Missing argument execution type -i or -j. Usage:"
    echo "$usage"
    exit 1
fi;

# Are we running on Linux?
_PLATFORM=`uname -s`
case "$_PLATFORM" in
  Linux|CYGWIN*)
     # CygWin is close enough
     _IS_LINUX=true
     ;;
  *)
     _IS_LINUX=false
     ;;
esac

if $_INSTALL_NEO4J ; then
  if ! $_IS_LINUX ; then
    echo "Neo4j installation on non-Linux platform '$_PLATFORM' is not supported by this script."
    echo "Consult http://neo4j.com/docs/operations-manual/current/installation for Neo4j"
    echo "installation instructions on this platform."
    exit 1
  fi
  echo "Starting Neo4j installion..."
  sudo sh -c "wget -O - https://debian.neo4j.org/neotechnology.gpg.key | sudo apt-key add -" >/dev/null 2>&1
  sudo sh -c "echo 'deb http://debian.neo4j.org/repo stable/' >/tmp/neo4j.list" >/dev/null 2>&1
  sudo mv /tmp/neo4j.list /etc/apt/sources.list.d
  sudo apt-get update
  sudo apt-get install neo4j
  echo "Neo4j installation finished."
  if [ -z "$_NEO4J_PASSWORD" ]; then
    echo "WARNING: the new Neo4j installation password is insecure and should be reset."
  else
    echo "Removing old authentication..."
    if sudo service neo4j status >/dev/null 2>&1; then
      echo "Shutting down Neo4j DB..."
      if ! sudo service neo4j stop >/dev/null 2>&1; then
        echo "An error occurred while trying to shut down Neo4."
        exit 1
      fi
    fi
    sudo rm /var/lib/neo4j/data/dbms/auth
    if ! sudo service neo4j start >/dev/null 2>&1; then
      echo "An error occurred while trying to start Neo4j."
      exit 1
    fi
    echo "Setting new password for user Neo4j..."
    curl -H "Content-Type: application/json" -X POST -d '{"password":"'${_NEO4J_PASSWORD}'"}' -u neo4j:neo4j http://localhost:7474/user/neo4j/password >/dev/null >/dev/null 2>&1
  fi
fi

if $_IMPORT_DATA ; then
  if $_IS_LINUX ; then
    if sudo service neo4j status; then
      echo "Shutting down Neo4j in order to prepare data import..."
      if ! sudo service neo4j stop; then
        echo "An error occurred while trying to shut down Neo4j."
      exit 1
      fi
    fi
  fi

  # If the current working directory is not named graph-importer,
  # then clone the graph-importer into a temp directory.
  if [ "${PWD##*/}" == "graph-importer" ]; then
    _PROJECT_DIR="$PWD"
  else
    _TEMPDIR=`mktemp -d`
    _PROJECT_DIR="$_TEMPDIR"
    _REPO="https://github.com/reactome/graph-importer.git"
    echo "Cloning $_REPO into ${_TEMPDIR}..."
    cp -R $HOME/workspace/reactome/server/graph-importer/* $_PROJECT_DIR
    #git clone "$_REPO" "$_TEMPDIR"
  fi
  _JAR_FILE="$_PROJECT_DIR/target/BatchImporter.jar"
  if [ ! -f "$_JAR_FILE" ]; then
    echo "Packaging the reactome graph-importer project..."
    if ! (cd "$_PROJECT_DIR"; mvn -q clean package -U -DskipTests); then
      echo "An error occurred packaging the project."
      exit 1
    fi
    if [ ! -f "$_JAR_FILE" ]; then
      echo "The jar file was not found after the Maven build: $_JAR_FILE"
      exit 1
    fi
  fi
  echo "Importer jar file: $_JAR_FILE"

  # Remove trailing /
  _GRAPH_PARENT_DIR="${_GRAPH_PARENT_DIR%/}"
  # The parent directory must exist.
  if [ ! -d "$_GRAPH_PARENT_DIR" ]; then
    echo "Target graph parent folder must exist: $_GRAPH_PARENT_DIR"
    exit 1
  fi
  
  _GRAPH_DIR="${_GRAPH_PARENT_DIR}/${_GRAPH_NAME}"
  # Make the target graph directory, if necessary.
  if [ -d "$_GRAPH_DIR" ]; then
    if ! $_OVERWRITE ; then
      echo "Target graph database already exists: $GRAPH_DIR"
      exit 1
    fi
  elif ! mkdir "$_GRAPH_DIR"; then
    echo "Creating new database folder..."
    echo "Could not create the target graph database folder: $GRAPH_DIR"
    exit 1
  fi

  if $_IS_LINUX; then
    echo "Changing owner of the target Neo4j graph folder to ${USER}..."
    if ! sudo chown -R ${USER} ${_GRAPH_DIR}; then
      echo "An error occurred when trying to change owner of the target Neo4j graph folder."
      exit 1
    fi
  fi

  echo "Importing data to Neo4j..."
  if ! java -jar ${_JAR_FILE} -h ${_REACTOME_HOST} -s ${_REACTOME_PORT} -d ${_REACTOME_DATABASE} -u ${_REACTOME_USER} -p ${_REACTOME_PASSWORD} -o ${_GRAPH_DIR}; then
    echo "An error occurred during the data import process."
    exit 1
  fi
  echo "Data successfully imported into $_GRAPH_DIR."

  if $_IS_LINUX; then
    echo "Changing owner of Neo4j graph to user neo4j..."
    if ! sudo chown -R neo4j ${_GRAPH_DIR}; then
      echo "An error occurred when trying to change owner of the Neo4j graph."
      exit 1
    fi
    echo "Starting Neo4j database..."
    if ! sudo service neo4j start; then
      echo "Neo4j database could not be started."
      exit 1
    fi
  fi
  if [ -n "$_TEMPDIR" ]; then
    rm -r "$_TEMPDIR"
  fi
fi

echo `basename $0` "execution successful."
exit 0
