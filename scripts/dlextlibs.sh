#!/bin/bash

mkdir -p extlibs/jv/wa
cd extlibs/jv/wa

curl -L https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar > javax.servlet-api-3.1.0.jar

curl -L https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.0.M1/jetty-all-9.4.0.M1-uber.jar > jetty-all-9.4.0.M1-uber.jar

#wget https://repo1.maven.org/maven2/org/eclipse/jetty/aggregate/jetty-all/9.4.17.v20190418/jetty-all-9.4.17.v20190418-uber.jar

curl -L https://bitbucket.org/xerial/sqlite-jdbc/downloads/sqlite-jdbc-3.19.3.jar > sqlite-jdbc-3.19.3.jar

#curl -L https://search.maven.org/remotecontent?filepath=org/apache/tomcat/tomcat-jdbc/9.0.30/tomcat-jdbc-9.0.30.jar > tomcat-jdbc-9.0.30.jar

#curl -L https://repo1.maven.org/maven2/com/mchange/c3p0/0.9.5.5/c3p0-0.9.5.5.jar > c3p0-0.9.5.5.jar

#curl -L https://repo1.maven.org/maven2/com/mchange/mchange-commons-java/0.2.19/mchange-commons-java-0.2.19.jar > mchange-commons-java-0.2.19.jar

mkdir ../ba
cp sqlite-jdbc-3.19.3.jar ../ba
#cp c3p0-0.9.5.5.jar ../ba
#cp mchange-commons-java-0.2.19.jar ../ba

mkdir ../ca
cp sqlite-jdbc-3.19.3.jar ../ca
#cp c3p0-0.9.5.5.jar ../ca
#cp mchange-commons-java-0.2.19.jar ../ca
