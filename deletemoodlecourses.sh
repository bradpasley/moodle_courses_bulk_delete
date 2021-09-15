#!/bin/bash
#
# by Brad Pasley (c) 2021
#
# This script automates the bulk resetting and deleting of Moodle courses. It depends on the following:
# * moosh to be installed
# * moodle directory - stored in the below variable. Please change to the correct path
moodledirectory="/data/webs/au.edu.ac.moodle.he/moodle/"
#
#help screen
displayHelp() 
{
  echo
  echo "============================"
  echo "Delete Moodle Courses - Help"
  echo "============================"
  echo
  echo "This script helps you to bulk delete Moodle courses."
  echo "It first resets the course to wipe user data, to prevent unexpected issues."
  echo "Then it will delete the course. Finally it will flush the Moodle database to clear away space."
  echo
  echo "Options"
  echo "======="
  echo " -h                        display this help page"
  echo " -n (number) -p (number)   multiprocess several processes on separate bash shells"
  echo " -r                        reset shells only"
  echo " -d                        delete shells only"
  echo 
  echo "Delete all from One Moodle Category"
  echo "==================================="
  echo "To delete all Moodle courses in one categories, input the Moodle category id."
  echo "e.g. If I want to delete all Moodle courses in category 10:"
  echo "> deletemoodlecourses 10"
  echo
  echo "Delete all from Multiple Moodle Categories"
  echo "=========================================="
  echo "To delete all Moodle courses in multiple categories, input the Moodle categories, separated by a space."
  echo "e.g. If I want to delete all Moodle courses in categories 10, 12, and 15:"
  echo "> deletemoodlecourses 10 12 15"
  echo
  echo "Advanced: Multiprocess job"
  echo "=========================="
  echo "To process 1st of every 3 lines, 2nd of every 3 lines, 3rd of every 3 lines, you should use the -n (number) and -p (processes) options"
  echo "e.g. command prompt 1:"
  echo "> deletemoodlecourses -n 1 -p 3 10 12 15"
  echo "     command prompt 2:"
  echo "> deletemoodlecourses -n 2 -p 3 10 12 15"
  echo "     command prompt 3:"
  echo "> deletemoodlecourses -n 3 -p 3 10 12 15" 
  exit
}

displayUsage()
{
  echo
  echo "Delete Moodle Courses"
  echo "====================="
  echo "Usage: $0 [-n <0|p> -p <=n] categoryid [additional categoryids]"
  echo "e.g. 1/3 processes, category ids 244, 245"
  echo "     > $0 -n 1 -p 3 244 245"
  echo 
  echo "For more information, use the help: $0 -h"
  echo
  exit 1
}

#check options
#processNumber - 0 is single process, 1 if first division of process
#processTotal - 1 is single process, 2 if two processes, 3 if three processes etc
processNumber=0
processTotal=1
multiprocess="false"
resetonly="false"
deleteonly="false"

#debugging: echo "test args #1: 1: $1 2: $2 3: $3 4: $4 5: $5"

while getopts ":hrdn:p::" option; do
  #debugging: echo "getoptions: ${option}"
  #debugging: echo "getoptargs: ${OPTARG}"
   case "${option}" in
      h) # display Help
         displayHelp
         ;;
      d) #delete only
         deleteonly="true"
         ;;
      r) #reset only
         resetonly="true"
         ;;
      n) # process number
         processNumber=${OPTARG}
         #debugging line: echo "n: $processNumber"
         if [[ "$processNumber" == "" ]] 
         then 
            echo "n is empty"
            displayUsage
         elif [[ ! $processNumber =~ ^[[:digit:]]+$ ]] 
         then 
           echo "-n: $processNumber is not number"
           displayUsage
         fi
         #[ -n "${processNumber}"] || displayUsage
         #((processNumber -gt 0)) || displayUsage
         multiprocess="true"
         ;;
      p) # total number of processes
         processTotal=${OPTARG}
         #debugging line: echo "p: $processTotal"
         if [[ "$processTotal" == "" ]] 
         then 
            echo "-p: no value entered"
            displayUsage
         elif [[ ! $processTotal =~ ^[[:digit:]]+$ ]] 
         then 
           echo "-p: $processTotal is not number"
           displayUsage
         fi
         multiprocess="true"
         ;;
      :) #no arg provided
        echo
        echo "input error: -${OPTARG} requires a value"
        displayUsage
        ;;
      *) #unknown error
        echo
        echo "unexpected input"
        displayUsage
   esac
