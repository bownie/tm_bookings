#!/bin/sh

# process stdin and extract the goodness
#
EMAIL_NAME=""
EMAIL_EMAIL=""
EMAIL_ENQUIRY=""
EMAIL_TOUR=""
EMAIL_DATE=""
EMAIL_PARTICIPANTS=""
TMP_FILE="$HOME/tm_bookings/tmp/mysqlinsert.tmp"

LOG_FILE="$HOME/tm_bookings/logs/processMail.log"

# Process a line at a time
#
while read line
do
   if [ -z "${EMAIL_NAME}" ]
   then
     EMAIL_NAME=`echo $line|grep -e "Name[ 	]*:" |cut -d ':' -f 2| sed -e 's/^[ 	]*//g'| sed -e 's/=0D//g'`
   fi

   if [ -z "${EMAIL_EMAIL}" ]
   then
     EMAIL_EMAIL=`echo $line|grep -e "Email[ 	]*:" |cut -d ':' -f 2|cut -d '<' -f 1| sed -e 's/^[ 	]*//g'| sed -e 's/=0D//g'`
   fi

   if [ -z "${EMAIL_ENQUIRY}" ]
   then
     EMAIL_ENQUIRY=`echo $line|grep -e "Enquiry[ 	]*:" |cut -d ':' -f 2| sed -e 's/^[ 	]*//g'| sed -e 's/=0D//g'`
   fi

   if [ -z "${EMAIL_TOUR}" ]
   then
     EMAIL_TOUR=`echo $line|grep -e "Name of Tour[ 	]*:" |cut -d ':' -f 2| sed -e 's/^[ 	]*//g'| sed -e 's/=0D//g'`
   fi

   if [ -z "${EMAIL_DATE}" ]
   then
     EMAIL_DATE=`echo $line|grep -e "Date of Tour[ 	]*:" |cut -d ':' -f 2| sed -e 's/^[ 	]*//g'| sed -e 's/=0D//g'`
   fi

   if [ -z "${EMAIL_PARTICIPANTS}" ]
   then
     EMAIL_PARTICIPANTS=`echo $line|grep Participants:|cut -d ':' -f 2| sed -e 's/^[ 	]*//g'| sed -e 's/=0D//g'`
   fi

done


# Log the action
#
TIMESTAMP=`date +%Y-%m-%d:%H:%M:%S`
echo "${TIMESTAMP}:EMAIL_NAME = ${EMAIL_NAME}" | tee -a ${LOG_FILE}
echo "${TIMESTAMP}:EMAIL_EMAIL = ${EMAIL_EMAIL}" | tee -a ${LOG_FILE}
echo "${TIMESTAMP}:EMAIL_ENQUIRY = ${EMAIL_ENQUIRY}" | tee -a ${LOG_FILE}
echo "${TIMESTAMP}:EMAIL_TOUR = ${EMAIL_TOUR}" | tee -a ${LOG_FILE}
echo "${TIMESTAMP}:EMAIL_DATE = ${EMAIL_DATE}" | tee -a ${LOG_FILE}
echo "${TIMESTAMP}:EMAIL_PARTICIPANTS = ${EMAIL_PARTICIPANTS}" | tee -a ${LOG_FILE}


if [ -z "${EMAIL_NAME}" -o -z "${EMAIL_EMAIL}" ]
then
  echo "${TIMESTAMP}:no record to process"
  exit
fi

# Run an insert/upsert via a temp file
#
# Note that first column is autoincremented primary key
#
echo "insert into tm_enquiry values(null, \"${EMAIL_NAME}\", \"${EMAIL_EMAIL}\", \"${EMAIL_ENQUIRY}\", \"${EMAIL_TOUR}\", \"${EMAIL_DATE}\", \"${EMAIL_PARTICIPANTS}\", \"NEW\", now());" > ${TMP_FILE}
cat ${TMP_FILE} |tee -a ${LOG_FILE}

# Show most of the arguments
#
echo "mysql -h ${TM_DB_HOST} -D ${TM_DB_NAME} -u ${TM_DB_USER}" | tee -a ${LOG_FILE}

# Run mysql
#
mysql -h ${TM_DB_HOST} -D ${TM_DB_NAME} -u ${TM_DB_USER} -p${TM_DB_PW} < ${TMP_FILE}

# Check status
#
if [ $? -ne 0 ]
then
  echo "${TIMESTAMP}:insert failed" |tee -a ${LOG_FILE}
else
  echo "${TIMESTAMP}:success" |tee -a ${LOG_FILE}
fi

# cleanup
#
rm -f ${TMP_FILE}
