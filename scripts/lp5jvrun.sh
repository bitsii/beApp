cd ../apprun

export MYPWD=`pwd`

export MYHN=`hostname`

java -classpath "App/LocPing/*" be.BEL_4_Base.BEL_4_Base $*

cd ../app
