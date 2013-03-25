#!/bin/bash

# IMPORTANT: You must allow symlinks within your Tomcat webapps for this script to work.  
# Edit TOMCAT_HOME/conf/context.xml and change <Context> to <Context allowLinking="true">

# Your java project name. Defaults to current directory name if not set here.
PROJECT_NAME=

# Full path to your java project home location. Defaults to current directory if not set here.
PROJECT_HOME=

# Location of local exploded webapp. Defaults to [current dir]/target/[artifactId]-[version]
# Note that a symlink will be created in the local tomcat webapps directory which will point back to this directory.
LOCAL_WEBAPP_DIR=

# Your local Tomcat /bin directory, where 'catalina.sh' lives. Defaults to /sl/apps/[PROJECT_HOME]/tomcat/bin
LOCAL_TOMCAT_BIN_DIR=

# Your local Tomcat /webapps directory, where the local webapp will be deployed (via a symlink to LOCAL_WEBAPP_DIR). 
# Defaults to /sl/apps/[PROJECT_HOME]/tomcat/webapps
LOCAL_TOMCAT_WEBAPPS_DIR=

# The name of your webapp when it's deployed locally
# Defaults to your maven pom.xml's [artifactId]-[version]. 
# 'ROOT' is the right choice if you want your application deployed in the root context of tomcat (i.e. localhost/index.html).
LOCAL_WEBAPP_NAME=ROOT

# The name of your webapp when it's deployed to the server. 
# Defaults to your maven pom.xml's [artifactId]-[version]. 
# 'ROOT' is the right choice if you want your application deployed in the root context of tomcat (i.e. my.site.com/index.html).
REMOTE_WEBAPP_NAME=ROOT

# Where the war file will be copied to on remote server
# Defaults to LOCAL_TOMCAT_WEBAPPS_DIR
# On Ubuntu, this is commonly /var/lib/tomcat7/webapps
# IMPORTANT: Make both the user you're logging in with (i.e. 'sladmin') 
#            and the tomcat server user (i.e. 'tomcat7') can write to this directory
REMOTE_TOMCAT_WEBAPPS_DIR=/var/lib/tomcat7/myapps



# DO NOT EDIT ANYTHING BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING
# -----------------------------------------------------------------------

COMMAND=$1
COMMAND_ARG_1=$2
echo "[manage.sh] Running command '$COMMAND' .." 

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
  LOCAL_WEBAPP_DIR=$PROJECT_HOME/target/$ARTIFACT_ID-$VERSION
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

# set tomcat home
if [ -z "$LOCAL_TOMCAT_HOME_DIR" ]; then
  LOCAL_TOMCAT_HOME_DIR=$LOCAL_MY_APP_DIR/tomcat
fi

if [ ! -d $LOCAL_TOMCAT_HOME_DIR ]; then
  echo "Directory $LOCAL_TOMCAT_HOME_DIR was not found.  Install tomcat here, or create a symlink to an existing tomcat installation directory"
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
  echo "[manage.sh] Finished command $COMMAND" 
  exit 0  
fi

# branch on command input
if [ "$COMMAND" == "run" ]; then
  cd $LOCAL_TOMCAT_BIN_DIR
  ./catalina.sh run
  echo "[manage.sh] Finished command $COMMAND" 
  exit 0  
fi

