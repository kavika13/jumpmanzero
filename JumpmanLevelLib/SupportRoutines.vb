Public Module SupportRoutines

    Public Function PointInQuad(ByVal iX As Single, ByVal iY As Single, ByVal qX1 As Single, ByVal qY1 As Single, ByVal qX2 As Single, ByVal qY2 As Single, ByVal qX3 As Single, ByVal qY3 As Single, ByVal qX4 As Single, ByVal qY4 As Single) As Boolean
        Dim bX As Single, bY As Single, nX As Single, nY As Single
        Dim det As Single

        Dim iLen As Single

        PointInQuad = False

        bX = qX2 - qX1 : bY = qY2 - qY1
        nX = iX - qX1 : nY = iY - qY1
        det = bX * nY - bY * nX
        iLen = Math.Sqrt(bX * bX + bY * bY)
        If det - (iLen / 2) > 0 Then Exit Function

        bX = qX3 - qX2 : bY = qY3 - qY2
        nX = iX - qX2 : nY = iY - qY2
        det = bX * nY - bY * nX
        iLen = Math.Sqrt(bX * bX + bY * bY)
        If det - (iLen / 2) > 0 Then Exit Function

        bX = qX4 - qX3 : bY = qY4 - qY3
        nX = iX - qX3 : nY = iY - qY3
        det = bX * nY - bY * nX
        iLen = Math.Sqrt(bX * bX + bY * bY)
        If det - (iLen / 2) > 0 Then Exit Function

        bX = qX1 - qX4 : bY = qY1 - qY4
        nX = iX - qX4 : nY = iY - qY4
        det = bX * nY - bY * nX
        iLen = Math.Sqrt(bX * bX + bY * bY)
        If det - (iLen / 2) > 0 Then Exit Function

        PointInQuad = True
    End Function


    Public Function ToRealX(ByVal sX As Single) As Long
        ToRealX = (sX - 5) / 2
    End Function

    Public Function ToRealY(ByVal sY As Single) As Long
        ToRealY = (645 - sY) / 2
    End Function

    Public Sub OutputResource(ByVal sType As String, ByVal i1 As Integer, ByVal i2 As Integer, ByVal i3 As Integer, ByVal i4 As Integer, ByVal sFunc As String)
        Print(10, aPad(sType, 2))
        Print(10, aPad(sFunc, 30))
        Print(10, IntToString(i1))
        Print(10, IntToString(i2))
        Print(10, IntToString(i3))
        Print(10, IntToString(i4))
    End Sub

    Public Sub OutputLine(ByVal sType As String, ByVal i1 As Integer, ByVal i2 As Integer, ByVal i3 As Integer, ByVal i4 As Integer, ByVal i5 As Integer, ByVal i6 As Integer, ByVal i7 As Integer, ByVal i8 As Integer, ByVal i9 As Integer, ByVal i10 As Integer, ByVal sFunc As String)
        Print(10, aPad(sType, 2))
        Print(10, aPad(sFunc, 8))
        Print(10, IntToString(i1))
        Print(10, IntToString(i2))
        Print(10, IntToString(i3))
        Print(10, IntToString(i4))
        Print(10, IntToString(i5))
        Print(10, IntToString(i6))
        Print(10, IntToString(i7))
        Print(10, IntToString(i8))
        Print(10, IntToString(i9))
        Print(10, IntToString(i10))
    End Sub

    Public Function aPad(ByVal sString As String, ByVal iLen As Integer) As String
        If Len(sString) > iLen Then sString = Mid(sString, 1, iLen)
        If Len(sString) < iLen Then sString = sString & New String(Chr(0), iLen - Len(sString))
        aPad = sString
    End Function

    Public Function IntToString(ByVal iInt As Integer) As String
        IntToString = Nothing
        Dim iTemp As Integer
        iTemp = iInt Mod 256
        IntToString = IntToString & Chr(iTemp)
        iTemp = (iInt - iTemp) \ 256
        IntToString = Chr(iTemp) & IntToString
    End Function

    Public Sub OutputBuffer(ByVal sbuff As String)
        Print(10, IntToString(Len(sbuff)))
        Print(10, sbuff)
    End Sub



    Public Function NumToString(ByVal sNum As Single) As String
        Dim bNeg As Boolean
        Dim iNum1 As Integer, iNum2 As Integer, iNum3 As Integer, iNum4 As Integer
        Dim iNum As Int32

        iNum = sNum * 256

        If iNum < 0 Then
            bNeg = True
            iNum = Math.Abs(iNum)
        End If

        iNum4 = iNum Mod 256
        iNum = (iNum - iNum4) \ 256

        iNum3 = iNum Mod 256
        iNum = (iNum - iNum3) \ 256

        iNum2 = iNum Mod 256
        iNum = (iNum - iNum2) \ 256

        iNum1 = iNum Mod 128 + IIf(bNeg, 128, 0)

        NumToString = Chr(iNum1) & Chr(iNum2) & Chr(iNum3) & Chr(iNum4)
    End Function

    'Public Function NumToString(ByVal sNum As Single, Optional ByVal iRep As Integer = 4) As String
    '    Dim iNum As Long
    '    Dim iTemp As Long
    '    Dim bNeg As Boolean

    '    iNum = sNum * 256

    '    If iNum < 0 Then
    '        bNeg = True
    '        iNum = -iNum
    '    End If

    '    iTemp = iNum Mod 256
    '    NumToString = Chr(iTemp) & NumToString
    '    iNum = iNum / 256

    '    iTemp = iNum Mod 256
    '    NumToString = Chr(iTemp) & NumToString
    '    iNum = iNum / 256

    '    iTemp = iNum Mod 256
    '    NumToString = Chr(iTemp) & NumToString
    '    iNum = iNum / 256

    '    iTemp = iNum Mod 128
    '    If bNeg Then iNum = iNum + 128
    '    NumToString = Chr(iTemp) & NumToString

    'End Function

End Module
