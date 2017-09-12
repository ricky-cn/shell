#!/bin/bash

if [ $# == 0 ]; then
   echo "***command: $0 <pathname>"
   echo "***error  directory!!"
   exit
fi
if [ ! -d $1 ]; then
   echo "dir  $1 not valid dir"
   exit
fi
#function to get the content begin with spec char from file.
function find_head()
{
   echo "$1, $2 ,  $3, $4"
   iLen=${#2}
   strName=$2
   cnLine=$3
   cBgn=$4
   i=0
   jFlag=0
   iFind=0
   ret_var=""
#   cat $1 | while read line
#   for line in `cat $1`
   while read -r line; do
#echo "=====test the line: $line"
       if [ ${#line} -lt 2 ]; then
           echo "line is null, $i , $3 "
           if [ $3 -lt 1 ]; then
#              i=$(expr $i + 1)
              continue
           fi
#           continue
       fi
       if [ "${line:0:1}" == "#" ];then
#           echo "begin with # "
           continue
       fi
       if [ $jFlag -eq 1 ];then
#          echo " jFlag == 1, $line , $i"
          if [ $i -lt $cnLine ]; then
             i=$(expr $i + 1 )
#             echo " i plus 1; $i "
             continue
          else
#             echo "line : $line"
             ret_var="${line//\$/=}"
             iFind=1
             break
          fi
       fi
#echo "input : $strName; ${line:0:$iLen}"
#echo "===$strName===$line====${line:$cBgn:$iLen}==="
       if [ "$strName" == "${line:$cBgn:$iLen}" ];then
#            echo "input find!"
          if [ $3 -lt 1 ]; then
            ret_var="${line//\$/=}"
            iFind=1
            break
          else
            jFlag=1
            i=1
          fi
       fi
   done < $1
#  echo "return string : $ret_var"
#   if [ ${#ret_var} -lt 1 ];then
#      echo "file search end.., no found!"
#      ret_var=""
#      return 0
#   else
#      echo "found!"
#      return 1
#   fi
    if [ $iFind -lt 1 ];then
       ret_var=""
    fi
    return $iFind
}
tmpFile="/tmp/mkfiletmp.list"
if [ -f $tmpFile ]; then
   echo "file  $tmpFile exist!"
   rm $tmpFile
fi
find $1 -name 'Makefile*' -print > $tmpFile
lineCnt=`wc -l $tmpFile | awk '{ print $1}'`

echo "lines:$lineCnt"
if [ "$lineCnt" == "0" ];then
   echo "dir $1 files not found. lines: $lineCnt"
   exit
fi
echo "*******to do Makefile scan.******"
libFileName="libTest.txt"
if [ -f $libFileName ]; then
   rm $libFileName
fi
cat $tmpFile
for mkfile in `cat $tmpFile`
do
    echo "filename: $mkfile to do..."
    #select the proddest. maybe have several objs.
    libObj=`awk -F= '/^PRODDEST/{print $2}' $mkfile`
#   change the $ to =
    libTmpObj=`echo ${libObj//\$/=}`
    if [ ${#libTmpObj} -lt 1 ];then
       echo "PRODDEST is null, do next..."
       continue
    fi
    for objName in $libTmpObj
    do
       if [ ${#objName} -lt 2 ];then
#          echo "obj is null"
          continue
       fi
#       echo "obj: $objName, ${objName:0:1}"
#       echo ${objName%\$*}
       xFlag=0
       if [ "${objName:0:1}" == "=" ];then
          xFlag=2
          newobjName=${objName#*(}
          newobjName=${newobjName%)*}
#          echo "$objName head char is \$, to get the target name: $newobjName"
          find_head $mkfile $newobjName 0 0
          outputName=$ret_var
          if [ ${#outputName} -lt 2 ]; then
             echo "not found the target objname."
             continue
          fi
          outputName=${outputName#*=}
#          echo "====output name is : $outputName"
       else
          newobjName=${objName%=*}
          outputName=$objName
#          echo "===head char no the \$, $outputName; $newobjName"
       fi
##############################
# here can get the .o with cpp link.
# find_head $mkfile $newobjName 0 $xFlag
# lineName=$ret_var
# cobj=`echo ${lineName//\$/=}`
# cobj=${cobj#*:}
# *** check the $ char.
##############################
##############################
#to get the compile option with command line.
##############################
    find_head $mkfile $newobjName 1 $xFlag
    lineName=$ret_var
    clineName=`echo ${lineName//\$/=}`
    for lclineName in $clineName
    do
       if [ ${#lclineName} -lt 2 ];then
          continue
       fi
       if [ ${lclineName:0:2} == "-l" ];then
#          echo "find the compile option lib."
#          echo "=====3***lib tmp name:  $outputName ; ${lclineName#*l}"
          echo $mkfile";"$outputName";"${lclineName#*l} >> $libFileName
       fi
    done
    echo "libtodo: $newobjName; line name : $lineName"
##############################
# find the PRODLIBS includes.
##############################
    linelibName=`awk -F= '/^PRODLIBS/{print $2}' $mkfile`
    lineTmpName=`echo ${linelibName//\$/=}`
#    echo "===tmpName is : $lineTmpName , $linelibName"
#    lineTmpName2=${lineTmpName:0:${#lineTmpName}}
    liblastChar=${lineTmpName:0-1}
    liblastChar2=${lineTmpName:0-2:1}
    if [ "$liblastChar" == "\\" ];then
       libTmpName=${lineTmpName:0:${#lineTmpName} - 1}
#       echo "*****1"
    else
       if [ "$liblastChar2" == "\\" ];then
          libTmpName=${lineTmpName:0:${#lineTmpName} - 2}
          liblastChar=$liblastChar2
       else
          echo "no the \\ last."
       fi
    fi
       for ltmpName in $libTmpName
       do
#           libTodo="$lineName"
#           echo "lib name: $lineName , $ltmpName"
           if [ ${#ltmpName} -lt 2 ];then
                continue
           fi
#           echo "=====2***lib tmp name:  $outputName ; $ltmpName"
           echo $mkfile";"$outputName";"$ltmpName >> $libFileName
       done
       iLine=0
       while [ "$liblastChar" == "\\" ];
       do
           iLine=$(expr $iLine + 1 )
#           echo " *======lib list doing... , $iLine"
           find_head $mkfile "PRODLIBS" $iLine 0
           newlibLine=$ret_var
           echo " *======$newlibLine===="
          if [ ${#newlibLine} -lt 2 ];then
              echo "return error!"
              break
          fi
          liblastChar=${newlibLine:0-1:1}
          liblastChar2=${newlibLine:0-2:1}
          echo "*===last char : $liblastChar"
          if [ "$liblastChar" == "\\" ];then
               newlibLine=${newlibLine:0:${#newlibLine} - 1}
          else
             if [ "$liblastChar2" == "\\" ];then
                newlibLine=${newlibLine:0:${#newlibLine} - 2}
                liblastChar=$liblastChar2
#                echo "******2"
             else
                liblastChar=""
             fi
          fi
          for newlineName in ${newlibLine}
          do
#                set libnewTodo="lib"$newlineName".so"
                if [ ${#newlineName} -lt 2 ];then
                   continue
                fi
#                echo "===1**lib name: $outputName , $newlineName "
                echo $mkfile";"$outputName";"$newlineName >> $libFileName
           done
       done
#       echo " to deal ... $newlibLine"
     echo "PRODDEST $outputName ok "
     done
echo "filename: $mkfile ok "
done
echo "all done."
