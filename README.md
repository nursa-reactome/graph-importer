[<img src=https://user-images.githubusercontent.com/6883670/31999264-976dfb86-b98a-11e7-9432-0316345a72ea.png height=75 />](https://reactome.org)

# Reactome Graph Database Batch Importer

## What is the Reactome Graph Batch Importer project

The Batch Importer is a tool used for initial data conversion from the
Reactome relational database to a graph database. To maximise import
performance the Neo4j Batch Importer is utilised to directly create the
Neo4j database file structure. This process is unsafe ignoring transactions,
constraints or other safety features. Constraints will be checked once
the import process has finished.

The Batch Importer generates the graph database dynamically depending
on the Model specified in the Reactome graph library. Depending on the
POJOs specified in Domain model, data will be automatically fetched
from corresponding Instances of the relational database. Annotations
used in the model help to indicate properties and relationships that
should be taken into account in the import process.

#### Project components used:

* [Neo4j](https://neo4j.com/download/) Community Edition - version 3.2.2
  or later
* Reactome [Graph Core](https://github.com/reactome/graph-core)

#### Reactome data import

Reactome data will be automatically be imported when running the
[script](https://raw.githubusercontent.com/reactome/graph-importer/master/setup-graph.sh)
```setup-graph.sh```. User executing this script will be asked for
password if permissions require it.

Another option could be cloning the git repository ```git clone
https://github.com/reactome/graph-importer.git```

* Script Usage
```console
./setup-graph
    -h  Program help/usage
    -i  Install Neo4j. DEFAULT: false
    -j  Import Reactome data. DEFAULT: false
    -r  Reactome MySQL database host. DEFAULT: localhost
    -s  Reactome MySQL database port. DEFAULT: 3306
    -t  Reactome MySQL database name. DEFAULT: reactome
    -u  Reactome MySQL database user. DEFAULT: reactome
    -p  Reactome MySQL database password. DEFAULT: reactome
    -d  Neo4j target database parent directory. DEFAULT: /var/lib/neo4j/data/
    -e  Neo4j target database name. DEFAULT: graph.db
    -n  Neo4j password (only set when Neo4j is installed)
```

:warning: Do not execute as sudo, permission will be asked when required

* Installing Neo4j (Linux only)
```console
./setup-graph -i
    -n Optional Neo4j password."
```

* Installing Neo4j in other platforms
    * [MAC OS X](http://neo4j.com/docs/operations-manual/current/installation/osx/)
    * [Windows](http://neo4j.com/docs/operations-manual/current/installation/windows/)

```console
By opening http://localhost:7474 and reaching Neo4j browser you're ready to import data.
```

* Importing Data

> :memo: Refer to [Extras](https://github.com/gsviteri/DemoLayout/new/master?readme=1#extras)
  in order to download the MySql database before starting.

```console
./setup-graph -j
    -h  Program help/usage
    -i  Install Neo4j. DEFAULT: false
    -j  Import Reactome data. DEFAULT: false
    -r  Reactome MySQL database host. DEFAULT: localhost
    -s  Reactome MySQL database port. DEFAULT: 3306
    -t  Reactome MySQL database name. DEFAULT: reactome
    -u  Reactome MySQL database user. DEFAULT: reactome
    -p  Reactome MySQL database password. DEFAULT: reactome
    -d  Neo4j target database parent directory. DEFAULT: /var/lib/neo4j/data/
    -e  Neo4j target database name. DEFAULT: graph.db
```

Example:
```
./setup-graph.sh -j -h localhost -s 3306 -t reactome -u reactome_user -p not2share -d ./target -e graph.db
```

#### Data Import without the script

Reactome data can be imported without the script using the `BatchImporter.jar` file:

    java -jar ./target/BatchImporter.jar [options]

:warning: **CAUTION:** In order for the import to succeed, please ensure the following:
  1. All permissions to the specified target folder are granted to the user executing
     the jar file.
  2. When using the new database, permissions to access the database are given to the
     effective user running the Neo4j service.
  3. Neo4j is stopped before and restarted after the import.
  
  The `setup-graph.sh` script attempts to perform these actions on Linux platforms only.

**Properties**

The jar file execution properties are as follows:
```java
    -h  Reactome MySQL database host. DEFAULT: localhost
    -s  Reactome MySQL database port. DEFAULT: 3306
    -d  Reactome MySQL database name. DEFAULT: reactome
    -u  Reactome MySQL database user. DEFAULT: reactome
    -p  Reactome MySQL database password. DEFAULT: reactome
    -o  Target output Neo4j database path. DEFAULT: ./target/graph.db
```
Note that the `-o` jar file option is the file path concatenation
of the `setup.sh` `-d` and `-e` options.

Example:
```java
java -jar BatchImporter.jar \
     -h localhost \
     -s 3306 \
     -d reactome \
     -u reactome_user \
     -p not2share \
     -o ./target/graph.db
```

#### Extras
* [1] [Reactome Graph Database](http://www.reactome.org/download/current/reactome.graphdb.tgz)
* [2] [Documentation](http://www.reactome.org/pages/documentation/developer-guide/graph-database/)
* [3] [MySQL dump database](http://www.reactome.org/download/current/databases/gk_current.sql.gz)
