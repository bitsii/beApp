
mkdir -p ../apprun
mkdir -p ../apprun/dzdata

export TEST_APPDATA=../apprun/dzt

cd ../apprun/dz

java -classpath "*" be.BEL_4_Base.BEL_4_Base $*

cd ../../app
