#!/bin/bash

mkdir -p extlibs/IUBridge
cd extlibs/IUBridge

curl -L https://www.bouncycastle.org/download/bcprov-jdk15on-155.jar > bcprov-jdk15on-155.jar

curl -L https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar > javax.servlet-api-3.1.0.jar

curl -L https://repo1.maven.org/maven2/org/hsqldb/hsqldb/2.3.4/hsqldb-2.3.4.jar > hsqldb-2.3.4.jar

curl -L https://java.net/projects/javamail/downloads/download/javax.mail.jar > javax.mail.jar

curl -L https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar > jetty-all-9.4.0.M1-uber.jar

curl -L https://repo1.maven.org/maven2/com/jcraft/jsch/0.1.54/jsch-0.1.54.jar > jsch-0.1.54.jar

