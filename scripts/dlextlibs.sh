#!/bin/bash

mkdir -p extlibs/KBridge
cd extlibs/KBridge

curl -L https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar > javax.servlet-api-3.1.0.jar

curl -L https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar > jetty-all-9.4.0.M1-uber.jar

