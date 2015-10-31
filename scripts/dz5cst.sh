
mkdir -p ../apprun

export TEST_APPDATA=../apprun/dzt

rm -rf ../apprun/dz

mono --debug ../be/target5/BEL_4_Base_mcs.exe --buildFile build/shared.txt --deployPath ../apprun/dzd --buildPath ../apprun/dz --emitLang cs -mainClass=Dz:Lui source/Dz.be source/Db.be source/BrowserUI.be
mcs -debug:pdbonly -warn:0 -out:../apprun/dz/BEL_4_Base_mcs.exe ../be/system/cs/be/BELS_Base/*.cs ../apprun/dz/Base/target/cs/be/BEL_4_Base/*.cs

#java -classpath ../be/target5/BEL_system_be_jv.jar:../be/target5/BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build/base.txt --deployPath ../apprun/dzd --buildPath ../apprun/dz --emitLang js --ownProcess false -mainClass=Dz:Eui source/DzEui.be

#cp ../apprun/dz/Base/target/js/be/BEL_4_Base/BEL_4_Base.js ../apprun/dz
cp source/Dz*.html ../apprun/dz
#cp extlibs/jetty/* ../apprun/dz
#cp extlibs/sqlite/* ../apprun/dz
#cp extlibs/bcastlejv/* ../apprun/dz

cd ../apprun/dz

mono --debug BEL_4_Base_mcs.exe test $*

cd ../../app
