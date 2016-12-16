#!/bin/bash

mkdir -p extlibs/IUHub
cd extlibs/IUHub

wget https://www.bouncycastle.org/download/bcprov-jdk15on-155.jar
wget https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar
wget https://repo1.maven.org/maven2/org/hsqldb/hsqldb/2.3.4/hsqldb-2.3.4.jar
wget https://java.net/projects/javamail/downloads/download/javax.mail.jar
wget https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar
wget https://repo1.maven.org/maven2/com/jcraft/jsch/0.1.54/jsch-0.1.54.jar