done

#if -n used but no -p used
if [[ $processNumber -ne 0 && $processTotal -eq 1 ]]
then 
  displayUsage
fi

#if -p used but no -n used
if [[ $processNumber -eq 0 && $processTotal -gt 1 ]]
then
  displayUsage
fi

#if both reset and delete options added, die
if [[ "$resetonly" == "true" && "$deleteonly" == "true" ]]
then
  echo "Input error: Cannot have both -r and -d options"
  displayUsage
fi

#skip one argument for reset only
#debugging: echo "reset? $resetonly"
if [[ "$resetonly" == "true" ]]
then
  #remove -r
  shift
fi

#skip one argument for delete only
#debugging: echo "delete? $deleteonly"
if [[ "$deleteonly" == "true" ]]
then
  #remove -d
  shift
fi

#skip first two arguments for multiprocess - move to categoryids
#debugging: echo "multi? $multiprocess"
if [[ "$multiprocess" == "true" ]]
then
  #remove -n
  shift
  #remove -n (value)
  shift
  #remove -p
  shift
  #remove -p (value)
  shift
fi



#check if any categoryid arguments exist
if [ $# -lt 1 ]
then
 echo "Input error: at least one categoryid must be entered."
 displayUsage
fi

#debugging line
#echo "test args #2: 1: $1 2: $2 3: $3 4: $4 5: $5"

#check args are all integers
for arg in "$@"
do
  if [[ ! $arg =~ ^[[:digit:]]+$ ]]
  then 
      echo "Input Error - $arg is not a number"
      displayUsage
  fi
done

#start main response
echo
echo "Delete Moodle Courses"
echo

if [[ "$multiprocess" == "true" ]]
then
  echo "Multi-processing: processing stream $processNumber of $processTotal processes"
fi

if [[ "$resetonly" == "true" ]]
then
  echo "Resetting Courses Only"
fi

if [[ "$deleteonly" == "true" ]]
then
  echo "Deleting Courses Only"
fi

#change to Moodle directory
cd "$moodledirectory"

#for each category provided as an argument, list, reset and delete each course
for category in "$@"
do
      
   #$processlist = list of courseids to be processed
   if [[ "$multiprocess" == "true" ]]
   then
    # sed command breaks into 3 separate lists - to be excuted simultaneously.
    processlist=$(sudo -u www-data moosh course-list -i "category=$category" | sed -n "${processNumber}~${processTotal}p")
   else
    processlist=$(sudo -u www-data moosh course-list -i "category=$category")
   fi

   echo
   echo "CategoryID $category"
   echo
   echo "CourseIDs:"
   #list course ids, not on separate lines, but separated by commas, except the last one.
   echo $processlist | sed '$s/,$/\n/'
   echo
   echo "Processing these courses..."

   if [[ "$resetonly" == "true" ]]
   then
    #debugging (just display what would be reset)
    #echo $processlist | xargs -n 1 echo "resetting"
    #reset each courseid supplied 
    echo $processlist | xargs -n 1 sudo -u www-data moosh course-reset 
   elif [[ "$deleteonly" == "true" ]]
   then
      #debugging (just display what would be deleted)
      #echo $processlist | xargs -n 1 echo "deleting"
      #delete each courseid supplied 
      echo $processlist | xargs -n 1 sudo -u www-data moosh course-delete 
   else #do both reset and delete
      #debugging (just display what would be reset)
      #echo $processlist | xargs -n 1 echo "resetting"
      #debugging (just display what would be deleted)
      #echo $processlist | xargs -n 1 echo "deleting"
      #reset each courseid supplied 
      echo $processlist | xargs -n 1 sudo -u www-data moosh course-reset 
      echo $processlist | xargs -n 1 sudo -u www-data moosh course-delete 
   fi  
   
   echo  
done

#return to script directory
echo
echo "Bulk Moodle Course Deletion completed"
echo


