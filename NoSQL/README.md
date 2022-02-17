# Oracle NoSQL Database on Docker

Sample Docker build files to facilitate installation and environment setup for
DevOps users. For more information about Oracle NoSQL Database please see the
[Oracle NoSQL Database documentation](https://docs.oracle.com/en/database/other-databases/nosql-database/index.html).

This project offers sample container image configuration files for:

* [Oracle NoSQL Database Community Edition](ce/Dockerfile)

## Quick start: building the Oracle NoSQL Community Edition image

To build the Oracle NoSQL Community Edition container image, clone this
repository and run the following commands from the root of cloned repository:

```shell
cd NoSQL/ce/
docker build -t oracle/nosql .
```
or

```shell
cd NoSQL/ce/
docker build --build-arg KV_VERSION=20.3.19 --tag oracle/nosql:ce .
```

The resulting image will be available as `oracle/nosql:ce`. 
You can also pull the image directly from the GitHub Container Registry:

```shell
docker pull ghcr.io/oracle/nosql:latest-ce
docker tag ghcr.io/oracle/nosql:latest-ce oracle/nosql:ce
```

## Quick start: running Oracle NoSQL Database in a container

The steps outlined below are using Oracle NoSQL Database community edition, if
you are using Oracle NoSQL Database Enterprise Edition, please use the
appropriate image name.

Start up KVLite in a container. You must give it a name and provide a hostname. Startup of
KVLite is the default `CMD` of the image:

```shell
docker run -d --name=kvlite --hostname=kvlite --env KV_PROXY_PORT=8080 -p 8080:8080 oracle/nosql:ce
```

In a second shell, run a second container to ping the kvlite store
instance:

```shell
docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/kvstore.jar ping -host store -port 5000
```

Note the required use of `--link` for proper hostname check (actual KVLite
container is named `kvlite`; alias is `store`).

You can also use the Oracle NoSQL Command Line Interface (CLI). Start the
following container:

```shell

$ docker run --rm -ti --link kvlite:store oracle/nosql:ce  java -Xmx64m -Xms64m -jar lib/kvstore.jar version

20.3.19 2021-09-29 04:04:01 UTC  Build id: b8acf274b357 Edition: Community

$ docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/kvstore.jar runadmin -host store -port 5000 -store kvstore

  kv-> ping
   Pinging components of store kvstore based upon topology sequence #14
   10 partitions and 1 storage nodes
   Time: 2021-12-20 12:56:33 UTC   Version: 20.3.19
   Shard Status: healthy:1 writable-degraded:0 read-only:0 offline:0 total:1
   Admin Status: healthy
   Zone [name=KVLite id=zn1 type=PRIMARY allowArbiters=false masterAffinity=false]   RN Status: online:1 read-only:0 offline:0
   Storage Node [sn1] on dcbd8ff4f07c:5000    Zone: [name=KVLite id=zn1 type=PRIMARY allowArbiters=false masterAffinity=false]    Status: RUNNING   Ver: 20.3.19 2021-09-29 04:04:01 UTC  Build id: b8acf274b357 Edition: Community
        Admin [admin1]          Status: RUNNING,MASTER
        Rep Node [rg1-rn1]      Status: RUNNING,MASTER sequenceNumber:50 haPort:5003 available storage size:1023 MB


  kv-> put kv -key /SomeKey -value SomeValue
  Operation successful, record inserted.
  kv-> get kv -key /SomeKey
  SomeValue
  kv-> exit
```

You can also use the Oracle SQL Shell Command Line Interface (CLI). Start the
following container:

```shell
$ docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/sql.jar -helper-hosts store:5000 -store kvstore

  sql-> show tables
  tables
    SYS$IndexStatsLease
    SYS$MRTableAgentStat
    SYS$MRTableInitCheckpoint
    SYS$PartitionStatsLease
    SYS$SGAttributesTable
    SYS$StreamRequest
    SYS$StreamResponse
    SYS$TableStatsIndex
    SYS$TableStatsPartition
  sql-> exit

```

## Oracle NoSQL Database Proxy

The Oracle NoSQL Database Proxy is a middle-tier component that lets the Oracle NoSQL Database drivers communicate with the Oracle NoSQL Database cluster. 
The Oracle NoSQL Database drivers are available in various programming languages that are used in the client application.

The Oracle NoSQL Database Proxy is a server that accepts requests from Oracle NoSQL Database drivers and processes them using the Oracle NoSQL Database. 
The Oracle NoSQL Database drivers can be used to access either the Oracle NoSQL Database Cloud Service or an on-premises installation via the Oracle NoSQL Database Proxy. 
Since the drivers and APIs are identical, applications can be moved between these two options. 

You can deploy a container-based Oracle NoSQL Database store first for a prototype project, and move forward to Oracle NoSQL Database cluster for a production project.

Here is a snippet showing the connection from a Node.js program.

````
return new NoSQLClient({
  serviceType: ServiceType.KVSTORE,
  endpoint: 'nosql-container-host:8080'
});
````

## Using Oracle NoSQL Command-Line from an external host

**Note**: We recommend running NoSQL Command-Line doing a container to container connection as shown in the previous chapters. 
It allows starting the container without publishing all internal ports (KVPORT, KV_HARANGE, KV_SERVICERANGE) but only the KV_PROXY_PORT. 

For your developments, remember the SDK drivers will contact the Oracle NoSQL Database Proxy on KV_PROXY_PORT. 

If you need to run NoSQL Command-Line from a host outside any container, please follow those instructions.

Install Oracle NoSQL in your external host

```shell
KV_VERSION=20.3.19
rm -rf kv-$KV_VERSION
DOWNLOAD_ROOT=http://download.oracle.com/otn-pub/otn_software/nosql-database
DOWNLOAD_FILE="kv-ce-${KV_VERSION}.zip"
DOWNLOAD_LINK="${DOWNLOAD_ROOT}/${DOWNLOAD_FILE}"
curl -OLs $DOWNLOAD_LINK
jar tf $DOWNLOAD_FILE | grep "kv-$KV_VERSION/lib" > extract.libs
jar xf $DOWNLOAD_FILE @extract.libs 
rm -f $DOWNLOAD_FILE extract.libs
KVHOME=$PWD/kv-$KV_VERSION
```

Start up KVLite in a container. You must give it a name 
and provide a hostname. 
In this case, You need to publish all internal ports and the KV_PROXY_PORT.
- 5000 KVPORT
- 5010-5020 KV_HARANGE
- 5021-5049 KV_SERVICERANGE
- 8080 KV_PROXY_PORT

This hostname must be resolvable from the host outside the container. 
It could be an alias to the host running the docker commands.

```shell
$ cat /etc/hosts
10.0.0.143 nosql-container-host
10.0.0.143 kvlite-nosql-container-host
```

```shell
$ ping kvlite-nosql-container-host

PING kvlite-nosql-container-host (10.0.0.143) 56(84) bytes of data.
64 bytes from nosql-container-host (10.0.0.143): icmp_seq=1 ttl=64 time=0.259 ms
64 bytes from nosql-container-host (10.0.0.143): icmp_seq=2 ttl=64 time=0.241 ms
64 bytes from nosql-container-host (10.0.0.143): icmp_seq=3 ttl=64 time=0.192 ms
```

Startup of KVLite is the default `CMD` of the image:

You can use you current HOSTNAME as a value for the --hostname

```shell
docker run -d --name=kvlite --hostname=$HOSTNAME --env KV_PROXY_PORT=8080 -p 8080:8080 \
-p 5000:5000 -p 5010-5020:5010-5020 -p 5021-5049:5021-5049 -p 5999:5999 oracle/nosql:ce
```

Or, use an alias if you prefer

```shell
docker run -d --name=kvlite --hostname=kvlite-nosql-container-host --env KV_PROXY_PORT=8080 -p 8080:8080 \
-p 5000:5000 -p 5010-5020:5010-5020 -p 5021-5049:5021-5049 -p 5999:5999 oracle/nosql:ce
```

In a second shell, run the NoSQL command to ping the kvlite store
instance:

```shell
$ java -jar $KVHOME/lib/kvstore.jar ping -host kvlite-nosql-container-host -port 5000
```
Note: -host must be the same name used when starting the container

If you want to run the NoSQL command to ping the kvlite store from another container:

```shell
docker run --rm -ti --link kvlite:store oracle/nosql:ce \
  java -jar lib/kvstore.jar ping -host store -port 5000
```
Note the required use of --link for proper hostname check (actual KVLite container is named kvlite; alias is store).

If you want to run without --link, you cannot use any alias when starting the container (use HOSTNAME).  

You can also use the admin Oracle NoSQL Command Line Interface (CLI).

```shell
$ java -jar $KVHOME/lib/kvstore.jar runadmin -host kvlite-nosql-container-host -port 5000 -store kvstore
````

You can also use the Oracle SQL Shell Command Line Interface (CLI)

```shell
$ java -jar $KVHOME/lib/sql.jar -helper-hosts kvlite-nosql-container-host:5000 -store kvstore
````


## More information

For more information on [Oracle NoSQL](http://www.oracle.com/technetwork/database/database-technologies/nosqldb/overview/index.html)
please review the [product documentation](http://docs.oracle.com/cd/NOSQL/html/index.html).

The Oracle NoSQL Database Community Edition image contains the OpenJDK.

## Licenses

Oracle NoSQL Community Edition is licensed under the [APACHE LICENSE v2.0](https://docs.oracle.com/cd/NOSQL/html/driver_table_c/doc/LICENSE.txt).

OpenJDK is licensed under the [GNU General Public License v2.0 with the Classpath Exception](http://openjdk.java.net/legal/gplv2+ce.html)

The files in this repository folder are licensed under the [Universal Permissive License 1.0](/LICENSE.txt)

## Commercial Support in Containers

Oracle NoSQL Community Edition has **no** commercial support.

## Copyright

Copyright (c) 2017, 2022 Oracle and/or its affiliates.
