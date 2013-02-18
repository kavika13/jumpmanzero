Module OldStuff



    'Private Sub CollideLines(ByVal X1 As Single, ByVal Y1 As Single, ByVal XV1 As Single, ByVal YV1 As Single, ByVal X2 As Single, ByVal Y2 As Single, ByVal XV2 As Single, ByVal YV2 As Single, ByRef CollideX As Single, ByRef CollideY As Single)
    '    Dim iTX As Single, iTY As Single
    '    iTX = X1 - X2
    '    iTY = Y1 - Y2

    '    'xv2*U-xv1*V=itx
    '    'yv2*U-yv1*V=ity

    '    If XV1 = 0 Then
    '        CollideX = 0
    '        CollideY = 0
    '        Exit Sub
    '    End If

    '    Dim iC1 As Single, iC2 As Single, iC3 As Single
    '    iC1 = YV2 - XV2 * (YV1 / XV1)
    '    iC2 = YV1 - XV1 * (YV1 / XV1)
    '    iC3 = iTY - iTX * (YV1 / XV1)

    '    Dim u As Single
    '    u = iC3 / iC1

    '    CollideX = u * XV2
    '    CollideY = u * YV2
    'End Sub

    'Private Sub ProcessSpace(ByVal iX1 As Long, ByVal iY1 As Long, ByVal iX2 As Long, ByVal iY2 As Long, ByVal iZ As Long, ByVal iPrevX As Single, ByVal iPrevY As Single, ByVal iNextX As Single, ByVal iNextY As Single, ByVal iNum As Long, ByVal bFile As Boolean)

    '    Dim sPX1 As Single, sPY1 As Single, sPLen1 As Single
    '    Dim sPX2 As Single, sPY2 As Single, sPLen2 As Single
    '    Dim sPX3 As Single, sPY3 As Single, sPLen3 As Single
    '    sPX1 = iX1 - iPrevX : sPY1 = iY1 - iPrevY : sPLen1 = Math.Sqrt(sPX1 * sPX1 + sPY1 * sPY1)
    '    sPX2 = iX2 - iX1 : sPY2 = iY2 - iY1 : sPLen2 = Math.Sqrt(sPX2 * sPX2 + sPY2 * sPY2)
    '    sPX3 = iNextX - iX2 : sPY3 = iNextY - iY2 : sPLen3 = Math.Sqrt(sPX3 * sPX3 + sPY3 * sPY3)

    '    Dim sNX1 As Single, sNY1 As Single, sNX2 As Single, sNY2 As Single, sNX3 As Single, sNY3 As Single
    '    Dim sNLen1 As Single, sNLen2 As Single, sNLen3 As Single
    '    sNX1 = iY1 - iPrevY
    '    sNY1 = iPrevX - iX1
    '    sNX2 = iY2 - iY1
    '    sNY2 = iX1 - iX2
    '    sNX3 = iNextY - iY2
    '    sNY3 = iX2 - iNextX
    '    sNLen1 = Math.Sqrt(sNX1 * sNX1 + sNY1 * sNY1)
    '    sNLen2 = Math.Sqrt(sNX2 * sNX2 + sNY2 * sNY2)
    '    sNLen3 = Math.Sqrt(sNX3 * sNX3 + sNY3 * sNY3)

    '    Dim sQX1 As Single, sQY1 As Single
    '    Dim sQX2 As Single, sQY2 As Single
    '    Dim sQX3 As Single, sQY3 As Single
    '    sQX1 = sNX1 * 3 / sNLen1
    '    sQY1 = sNY1 * 3 / sNLen1
    '    sQX2 = sNX2 * 3 / sNLen2
    '    sQY2 = sNY2 * 3 / sNLen2
    '    sQX3 = sNX3 * 3 / sNLen3
    '    sQY3 = sNY3 * 3 / sNLen3

    '    On Error Resume Next

    '    '        DSLine(iX2, iY2, iX2 + sQX3, iY2 + sQY3, Color.Yellow)
    '    '        DSLine(iX2 + sQX3, iY2 + sQY3, iX2 + sQX3 + sPX3, iY2 + sQY3 + sPY3, Color.Purple)
    '    '
    '    '        DSLine(iX1, iY1, iX1 + sQX1, iY1 + sQY1, Color.Yellow)
    '    '        DSLine(iX1 + sQX1, iY1 + sQY1, iX1 + sQX1 - sPX1, iY1 + sQY1 - sPY1, Color.Purple)
    '    '
    '    '        DSLine(iX1, iY1, iX1 + sQX2, iY1 + sQY2, Color.Yellow)
    '    '        DSLine(iX2, iY2, iX2 + sQX2, iY2 + sQY2, Color.Yellow)
    '    '        DSLine(iX1 + sQX2, iY1 + sQY2, iX1 + sQX2 + sPX2, iY1 + sQY2 + sPY2, Color.Purple)

    '    Dim iCollideX As Single, iCollideY As Single
    '    Dim sX1 As Single, sX2 As Single, sY1 As Single, sY2 As Single
    '    CollideLines(sQX1, sQY1, sPX1, sPY1, sQX2, sQY2, sPX2, sPY2, iCollideX, iCollideY)
    '    sX1 = iX1 + sQX2 + iCollideX
    '    sY1 = iY1 + sQY2 + iCollideY

    '    CollideLines(sQX2, sQY2, sPX2, sPY2, sQX3, sQY3, sPX3, sPY3, iCollideX, iCollideY)
    '    sX2 = iX2 + sQX3 + iCollideX
    '    sY2 = iY2 + sQY3 + iCollideY

    '    On Error Resume Next
    '    DSLine(iX1, iY1, iX2, iY2, Color.Green)
    '    DSLine(sX1, sY1, sX2, sY2, Color.Blue)

    '    If bFile And Err.Number = 0 Then
    '        msBuff = ""

    '        AddSpaceCube(iX1, iY1, iZ - iPlatformShift, iX2, iY2, iZ + iPlatformWidth, sX1, sY1, sX2, sY2, 0.01, 0.01)

    '        OutputLine("W", iX1, iY1, iX2, iY2, sX2, sY2, sX1, sY1, iZ, iNum, "")
    '        OutputBuffer(msBuff)

    '    End If

    '    On Error Resume Next
    'End Sub


    'Private Sub ProcessPlatform(ByVal iX1 As Long, ByVal iY1 As Long, ByVal iX2 As Long, ByVal iY2 As Long, ByVal iZ As Long, ByVal iExtra As Long, ByVal iNum As Long, ByVal bFile As Boolean)
    '    Dim iLen As Single
    '    Dim iLoop As Long
    '    Dim sX1 As Single, sX2 As Single, sY1 As Single, sY2 As Single
    '    Dim iNX As Single, iNY As Single

    '    If bFile Then
    '        msBuff = ""

    '        If iExtra <> 0 Then
    '            iNX = (iY2 - iY1)
    '            iNY = (iX1 - iX2)
    '            iLen = Math.Sqrt(iNX * iNX + iNY + iNY)
    '            AddPlatformCube(iX1, iY1, iZ - iPlatformShift, iX2, iY2, iZ + iPlatformWidth, 0.01, 0.01)
    '            iNX = iNX * 2 / iLen
    '            iNY = iNY * 2 / iLen
    '            AddSpaceCube(iX1, iY1, iZ - iPlatformShift, iX2, iY2, iZ + iPlatformWidth, iX1 + iNX, iY1 + iNY, iX2 + iNX, iY2 + iNY, 0.01, 0.01)
    '        Else
    '            AddPlatformCube(iX1, iY1, iZ - iPlatformShift, iX2, iY2, iZ + iPlatformWidth, 0.01, 0.01)
    '        End If

    '        OutputLine("P", iX1, iY1, iX2, iY2, iZ, iExtra, iNum, 0, 0, 0, "")
    '        OutputBuffer()
    '    End If

    '    DSLine(iX1, iY1, iX2, iY2, Color.Green)
    '    DSLine(iX1, iY1 - 1, iX2, iY2 - 1, Color.DarkGreen)
    '    DSLine(iX1, iY1 - 2, iX2, iY2 - 2, Color.Green)
    'End Sub

    'Private Sub AddPlatformCube(ByVal iX1 As Single, ByVal iY1 As Single, ByVal iZ1 As Single, ByVal iX2 As Single, ByVal iY2 As Single, ByVal iZ2 As Single, ByVal iTX As Single, ByVal iTY As Single)

    '    Dim iTX1 As Single, iTY1 As Single, iTX2 As Single, iTY2 As Single, iShift As Single
    '    Dim iLen As Single

    '    iLen = Math.Sqrt((iX2 - iX1) ^ 2 + (iY2 - iY1) ^ 2)

    '    iTX1 = 0
    '    iTX2 = iLen
    '    iTY1 = iTY
    '    iTY2 = iTY + 0.23
    '    iShift = (iY2 - iY1) / (iX2 - iX1) * 3

    '    iTX2 = CLng(iTX2 * 4 / 15)
    '    iTX2 = iTX2 / 4
    '    iShift = iShift * 1 / 15

    '    'FRONT
    '    AddPlatformTriangle(iX1, iY1, iZ1, iX2, iY2, iZ1, iX1, iY1 - 3, iZ1, iTX1, iTY1, iTX2, iTY1, iTX1 - iShift, iTY2)
    '    AddPlatformTriangle(iX2, iY2, iZ1, iX2, iY2 - 3, iZ1, iX1, iY1 - 3, iZ1, iTX2, iTY1, iTX2 - iShift, iTY2, iTX1 - iShift, iTY2)

    '    'BACK
    '    '       AddTriangle(iX1, iY1 - 3, iZ2, iX2, iY2, iZ2, iX1, iY1, iZ2, iTX, iTY, 0.05, 0.05)
    '    '       AddTriangle(iX2, iY2 - 3, iZ2, iX1, iY1 - 3, iZ2, iX2, iY2, iZ2, iTX, iTY, 0.05, 0.05)

    '    'TOP
    '    If iSkipTop = 0 Then
    '        AddPlatformTriangle(iX1, iY1, iZ2, iX2, iY2, iZ2, iX1, iY1, iZ1, iTX1, 0.75, iTX2, 0.75, iTX1, 0.99)
    '        AddPlatformTriangle(iX2, iY2, iZ2, iX2, iY2, iZ1, iX1, iY1, iZ1, iTX2, 0.75, iTX2, 0.99, iTX1, 0.99)
    '    End If

    '    'BOTTOM
    '    '        AddTriangle(iX1, iY1 - 3, iZ2, iX1, iY1 - 3, iZ1, iX2, iY2 - 3, iZ2, iTX, 0.5, 0.016, 0.05)
    '    '        AddTriangle(iX1, iY1 - 3, iZ1, iX2, iY2 - 3, iZ1, iX2, iY2 - 3, iZ2, iTX, 0.5, 0.016, 0.05)

    '    'LEFT
    '    AddTriangle(iX1, iY1, iZ2, iX1, iY1, iZ1, iX1, iY1 - 3, iZ2, iTX, iTY, 0.025, 0.01)
    '    AddTriangle(iX1, iY1, iZ1, iX1, iY1 - 3, iZ1, iX1, iY1 - 3, iZ2, iTX, iTY, 0.025, 0.01)

    '    'RIGHT
    '    AddTriangle(iX2, iY2, iZ2, iX2, iY2 - 3, iZ2, iX2, iY2, iZ1, iTX, iTY, 0.025, 0.01)
    '    AddTriangle(iX2, iY2, iZ1, iX2, iY2 - 3, iZ2, iX2, iY2 - 3, iZ1, iTX, iTY, 0.025, 0.01)

    'End Sub


    'Private Sub AddSpaceCube(ByVal iX1 As Single, ByVal iY1 As Single, ByVal iZ1 As Single, ByVal iX2 As Single, ByVal iY2 As Single, ByVal iZ2 As Single, ByVal sX1 As Single, ByVal sY1 As Single, ByVal sX2 As Single, ByVal sY2 As Single, ByVal iTX As Single, ByVal iTY As Single)

    '    Dim iTX1 As Single, iTX2 As Single, iTX3 As Single, iTX4 As Single
    '    Dim iTY1 As Single, iTY2 As Single, iTY3 As Single, iTY4 As Single
    '    Dim iLen As Single
    '    Dim SPX As Single, SPY As Single

    '    SPX = iX2 - iX1
    '    SPY = iY2 - iY1

    '    iLen = Math.Sqrt(SPX * SPX + SPY * SPY)

    '    iTX1 = ((SPX * iX1) + (SPY * iY1)) / ((SPX * SPX) + (SPY * SPY)) * iLen / 10
    '    iTX2 = ((SPX * iX2) + (SPY * iY2)) / ((SPX * SPX) + (SPY * SPY)) * iLen / 10
    '    iTX3 = ((SPX * sX1) + (SPY * sY1)) / ((SPX * SPX) + (SPY * SPY)) * iLen / 10
    '    iTX4 = ((SPX * sX2) + (SPY * sY2)) / ((SPX * SPX) + (SPY * SPY)) * iLen / 10

    '    iTY1 = iTY
    '    iTY2 = iTY
    '    iTY3 = iTY + 0.23
    '    iTY4 = iTY + 0.23

    '    'FRONT
    '    AddPlatformTriangle(iX1, iY1, iZ1, iX2, iY2, iZ1, sX1, sY1, iZ1, iTX1, iTY1, iTX2, iTY2, iTX3, iTY3)
    '    AddPlatformTriangle(iX2, iY2, iZ1, sX2, sY2, iZ1, sX1, sY1, iZ1, iTX2, iTY2, iTX4, iTY4, iTX3, iTY3)

    '    'TOP
    '    If iSkipTop = 0 Then
    '        AddPlatformTriangle(iX1, iY1, iZ2, iX2, iY2, iZ2, iX1, iY1, iZ1, iTX1, 0.75, iTX2, 0.75, iTX1, 0.99)
    '        AddPlatformTriangle(iX2, iY2, iZ2, iX2, iY2, iZ1, iX1, iY1, iZ1, iTX2, 0.75, iTX2, 0.99, iTX1, 0.99)
    '    End If

    '    'LEFT
    '    AddTriangle(iX1, iY1, iZ2, iX1, iY1, iZ1, sX1, sY1, iZ2, iTX, iTY, 0.025, 0.01)
    '    AddTriangle(iX1, iY1, iZ1, sX1, sY1, iZ1, sX1, sY1, iZ2, iTX, iTY, 0.025, 0.01)

    '    'RIGHT
    '    AddTriangle(iX2, iY2, iZ2, sX2, sY2, iZ2, iX2, iY2, iZ1, iTX, iTY, 0.025, 0.01)
    '    AddTriangle(iX2, iY2, iZ1, sX2, sY2, iZ2, sX2, sY2, iZ1, iTX, iTY, 0.025, 0.01)

    'End Sub


    'Private Sub AddCube(ByVal iX1 As Single, ByVal iY1 As Single, ByVal iZ1 As Single, ByVal iX2 As Single, ByVal iY2 As Single, ByVal iZ2 As Single, ByVal iTX As Single, ByVal iTY As Single)

    '    'FRONT
    '    AddTriangle(iX1, iY1, iZ1, iX2, iY1, iZ1, iX1, iY2, iZ1, iTX, iTY, 0.06, 0.06)
    '    AddTriangle(iX2, iY1, iZ1, iX2, iY2, iZ1, iX1, iY2, iZ1, iTX, iTY, 0.06, 0.06)

    '    'BACK
    '    AddTriangle(iX1, iY2, iZ2, iX2, iY1, iZ2, iX1, iY1, iZ2, iTX, iTY, 0.05, 0.05)
    '    AddTriangle(iX2, iY1, iZ2, iX1, iY2, iZ2, iX2, iY2, iZ2, iTX, iTY, 0.05, 0.05)

    '    'TOP
    '    AddTriangle(iX1, iY1, iZ2, iX2, iY1, iZ2, iX1, iY1, iZ1, iTX, 0.8, 0.05, 0.05)
    '    AddTriangle(iX1, iY1, iZ1, iX2, iY1, iZ2, iX2, iY1, iZ1, iTX, 0.8, 0.05, 0.05)

    '    'BOTTOM
    '    AddTriangle(iX1, iY2, iZ2, iX1, iY2, iZ1, iX2, iY2, iZ2, iTX, 0.8, 0.05, 0.05)
    '    AddTriangle(iX1, iY2, iZ1, iX2, iY2, iZ1, iX2, iY2, iZ2, iTX, 0.8, 0.05, 0.05)

    '    'LEFT
    '    AddTriangle(iX1, iY1, iZ2, iX1, iY1, iZ1, iX1, iY2, iZ2, iTX, iTY, 0.05, 0.05)
    '    AddTriangle(iX1, iY1, iZ1, iX1, iY2, iZ1, iX1, iY2, iZ2, iTX, iTY, 0.05, 0.05)

    '    'RIGHT
    '    AddTriangle(iX2, iY1, iZ2, iX2, iY2, iZ2, iX2, iY1, iZ1, iTX, iTY, 0.05, 0.05)
    '    AddTriangle(iX2, iY1, iZ1, iX2, iY2, iZ2, iX2, iY2, iZ1, iTX, iTY, 0.05, 0.05)

    'End Sub




End Module
