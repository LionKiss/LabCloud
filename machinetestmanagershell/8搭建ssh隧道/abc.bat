echo off

:exit
plink -v -ssh  -R *:***:****:**** -pw ***** -P 22 root@******* "for (( i=1; i<=100; i++)) do echo `date` yes; sleep 6; done"
goto exit
