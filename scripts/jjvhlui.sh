
export TEST_APPDATA=../apprun/jotad

cp source/JotUi.html ../apprun/jo

java -classpath ../apprun/jo/*:extlibs/jetty/*:extlibs/sqlite/*:extlibs/bcastlejv/* be.BEL_4_Base.BEL_4_Base $*
