#!/bin/sh

# Convert the 1st arg to an absolute path.  OS specific
absolutePath() {
  case $OS in
  Windows_NT*)
    # for MKS Toolkit on Windows, an absolute path starts with a drive letter prefix or a UNC path.
    # Assume only forward slashes 
    case $1 in
      [a-zA-Z]:*)
        # Drive prefix
        echo $1
        ;;
      //*)
        # UNC path
        echo $1
        ;;
      /*)
        # path is absolute, but the drive is relative
        p=${mypwd##??}
        echo ${mypwd%%${p}}$1
        ;;
      *)
        # relative path
        echo ${mypwd}/$1
        ;;
    esac
    ;;
  *)
    # for everything else, an initial / indicates an absolute path
    case $1 in
      /*)
        # absolute path
        echo $1
        ;;
      *)
        # relative path
        echo ${mypwd}/$1
        ;;
    esac
    ;;
  esac
}

mypwd="`pwd`"

# Determine the location of this script...
# Note: this will not work if the script is sourced (. ./config_builder.sh)
SCRIPTNAME=$0
case ${SCRIPTNAME} in
 /*)  SCRIPTPATH=`dirname "${SCRIPTNAME}"` ;;
  *)  SCRIPTPATH=`dirname "${mypwd}/${SCRIPTNAME}"` ;;
esac

# Set the ORACLE_HOME relative to this script...
ORACLE_HOME=`cd "${SCRIPTPATH}/../.." ; pwd`
export ORACLE_HOME

# Set the MW_HOME relative to the ORACLE_HOME...
MW_HOME=`cd "${ORACLE_HOME}/.." ; pwd`
export MW_HOME

# Set the home directories...
. "${SCRIPTPATH}/setHomeDirs.sh"

OS=`uname -s`

umask 027

# set up common environment
. "${SCRIPTPATH}/commEnv.sh"

CLASSPATHSEP=:
case $OS in
Windows_NT*)
  CLASSPATHSEP=\;
;;
CYGWIN*)
  CLASSPATHSEP=\;
;;
esac
export CLASSPATHSEP

CLASSPATH="${FMWCONFIG_CLASSPATH}${CLASSPATHSEP}${DERBY_CLASSPATH}${CLASSPATHSEP}${POINTBASE_CLASSPATH}"
export CLASSPATH


while [ "$#" -gt "0" ]
do
  ARGNAME=`echo $1 | cut -d'=' -f1`
  ARGVALUE=`echo $1 | cut -d'=' -f2`

  if [ "`echo ${ARGVALUE} | cut -c1`" = "-" ] ; then
    echo "ERROR! Missing equal(=) sign. Arguments must be -name=value!"
    return 1
  fi

  if [ "${ARGVALUE}" = "" ] ; then
    echo "ERROR! Missing value! Arguments must be -name=value!"
    return 1
  fi

  case $ARGNAME in
     "-log")
        ARGVALUE=`absolutePath "${ARGVALUE}"`
        ARGUMENTS="${ARGUMENTS} ${ARGNAME}='${ARGVALUE}'"
        ;;
     *) ARGUMENTS="${ARGUMENTS} ${ARGNAME}='${ARGVALUE}'";;
  esac
  shift
done
export ARGUMENTS

cd "${COMMON_COMPONENTS_HOME}/common/lib"

if [ -d "${JAVA_HOME}" ]; then
 eval '"${JAVA_HOME}/bin/java"' '${MEM_ARGS}' -Dprod.props.file='"${WL_HOME}/.product.properties"' com.oracle.cie.wizard.WizardController -target=template ${ARGUMENTS}
else
 echo JAVA_HOME not set
 exit 1
fi
