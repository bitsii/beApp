#!/bin/bash

mkdir -p extlibs/jv/wa
cd extlibs/jv/wa

curl -L https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar > javax.servlet-api-3.1.0.jar

curl -L https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar > jetty-all-9.4.0.M1-uber.jar

curl -L https://bitbucket.org/xerial/sqlite-jdbc/downloads/sqlite-jdbc-3.19.3.jar > sqlite-jdbc-3.19.3.jar

mkdir ../ba
cp sqlite-jdbc-3.19.3.jar ../ba

mkdir ../ca
cp sqlite-jdbc-3.19.3.jar ../ca

mkdir ../ba
cp sqlite-jdbc-3.19.3.jar ../ba

mkdir ../ca
cp sqlite-jdbc-3.19.3.jar ../ca
