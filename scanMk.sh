#!/bin/bash
echo $1
if ( $#argv == 0) then
   echo "error  directory"
   exit
endif
if ( ! -d $argv[1] ) then
   echo "dir  $argv[1] not valid dir"
   exit
endif
set tmpFile='/tmp/mkfiletmp.list'
if ( -e $tmpFile )then
#   echo "file  $tmpFile exist!"
   rm $tmpFile
endif
find $argv[1] -name 'Makefile*' -print > $tmpFile
set lineCnt=`wc -l $tmpFile | awk '{ print $1}'`
#@ lineCnt = 0 + $lineCnt
echo "lines:$lineCnt"
if ( "$lineCnt" =~ "0" )then
   echo "dir $argv[1] files not found. lines: $lineCnt"
   exit
endif
echo "*******to do Makefile scan.******"
set libFileName="libTest.txt"
if ( -e $libFileName ) then
   rm $libFileName
endif
#foreach mkfile(`cat $tmpFile`)
#for mkfile in $tmpFile
#do
   echo "filename: $mkfile to do..."
#select the proddest. maybe have several objs.
   set libObj=`awk -F= '/^PRODDEST/{print $2}' $mkfile`
   echo "objs: $libObj"
   for objName in $libObj
   do
       echo "obj: $objName"
       echo ${objName%\$*}
       set newobjName=${objName%\$*}
#       set newobjName=`echo $objName | awk -F; '{ print $1 }'`
#       set newobjName=`echo ${objName%%;*}`
       echo "$objName have \$, new is $newobjName"
       set firstlineCont=`awk -F'[: ]' '/^$newobjName/{print $2}' $mkfile`
       echo "firstlinecont : $firstlineCont"
#if end char is "\", then cut it, and have several lines.
#       set lastChar=${firstlineCont}
       echo "firstcont cnt: ${#firstlineCont}"
       if ( ${#firstlineCont} < 1 )then
           echo "objName is null"
           continue
       endif
#get the righ last char.
       set lastChar=${firstlineCont:0:1}
       echo "last char : $lastChar"
       if ( "$lastChar" =~ "\\" )then
           echo "last char is \\ "
           set lineCont=${firstlineCont%?}
       else
           set lineCont=$firstlineCont
       endif
       for lineName in $lineCont
	do
	       set libTodo="lib"$lineName".so"
	       echo "lib name: $lineName, $libTodo"
	       echo $libObj";"$libTodo >> $libFileName
	done
        set lineNum=`awk '/^$objName/{print NR}' $mkfile`
#   echo "line contents: $lineCont"
        set lines=`awk -n 'NR>$lineNum{print $0}' $mkfile `
        for libLine in $lines
        do
            echo "line: $lineNum; $libLine"
	    set lastChar=${libLine:0:1}
	    if ( "$lastChar" !~ "\\" ) then
	       set newlibLine=$libLine
	    else
		set newlibLine=${libLine%?}
	    endif
	    echo " to do ... $newlibLine"
	    for newlineName in $newlibLine
	    do
		set libnewTodo="lib"$newlineName".so"
		echo "lib name: $newlineName , $libnewTodo "
		echo $objName";"$libnewTodo >> $libFileName
	    done
if ( "$lastChar" !~ "\\" ) then
break
endif
done
echo "PRODDEST $objName ok"
echo "filename: $mkfile ok"
done
#done
