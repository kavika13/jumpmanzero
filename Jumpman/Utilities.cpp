#include "stdafx.h"
#include <stdio.h>

long StringToLong(unsigned char *sString)
{
	float fTemp;

	fTemp=sString[1]*256.0f+sString[2]+sString[3]/256.0f;
	if(sString[0])
		return (long)fTemp*-1;
	else
		return (long)fTemp;
}

long StringToLong2(unsigned char *sString)
{
	float fTemp;

	fTemp=(sString[0]&127)*256.0f*256.0f*256.0f+sString[1]*256.0f*256.0f+sString[2]*256.0f+sString[3];
	if(sString[0] & 128)
		return (long)fTemp*-1;
	else
		return (long)fTemp;
}

long StringToInt(unsigned char *sString)
{
	float fTemp;
	fTemp=sString[0]*256.0f+sString[1];
	return (long)fTemp;
}

long FileToString(char *sFileName,unsigned char **sNewBuffer)
{
	DWORD iNumRead;
	BY_HANDLE_FILE_INFORMATION info;
	HANDLE hFile;
	long iSize;

	hFile=CreateFile(sFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
	GetFileInformationByHandle(hFile,&info);
	iSize=info.nFileSizeLow;
	*sNewBuffer=(unsigned char *)malloc(iSize);
	ReadFile(hFile,*sNewBuffer,iSize,&iNumRead,NULL);
	CloseHandle(hFile);

	char sError[300];
	sprintf_s(sError,"Can't find file - %s",sFileName);
	if(!iNumRead)MessageBox(0,sError,"Jumpman Zero",0);

	return iNumRead;
}

long PointInQuad(long iX0,long iY0,long iX1,long iY1,long iX2,long iY2,long iX3,long iY3,long iX4,long iY4)
{
	long iBX,iBY,iSX,iSY;
	long det,total;

	total=0;

	iBX=iX2-iX1;iBY=iY2-iY1;
	iSX=iX0-iX1;iSY=iY0-iY1;
	det=iBX*iSY-iBY*iSX;
	if(det<=0)total=total+1;

	iBX=iX3-iX2;iBY=iY3-iY2;
	iSX=iX0-iX2;iSY=iY0-iY2;
	det=iBX*iSY-iBY*iSX;
	if(det<=0)total=total+1;

	iBX=iX4-iX3;iBY=iY4-iY3;
	iSX=iX0-iX3;iSY=iY0-iY3;
	det=iBX*iSY-iBY*iSX;
	if(det<=0)total=total+1;

	iBX=iX1-iX4;iBY=iY1-iY4;
	iSX=iX0-iX4;iSY=iY0-iY4;
	det=iBX*iSY-iBY*iSX;
	if(det<=0)total=total+1;

	if(total==4)return 1;
	return 0;
}

