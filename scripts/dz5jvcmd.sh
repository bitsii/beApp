
mkdir -p ../apprun
mkdir -p ../apprun/dzdata

export TEST_APPDATA=../apprun/dzt

rm -rf ../apprun/dz

java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/shared.txt --deployPath ../apprun/dzd --buildPath ../apprun/dz --emitLang jv -mainClass=Dz:CmdUi source/Dz.be source/DzTest.be source/DzUi.be source/Db.be source/BrowserUI.be

javac -classpath extlibs/jetty/*:extlibs/sqlite/*:extlibs/bcastlejv/* ../be/system/jv/be/BELS_Base/*.java ../apprun/dz/Base/target/jv/be/BEL_4_Base/*.java

#java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/base.txt --deployPath ../apprun/dzd --buildPath ../apprun/dz --emitLang js --ownProcess false -mainClass=Dz:Eui source/DzEui.be

cd ../apprun/dz/Base/target/jv
jar -cf ../../../BEL_4_Base_lui_jv.jar .
cd ../../../../../app

cd ../be/system/jv
jar -cf ../../../apprun/dz/BEL_4_Base_lib_jv.jar .
cd ../../../app

find ../be/system -name "*.class" -exec rm {} \;

#cp ../apprun/dz/Base/target/js/be/BEL_4_Base/BEL_4_Base.js ../apprun/dz
cp source/Dz*.html ../apprun/dz
cp extlibs/jetty/* ../apprun/dz
cp extlibs/sqlite/* ../apprun/dz
cp extlibs/bcastlejv/* ../apprun/dz

cd ../apprun/dz

java -classpath "*" be.BEL_4_Base.BEL_4_Base $*

cd ../../app
