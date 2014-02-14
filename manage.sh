#!/bin/bash

# Your java project name. Defaults to current directory name if not set here.
PROJECT_NAME=

# Full path to your java project home location. Defaults to current directory if not set here.
PROJECT_HOME=

# Full path to your local Tomcat installation's home directory. 
# This is the directory that contains bin, conf, lib, logs, webapps, work, etc.
# Commonly used paths are: 
#   /sl/apache-tomcat-7.0.34
#   /catamaran/apache-tomcat-6.0.35
#   /catamaran/servers/[project_name]/tomcat
LOCAL_TOMCAT_HOME_DIR=/sl/apache-tomcat-7.0.34

# Flag to make this script create a symlink inside Tomcat's webapps directory back to 
# this project's src/main/webapp directory.  Set to 'false' if you are relying on Tomcat's 
# context configuration files located in TOMCAT_HOME/conf/Catalina/localhost. 
LOCAL_WEBAPP_CREATE_SYMLINK=true

# The name of your webapp when it's deployed locally
# Defaults to your maven pom.xml's [artifactId]-[version]. 
# 'ROOT' is the right choice if you want your application deployed in the root context of tomcat (i.e. accessible at http://localhost:8080/index.html).
LOCAL_WEBAPP_NAME=ROOT

# The name of your webapp when it's deployed to the server. 
# Defaults to your maven pom.xml's [artifactId]-[version]. 
# 'ROOT' is the right choice if you want your application deployed in the root context of tomcat (i.e. accessible at http://my.site.com/index.html).
REMOTE_WEBAPP_NAME=ROOT

# Where the war file will be copied to on remote server
# Defaults to /sl/apps/[PROJECT_HOME]/tomcat/webapps
# On Amazon AWS Linux servers, this is usually /usr/share/tomcatX/webapps
# On Ubuntu, this is usually /var/lib/tomcatX/webapps
# IMPORTANT: Make sure both the user you're logging in with (i.e. 'ec2-user') 
#            and the tomcat server user (i.e. 'tomcat7') can write to this directory
REMOTE_TOMCAT_WEBAPPS_DIR=/var/lib/tomcat7/myapps



# DO NOT EDIT ANYTHING BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING
# -----------------------------------------------------------------------

ECHO_PREFIX='[manage.sh]'

COMMAND=$1
COMMAND_ARG_1=$2
echo $ECHO_PREFIX "Running command '$COMMAND' .." 

# initialize common variables
CURRENT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURRENT_DIR_NAME=$(basename $CURRENT_DIR)
VERSION=`cat pom.xml | grep "version" | head -1 | sed -n -e 's/.*<version>\(.*\)<\/version>.*/\1/p'`
ARTIFACT_ID=`cat pom.xml | grep "artifactId" | head -1 | sed -n -e 's/.*<artifactId>\(.*\)<\/artifactId>.*/\1/p'`

# set project / build defaults
if [ -z "$PROJECT_NAME" ]; then
  PROJECT_NAME=$CURRENT_DIR_NAME
fi  
if [ -z "$PROJECT_HOME" ]; then
  PROJECT_HOME=$CURRENT_DIR
fi  
if [ -z "$LOCAL_WEBAPP_DIR" ]; then
  LOCAL_WEBAPP_DIR=$PROJECT_HOME/src/main/webapp
fi  

# set local runtime app defaults
if [ -z "$LOCAL_APPS_DIR" ]; then
  LOCAL_APPS_DIR=/sl/apps
fi
if [ -z "$LOCAL_MY_APP_DIR" ]; then
  LOCAL_MY_APP_DIR=$LOCAL_APPS_DIR/$PROJECT_NAME
fi
if [ ! -d $LOCAL_MY_APP_DIR ]; then
  mkdir -p $LOCAL_MY_APP_DIR
fi

if [ ! -d $LOCAL_TOMCAT_HOME_DIR ]; then
  echo $ECHO_PREFIX "Directory $LOCAL_TOMCAT_HOME_DIR was not found.  Make sure you edit this script and add value for this varliable.  Then make sure Tomcat is installed in that location, or create a symlink to an existing tomcat installation directory"
  exit 1;
fi

# set tomcat bin dir
if [ -z "$LOCAL_TOMCAT_BIN_DIR" ]; then
  LOCAL_TOMCAT_BIN_DIR=$LOCAL_TOMCAT_HOME_DIR/bin
fi

