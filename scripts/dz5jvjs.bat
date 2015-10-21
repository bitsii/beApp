java -classpath ..\be\target5\BEL_system_be_jv.jar;..\be\target5\BEL_4_Base_be_jv.jar be.BEL_4_Base.BEL_4_Base --buildFile build\base.txt --deployPath ..\apprun\dzd --buildPath ..\apprun\dz --emitLang js --ownProcess false -mainClass=Dz:Eui source\DzEui.be

copy /y ..\apprun\dz\Base\target\js\be\BEL_4_Base\BEL_4_Base.js ..\apprun\dz

cd ..\apprun\dz

java -classpath * be.BEL_4_Base.BEL_4_Base %*

cd ..\..\app
