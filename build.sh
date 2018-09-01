#!/bin/bash

SCRIPTFOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

DOCKER_MAVEN_JAVA=maven:3-jdk-8
DOCKER_XA65=oliverpavey/assembler-xa65:latest

# Create local volume for maven cache
if [ 0 -eq $(docker volume ls | grep maven-repo | wc -l) ]; then
    docker volume create --name maven-repo
fi

# Create and populate local volume
if [ 0 -eq $(docker volume ls | grep diskmaker-dfs | wc -l) ]; then

    docker volume create --name diskmaker-dfs

    # Put multi-line script into $BUILD_DISKMAKER_DFS
    read -r -d '' BUILD_DISKMAKER_DFS <<EOM
    cd ~  
    git clone https://github.com/OliverPavey/diskmaker-dfs.git  
    cd diskmaker-dfs  
    mvn clean package  
    cp target/*.jar /diskmaker-dfs/diskmaker-dfs.jar
EOM

    # Populate volume
    docker run --rm \
        --volume maven-repo:/root/.m2 \
        --volume diskmaker-dfs:/diskmaker-dfs \
        $DOCKER_MAVEN_JAVA \
        bash -c "$BUILD_DISKMAKER_DFS"
fi

# Put multi-line script into $ASSEMBLE_CODE
read -r -d '' ASSEMBLE_CODE <<EOM
cd /project/src
xa -M -o /project/out/hello hello.a65
EOM

# Ensure the output folder exists
mkdir -p $SCRIPTFOLDER/out

# Delete the expected outputs so we can tell if the assembly and disk build succeed
rm -f $SCRIPTFOLDER/out/hello > /dev/null
rm -f $SCRIPTFOLDER/out/helloWorld.ssd > /dev/null

# Assemble the code on suitable docker machine
docker run --rm \
    --volume diskmaker-dfs:/diskmaker-dfs \
    --volume $SCRIPTFOLDER:/project \
    $DOCKER_XA65 \
    bash -c "$ASSEMBLE_CODE"

if [ ! -e $SCRIPTFOLDER/out/hello ]; then
    echo "xa65 output not found"
    exit 2
else 
    # Put the code on an auto-bootable disk
    docker run --rm \
        --volume diskmaker-dfs:/diskmaker-dfs \
        --volume $SCRIPTFOLDER:/project \
        $DOCKER_MAVEN_JAVA \
        java -jar /diskmaker-dfs/diskmaker-dfs.jar /project/disk/disk.xml
fi

if [ ! -e $SCRIPTFOLDER/out/helloWorld.ssd ]; then
    echo "Diskmaker output not found."
    exit 3
else
    if [ ! -z "$BEEBEM_HOME" ]; then
        # Launch BeebEm with the new auto-bootable disk
        BEEBEM_EXE=$(echo $BEEBEM_HOME\\BeebEm.exe | sed s/\\\\/\\//g | sed s/C:/\\/c/g)
        $BEEBEM_EXE $SCRIPTFOLDER/out/helloWorld.ssd &
    fi
fi