# set tomcat webapps dir 
if [ -z "$LOCAL_TOMCAT_WEBAPPS_DIR" ]; then
  LOCAL_TOMCAT_WEBAPPS_DIR=$LOCAL_TOMCAT_HOME_DIR/webapps
fi  
if [ -z "$LOCAL_WEBAPP_NAME" ]; then
  LOCAL_WEBAPP_NAME=$ARTIFACT_ID-$VERSION
fi

# set remote server defaults
if [ -z "$REMOTE_WEBAPP_NAME" ]; then
  REMOTE_WEBAPP_NAME=$ARTIFACT_ID-$VERSION
fi
if [ -z "$REMOTE_TOMCAT_WEBAPPS_DIR" ]; then
  REMOTE_TOMCAT_WEBAPPS_DIR=$LOCAL_TOMCAT_WEBAPPS_DIR
fi

# branch on command input
if [ "$COMMAND" == "start" ]; then
  cd $LOCAL_TOMCAT_BIN_DIR
  ./catalina.sh jpda start
  echo $ECHO_PREFIX "Finished command $COMMAND" 
  exit 0  
fi

# branch on command input
if [ "$COMMAND" == "run" ]; then
  cd $LOCAL_TOMCAT_BIN_DIR
  ./catalina.sh run
  echo $ECHO_PREFIX "Finished command $COMMAND" 
  exit 0  
fi

# branch on command input
if [ "$COMMAND" == "rerun" ]; then
  $CURRENT_DIR/manage.sh build  
  if [ $? != 0 ]; then
    echo $ECHO_PREFIX 'EXITING, BUILD ERRORS'
    exit 1;
  fi

  $CURRENT_DIR/manage.sh run 
  
  echo $ECHO_PREFIX "Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "stop" ]; then
  cd $LOCAL_TOMCAT_BIN_DIR
  ./catalina.sh stop
  echo $ECHO_PREFIX "Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "build" ]; then
  cd $PROJECT_HOME

  # Performs a maven war:inplace build 
  # so that local src file changes appear immediately
  echo $ECHO_PREFIX "Starting 'mvn compile war:inplace' .."
  mvn compile war:inplace
  if [ $? != 0 ]; then
    echo $ECHO_PREFIX 'EXITING, MAVEN ERRORS'
    exit 1;
  fi
  
  # Optionally create a symlink inside the local Tomcat/webapps directory back to the newly build webapp
  if [ "$LOCAL_WEBAPP_CREATE_SYMLINK" == "true" ]; then
    echo $ECHO_PREFIX "Creating symlink to src/main/webapp inside [$LOCAL_TOMCAT_WEBAPPS_DIR]"
    cd $LOCAL_TOMCAT_WEBAPPS_DIR 

    # First remove old symlink, if it exists
    if [ -L $LOCAL_WEBAPP_NAME ]; then
      echo $ECHO_PREFIX "Removing old symlink to [$LOCAL_WEBAPP_NAME] inside [$LOCAL_TOMCAT_WEBAPPS_DIR] .."
      rm $LOCAL_WEBAPP_NAME
    fi

    # existing webapp directory exists inside tomcat?  if so rename it.
    if [ -d $LOCAL_WEBAPP_NAME ]; then
      DT=$(date +"%Y%m%d%H%M%S")
      NEW_NAME=${LOCAL_WEBAPP_NAME}.${DT}
      echo $ECHO_PREFIX "Renaming webapp [$LOCAL_WEBAPP_NAME] in [$LOCAL_TOMCAT_WEBAPPS_DIR] to [$NEW_NAME].."
      mv $LOCAL_WEBAPP_NAME $NEW_NAME
    fi
      
    # Then create new symlink
    cd $LOCAL_TOMCAT_WEBAPPS_DIR
    ln -s $LOCAL_WEBAPP_DIR $LOCAL_WEBAPP_NAME          
  fi
  
  echo $ECHO_PREFIX "Finished command $COMMAND"
  exit 0  
fi

if [ "$COMMAND" == "clean" ]; then

  # maven clean
  echo $ECHO_PREFIX "Performing 'mvn clean' in $PROJECT_HOME .."
  cd $PROJECT_HOME
  mvn clean

  echo $ECHO_PREFIX "Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "restart" ]; then
  $CURRENT_DIR/manage.sh stop
  $CURRENT_DIR/manage.sh build
  if [ $? != 0 ]; then
    echo $ECHO_PREFIX 'EXITING, BUILD ERRORS'
    exit 1;
  fi
  $CURRENT_DIR/manage.sh start

  echo $ECHO_PREFIX "Finished command $COMMAND"
  exit 0  
