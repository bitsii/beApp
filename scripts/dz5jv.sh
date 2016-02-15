
mkdir -p ../apprun
mkdir -p ../apprun/App/Dz/Data

rm -rf ../apprun/App/Dz/App
mkdir -p ../apprun/App/Dz/App

java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/shared.txt --deployPath ../apprun/App/Dzd --buildPath ../apprun/App/Dz --emitLang jv -mainClass=Dz:Ui source/DzTest.be source/DzUi.be source/Db.be source/BrowserUI.be source/BrowserJvFx.be source/WebServer.be source/App.be

javac -classpath extlibs/jetty/*:extlibs/hsqldb/*:extlibs/bcastlejv/*:extlibs/javamail/* ../be/system/jv/be/BELS_Base/*.java ../apprun/App/Dz/Base/target/jv/be/BEL_4_Base/*.java

java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/base.txt --deployPath ../apprun/App/Dzd --buildPath ../apprun/App/Dz --emitLang js --ownProcess false -mainClass=Dz:Eui source/DzEui.be source/BrowserEUI.be

cd ../apprun/App/Dz/Base/target/jv
jar -cf ../../../BEL_4_Base_lui_jv.jar .
cd ../../../../../../app

cd ../be/system/jv
jar -cf ../../../apprun/App/Dz/BEL_4_Base_lib_jv.jar .
cd ../../../app

find ../be/system -name "*.class" -exec rm {} \;

cp ../apprun/App/Dz/Base/target/js/be/BEL_4_Base/BEL_4_Base.js ../apprun/App/Dz
cp scripts/uppic.sh ../apprun/App/Dz
cp scripts/uppic.bat ../apprun/App/Dz
cp scripts/playsound.sh ../apprun/App/Dz
cp source/Dz*.html ../apprun/App/Dz
cp extlibs/jetty/* ../apprun/App/Dz
cp extlibs/hsqldb/* ../apprun/App/Dz
cp extlibs/bcastlejv/* ../apprun/App/Dz
cp extlibs/javamail/* ../apprun/App/Dz

./scripts/dz5jvrun.sh $*