# branch on command input
if [ "$COMMAND" == "rerun" ]; then
  $CURRENT_DIR/manage.sh build  
  $CURRENT_DIR/manage.sh run 
  
  echo "[manage.sh] Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "stop" ]; then
  cd $LOCAL_TOMCAT_BIN_DIR
  ./catalina.sh stop
  echo "[manage.sh] Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "build" ]; then
  cd $PROJECT_HOME

  # Performs a maven webapp build BUT replaces static web content with symlinks to the source files
  # so that local file changes appear immediately

  # First remove old symlinks to static web content
  if [ -f $LOCAL_WEBAPP_DIR ]; then
    echo "[manage.sh] Removing /static symlink from: $LOCAL_WEBAPP_DIR .."
    rm $LOCAL_WEBAPP_DIR/WEB-INF/freemarker 2> /dev/null
    rm $LOCAL_WEBAPP_DIR/static 2> /dev/null
  fi  

  # Then build which will move files from src/ to target/
  echo "[manage.sh] Running 'mvn compile war:exploded' .."
  mvn compile war:exploded
  
  # Remove newly copied static files from target/
  echo "[manage.sh] Removing web files from: $LOCAL_WEBAPP_DIR .."
  rm -r $LOCAL_WEBAPP_DIR/WEB-INF/freemarker 2> /dev/null
  rm -r $LOCAL_WEBAPP_DIR/static 2> /dev/null

  # Re-create the symlinks back to static files in the /src tree
  echo "[manage.sh] Creating symlinks from /target to static web content under /src .."
  cd $LOCAL_WEBAPP_DIR/WEB-INF/
  ln -s $PROJECT_HOME/src/main/webapp/WEB-INF/freemarker/ freemarker
  cd $LOCAL_WEBAPP_DIR
  ln -s $PROJECT_HOME/src/main/webapp/static/ static

  # Create a symlink in tomcat/webapps back to project's target directory
  if [ ! -L $LOCAL_TOMCAT_WEBAPPS_DIR/$LOCAL_WEBAPP_NAME ]; then
    echo "[manage.sh] Creating symlink from $LOCAL_TOMCAT_WEBAPPS_DIR/$LOCAL_WEBAPP_NAME to $LOCAL_WEBAPP_DIR .."
    cd $LOCAL_TOMCAT_WEBAPPS_DIR
    ln -s $LOCAL_WEBAPP_DIR $LOCAL_WEBAPP_NAME
  else 
    echo "[manage.sh] Webapp directory $LOCAL_TOMCAT_WEBAPPS_DIR/$LOCAL_WEBAPP_NAME exists already.  If your webapp doesn't start correctly, check that this directory points to the right webapp or delete it and this script will re-create it:"
    WEBAPP_LS_OUTPUT="`ls -l $LOCAL_TOMCAT_WEBAPPS_DIR/$LOCAL_WEBAPP_NAME`"
    echo "$WEBAPP_LS_OUTPUT"
  fi
  echo "[manage.sh] Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "clean" ]; then
  cd $PROJECT_HOME

  # First remove old symlinks
  if [ -f $LOCAL_WEBAPP_DIR ]; then
    echo "[manage.sh] Removing symlinks from: $LOCAL_WEBAPP_DIR .."
    rm $LOCAL_WEBAPP_DIR/WEB-INF/freemarker 2> /dev/null
    rm $LOCAL_WEBAPP_DIR/static 2> /dev/null
  fi  
  
  # Remove symlink in tomcat/webapps back to project's target directory
  echo "[manage.sh] Removing symlink or directory $LOCAL_WEBAPP_NAME inside $LOCAL_TOMCAT_WEBAPPS_DIR .."
  cd $LOCAL_TOMCAT_WEBAPPS_DIR
  rm $LOCAL_WEBAPP_NAME
  
  # Then maven clean
  echo "[manage.sh] Performing 'mvn clean' in $PROJECT_HOME .."
  cd $PROJECT_HOME
  mvn clean

  echo "[manage.sh] Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "restart" ]; then
  $CURRENT_DIR/manage.sh stop
  $CURRENT_DIR/manage.sh build
  $CURRENT_DIR/manage.sh start

  echo "[manage.sh] Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "status" ]; then
  STATUS=`ps -ef | grep $LOCAL_TOMCAT_BIN_DIR | grep -v "grep"`
  # TODO output something if empty
  echo "[manage.sh] Local tomcat 'ps -ef' status output:"
  echo "$STATUS"

  echo "[manage.sh] Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "status-all" ]; then
  STATUS=`ps -ef | grep "java" | grep -v "grep"`
  # TODO output something if empty
  echo "[manage.sh] Local java 'ps -ef' status output:"
  echo "$STATUS"

  echo "[manage.sh] Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "deploy" ]; then

  # Validate command line parameters
  if [ -z "$COMMAND_ARG_1" ]; then
    echo "[manage.sh] Please specify target server hostname (as you would specify a ssh/scp host)"
    exit 1
  fi  

  # Stop local server if running
  $CURRENT_DIR/manage.sh stop

  # First remove old symlinks
  if [ -f $LOCAL_WEBAPP_DIR ]; then
    echo "[manage.sh] Removing symlinks from: $LOCAL_WEBAPP_DIR .."
    rm $LOCAL_WEBAPP_DIR/WEB-INF/freemarker 2> /dev/null
    rm $LOCAL_WEBAPP_DIR/static 2> /dev/null
  fi  

  # Then build a war
  echo "[manage.sh] Running 'mvn compile war:war' .."
  mvn compile war:war

  # Copy to remote
  echo "[manage.sh] Copying war file to $COMMAND_ARG_1"
  scp target/$ARTIFACT_ID-$VERSION.war $COMMAND_ARG_1:$REMOTE_TOMCAT_WEBAPPS_DIR/$REMOTE_WEBAPP_NAME.war
  
  echo "[manage.sh] Finished command $COMMAND" 
  exit 0  
fi

if [ "$COMMAND" == "install-jar" ]; then

  # Validate command line parameters
  if [ -z "$COMMAND_ARG_1" ]; then
    echo "[manage.sh] Please specify jar file to install into local maven repository)"
    exit 1
  fi  

  # Then build a war
  echo "[manage.sh] Running 'mvn install:install-file ' .."
  mvn install:install-file -D
  # finish this later: http://ianibbo.blogspot.com/2009/04/google-apis-maven2-artifacts.html
  # and http://javastack.blogspot.com/2009/11/adding-jar-to-local-file-system-maven2.html

  echo "[manage.sh] Finished command $COMMAND" 
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