#!/bin/bash

if [ $# == 0 ]; then
   echo "***command: $0 <pathname>"
   echo "***error  makefile list!!"
   exit
fi

echo "##########Begin to compile ########"
fBasePath="`pwd`"
fErrorLog="`pwd`/autoCompileError.txt"
fCheckPath="`echo $OB_REL`"
echo $fErrorLog"    "$fCheckPath
fMakeName=$1
if [ -f $fMakeName ]; then
   echo "exec the  $fMakeName"
else
   echo "$fMakeName is not exist!"
   exit
fi
iErrFlag=0
while read -r lnContent; do
   if [ $lnContent = "" ]; then
        continue
   fi
   #echo ${lnContent:0:1}
   if [ ${lnContent:0:1} = "#" ]; then
        continue
   fi 
   ###file format: dir:make command:check result
   #echo $lnContent
   drCompile=`echo $lnContent | awk -F: '{print $1}' `
   cmdCompile="`echo $lnContent | awk -F: '{print $2}'`"
   resCheck="`echo $lnContent | awk -F: '{print $3}'`"

  #echo "################to clean the compile result.#####"
  for libName in `echo $resCheck` 
  do
      if [ ${#libName} -lt 3 ]; then
          continue
      fi
      if [ ${libName:0:3} = "lib" ]; then
          resLibName="$fCheckPath/lib/$libName"
      else
          resLibName="$fCheckPath/bin/$libName"
      fi
      echo "##########rm the result object: $resLibName"
      if [ -f $resLibName ]; then
          rm $resLibName
      fi
  done
   cd $drCompile
   echo "entry $drCompile"
   #echo ":$cmdCompile"
   #echo "$cmdCompile" | awk '{run=$0;system(run)}'
   eval $cmdCompile
   echo "compile command:  $cmdCompile"
   #$cmdCompile
   if [ $? -ne 0 ]; then
       echo "##########$cmdCompile execute fail!"
       echo "`date`: $drCompile: $cmdCompile execute fail!" > $fErrorLog
       break
   fi
   iErrFlag=0

   echo "################$drCompile:$cmdCompile:$resCheck"
   for libName in `echo $resCheck` 
   do
      if [ ${#libName} -lt 3 ]; then
          continue
      fi
      if [ ${libName:0:3} = "lib" ]; then
          resLibName="$fCheckPath/lib/$libName"
      else
          resLibName="$fCheckPath/bin/$libName"
      fi
      echo "##########result name: $resLibName"
      if [ -f $resLibName ]; then
          echo "result ok!"
          continue
      else
          echo "`date` :##########$drCompile: $resLibName compile fail!"
          echo "`date` :$resLibName compile fail!" > $fErrorLog
          iErrFlag=1
          break
      fi
   done
   if [ $iErrFlag -eq 1 ]; then
      break
   fi
done < $fMakeName
if [ $iErrFlag -eq 1 ]; then
    echo "########Compile Fail!########"
else
    echo "########Compile finished!########"
fi