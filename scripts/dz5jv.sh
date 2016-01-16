
mkdir -p ../apprun
mkdir -p ../apprun/dz/Data

rm -rf ../apprun/dz/App
mkdir -p ../apprun/dz/App

java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/shared.txt --deployPath ../apprun/dzd --buildPath ../apprun/dz --emitLang jv -mainClass=Dz:Ui source/DzTest.be source/DzUi.be source/Db.be source/BrowserUI.be

javac -classpath extlibs/jetty/*:extlibs/sqlite/*:extlibs/derby/*:extlibs/bcastlejv/* ../be/system/jv/be/BELS_Base/*.java ../apprun/dz/Base/target/jv/be/BEL_4_Base/*.java

java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/base.txt --deployPath ../apprun/dzd --buildPath ../apprun/dz --emitLang js --ownProcess false -mainClass=Dz:Eui source/DzEui.be

cd ../apprun/dz/Base/target/jv
jar -cf ../../../BEL_4_Base_lui_jv.jar .
cd ../../../../../app

cd ../be/system/jv
jar -cf ../../../apprun/dz/BEL_4_Base_lib_jv.jar .
cd ../../../app

find ../be/system -name "*.class" -exec rm {} \;

cp ../apprun/dz/Base/target/js/be/BEL_4_Base/BEL_4_Base.js ../apprun/dz
cp scripts/uppic.sh ../apprun/dz
cp scripts/uppic.bat ../apprun/dz
cp scripts/playsound.sh ../apprun/dz
cp source/Dz*.html ../apprun/dz
cp extlibs/jetty/* ../apprun/dz
#cp extlibs/sqlite/* ../apprun/dz
cp extlibs/derby/* ../apprun/dz
cp extlibs/bcastlejv/* ../apprun/dz

cd ../apprun/dz

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "*" be.BEL_4_Base.BEL_4_Base $*

cd ../../app
