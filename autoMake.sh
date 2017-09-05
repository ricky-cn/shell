#!/bin/bash

if [ $# == 0 ]; then
   echo "***command: $0 <pathname>"
   echo "***error  makefile list!!"
   exit
fi

fErrorLog="autoCompileError.txt"
fMakeName=$1
if [ -f $fMakeName ]; then
   echo "exec the  $fMakeName"
else
   echo "$fMakeName is not exist!"
   exit
fi
#for lnContent in `cat $fMakeName`
#do
while read -r lnContent; do
   if [ lnContent = "" ]; then
        continue
   fi
   ###file format: dir:make command:check result
   echo $lnContent
   drCompile=`echo $lnContent | awk -F: '{print $1}' `
   cmdCompile="`echo $lnContent | awk -F: '{print $2}'`"
   resCheck="`echo $lnContent | awk -F: '{print $3}'`"

   cd $drCompile
   $cmdCompile
   if [ $? -ne 0 ]; then
       echo "$cmdCompile execute fail!"
       break
   fi
   iErrFlag=0

   echo "$drCompile:$cmdCompile:$resCheck"
   for libName in `echo $resCheck`
   do
      echo "result name: $libName"
      if [ -f $libName ]; then
          echo "result ok!"
          continue
      else
          echo "`date` :$drCompile: $libName compile fail!" > $fErrorLog
          iErrFlag=1
          break
      fi
   done
   if [ $iErrFlag -eq 1 ]; then
      break
   fi

done < $fMakeName