fi

if [ "$COMMAND" == "status" ]; then
  STATUS=`ps -ef | grep $LOCAL_TOMCAT_BIN_DIR | grep -v "grep"`
  # TODO output something if empty
  echo $ECHO_PREFIX "Local tomcat 'ps -ef' status output:"
  echo "$STATUS"

  echo $ECHO_PREFIX "Finished command $COMMAND"
  exit 0  
fi

if [ "$COMMAND" == "status-all" ]; then
  STATUS=`ps -ef | grep "java" | grep -v "grep"`
  # TODO output something if empty
  echo $ECHO_PREFIX "Local java 'ps -ef' status output:"
  echo "$STATUS"

  echo $ECHO_PREFIX "Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "deploy" ]; then

  # Validate command line parameters
  if [ -z "$COMMAND_ARG_1" ]; then
    echo $ECHO_PREFIX "Please specify target server hostname (as you would specify a ssh/scp host)"
    exit 1
  fi  

  # Stop local server if running
  $CURRENT_DIR/manage.sh stop

  # Then build a war
  echo ECHO_PREFIX "Running 'mvn compile war:war' .."
  mvn compile war:war
  if [ $? != 0 ]; then
    echo $ECHO_PREFIX 'EXITING, MAVEN ERRORS'
    exit 1;
  fi

  # Copy to remote
  echo $ECHO_PREFIX " Copying war file to $COMMAND_ARG_1"
  scp target/$ARTIFACT_ID-$VERSION.war $COMMAND_ARG_1:$REMOTE_TOMCAT_WEBAPPS_DIR/$REMOTE_WEBAPP_NAME.war
  
  echo $ECHO_PREFIX "Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "install-jar" ]; then

  # Validate command line parameters
  if [ -z "$COMMAND_ARG_1" ]; then
    echo $ECHO_PREFIX "Please specify jar file to install into local maven repository)"
    exit 1
  fi  

  # Then build a war
  echo $ECHO_PREFIX "Running 'mvn install:install-file ' .."
  mvn install:install-file -D
  # finish this later: http://ianibbo.blogspot.com/2009/04/google-apis-maven2-artifacts.html
  # and http://javastack.blogspot.com/2009/11/adding-jar-to-local-file-system-maven2.html

  echo $ECHO_PREFIX "Finished command $COMMAND" 
  exit 0  
fi

# Command not recognized
echo "Usage: manage.sh command [arg1]"
echo "Valid commands are:"
echo "  run           (starts tomcat with visible log output and no remote debugger support)"
echo "  rerun         (builds then starts tomcat with visible log output and no remote debugger support)"
echo "  start         (starts tomcat with remote debugger port)"
echo "  stop          (stops tomcat)"
echo "  restart       (stops, builds, then starts tomcat with remote debugger port)"
echo "  build         (compiles java and builds webapp with local web symlinks)"
echo "  clean         (removes local web symlinks and does maven clean which removes /target)"
echo "  build-war     (compiles java, builds webapp with no symlinks)"
echo "  deploy [srv]  (build-war, scp war to server)"
echo "  status        (shows any running java processes matching current project name)"
echo "  status-java   (shows all running java processes)"
echo " "

# echo paths so user can verify them
echo "manage.sh is using these settings (edit file manage.sh if this doesn't look right):" 
echo "    PROJECT_NAME: $PROJECT_NAME" 
echo "    PROJECT_HOME: $PROJECT_HOME" 
echo "    LOCAL_WEBAPP_DIR: $LOCAL_WEBAPP_DIR" 
echo "    LOCAL_TOMCAT_BIN_DIR: $LOCAL_TOMCAT_BIN_DIR" 
echo "    LOCAL_TOMCAT_WEBAPPS_DIR: $LOCAL_TOMCAT_WEBAPPS_DIR" 
echo "    LOCAL_WEBAPP_NAME: $LOCAL_WEBAPP_NAME" 
echo "    REMOTE_WEBAPP_NAME: $REMOTE_WEBAPP_NAME" 
echo "    REMOTE_TOMCAT_WEBAPPS_DIR: $REMOTE_TOMCAT_WEBAPPS_DIR"
echo " "


exit 1
