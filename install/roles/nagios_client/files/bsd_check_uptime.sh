#!/bin/sh
# Dmitry Vayntrub 03/11/2009
#
# The plugin shows the uptime and optionally
# compares it against MIN and MAX uptime thresholds
#######################################################################
VERSION="check_uptime v1.04"

# Exit-Codes:
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

usage()
{
cat << EOF
usage: $0 [-c OPTION]|[-w OPTION] [-C OPTION]|[-W OPTION] [ -V ]

This script checks uptime and optionally verifies if the uptime
is below MINIMUM or above MAXIMUM uptime treshholds

OPTIONS:
   -h   Help
   -c   CRITICAL MIN uptime (minutes)
   -w   WARNING  MIN uptime (minutes)
   -C   CRITICAL MAX uptime (minutes)
   -W   WARNING  MAX uptime (minutes)
   -V   Version
EOF
}

while getopts c:w:C:W:Vv OPTION
do
     case $OPTION in
	c)
	   MIN_CRITICAL=`echo $OPTARG | grep -v "^-"`
	   [ ! "$?" = 0 ] && echo "Error: missing or illegal option value" && \
	   exit $STATE_UNKNOWN
	   ;;
	w)
	   MIN_WARNING=`echo $OPTARG | grep -v "^-"`
	   [ ! "$?" = 0 ] && echo "Error: missing or illegal option value" && \
	   exit $STATE_UNKNOWN
	   ;;
	C)
	   MAX_CRITICAL=`echo $OPTARG | grep -v "^-"`
	   [ ! "$?" = 0 ] && echo "Error: missing or illegal option value" && \
	   exit $STATE_UNKNOWN
	   ;;
	W)
	   MAX_WARNING=`echo $OPTARG | grep -v "^-"`
	   [ ! "$?" = 0 ] && echo "Error: missing or illegal option value" && \
	   exit $STATE_UNKNOWN
	  ;;
	V)
	   echo $VERSION
	   exit $STATE_OK
	   ;;
	v)
	   VERBOSE=1
	   ;;
	?)
	   usage
	   exit $STATE_UNKNOWN
	   ;;
     esac
done


UPTIME_REPORT=`uptime | tr -d ","`

if	echo $UPTIME_REPORT | grep -i day > /dev/null ; then
	DAYS=`echo $UPTIME_REPORT | awk '{ print $3 }'`
	HOURS=`echo $UPTIME_REPORT | awk '{ print $5}' | cut -f1 -d":"`
	if	echo $UPTIME_REPORT | grep -v hrs ; then
		MINUTES=`echo $UPTIME_REPORT | awk '{ print $5}' | cut -f2 -d":"`
	  else
		MINUTES=0
	fi

  elif	#in AIX 5:00 will show up as 5 hours, and in Solaris 2.6 as 5 hr(s), and in FreeBSD as 5 hrs
	echo $UPTIME_REPORT | egrep -e "hour|hr\(s\)|hrs" > /dev/null ; then
	HOURS=`echo $UPTIME_REPORT | awk '{ print $3}'`
	MINUTES=0
  else
	echo $UPTIME_REPORT | awk '{ print $3}' | grep ":" > /dev/null && \
	HOURS=`echo $UPTIME_REPORT | awk '{ print $3}' | cut -f1 -d":"`
	MINUTES=`echo $UPTIME_REPORT | awk '{ print $3}' | cut -f2 -d":"`
fi

UPTIME_MINUTES=`expr 0$DAYS \* 1440 + 0$HOURS \* 60 + 0$MINUTES`
UPTIME_MSG="${DAYS:+$DAYS Days,} ${HOURS:+$HOURS Hours,} $MINUTES Minutes"
 
if [ $MIN_CRITICAL ] && [ $UPTIME_MINUTES -lt $MIN_CRITICAL ] ; then
	echo "CRITICAL - system rebooted $UPTIME_MSG ago"
	exit $STATE_CRITICAL

  elif [ $MIN_WARNING ] && [ $UPTIME_MINUTES -lt $MIN_WARNING ] ; then
	echo "WARNING - system rebooted $UPTIME_MSG ago"
	exit $STATE_WARNING

  elif [ $MAX_CRITICAL ] && [ $UPTIME_MINUTES -gt $MAX_CRITICAL ] ; then
	echo "CRITICAL - system has not rebooted for $UPTIME_MSG"
	exit $STATE_CRITICAL

  elif [ $MAX_WARNING ] && [ $UPTIME_MINUTES -gt $MAX_WARNING ] ; then
	echo "WARNING - system has not rebooted for $UPTIME_MSG"
	exit $STATE_WARNING

  else
	echo "OK - uptime is $UPTIME_MSG"
	exit $STATE_OK
fi

