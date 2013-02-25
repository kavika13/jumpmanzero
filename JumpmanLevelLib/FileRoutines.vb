Imports System.IO

Public Module FileRoutines

    Public Sub LoadLevelFromFile(fullFilename As String, sourceDirectory As String,
                                 ByRef baseFilename As String,
                                 ByRef mLOs As Long, ByRef mLO() As LevelObject,
                                 ByRef mLRs As Long, ByRef mLR() As LevelResource)
        mLOs = 0
        mLRs = 0

        Dim sAll As String
        FileOpen(1, Path.Combine(sourceDirectory, fullFilename), OpenMode.Input, OpenAccess.Read)
        sAll = InputString(1, LOF(1))

        Dim sLines() As String
        Dim sLine As String
        Dim iLine As Long

        sLines = Split(sAll, vbCrLf)

        For iLine = 0 To UBound(sLines)
            sLine = sLines(iLine)

            If Microsoft.VisualBasic.Left(sLine, 2) = "O " Then
                If mLOs >= mLO.Length Then
                    Throw New System.IO.InvalidDataException("Too many objects specified in level file")
                End If
                mLO(mLOs).ConvertFromString(Mid(sLine, 3))
                mLO(mLOs).DestroyIfInvalid()
                mLOs = mLOs + 1
            End If

            If Microsoft.VisualBasic.Left(sLine, 2) = "R " Then
                If mLRs >= mLR.Length Then
                    Throw New System.IO.InvalidDataException("Too many resources specified in level file")
                End If
                mLR(mLRs).ConvertFromString(Mid(sLine, 3))
                mLRs = mLRs + 1
            End If
        Next

        baseFilename = Microsoft.VisualBasic.Left(fullFilename, InStr(fullFilename, ".") - 1)

        FileClose(1)
    End Sub

    Public Sub SaveLevelToFile(mLRs As Long, mLR() As LevelResource,
                               mLOs As Long, mLO() As LevelObject,
                               baseFilename As String, outputDirectory As String)
        Dim sAll As String = Nothing
        Dim sLine As String
        Dim iLoop As Long

        FileOpen(3, Path.Combine(outputDirectory, baseFilename & ".LVL"), OpenMode.Output)

        For iLoop = 0 To mLRs - 1
            sLine = "R " & mLR(iLoop).ConvertToString()
            sAll = sAll & sLine & vbCrLf
        Next

        For iLoop = 0 To mLOs - 1
            sLine = "O " & mLO(iLoop).ConvertToString()
            sAll = sAll & sLine & vbCrLf
        Next

        Print(3, sAll)
        FileClose(3)
    End Sub

    Public Sub RenderLevelToFile(mLRs As Long, mLR() As LevelResource,
                           mLOs As Long, mLO() As LevelObject,
                           baseFilename As String, sourceDirectory As String, outputDirectory As String)

        SortLevelObject(mLOs, mLO)

        FileOpen(10, Path.Combine(outputDirectory, baseFilename & ".DAT"), OpenMode.Output, OpenAccess.Default)

        Dim iLoop As Long

        Dim sAll As String = Nothing
        Dim iScripts As Long
        Dim iMeshes As Long
        Dim iTextures As Long
        Dim iSounds As Long

        iSounds = 0
        iScripts = 0
        iMeshes = 0
        iTextures = 0

        For iLoop = 0 To mLRs - 1
            OutputResource("R", mLR(iLoop).ResourceType, mLR(iLoop).ResourceData, mLR(iLoop).ResourceData2, 0, mLR(iLoop).FileName)

            If mLR(iLoop).ResourceType = JMResourceType.BIN And mLR(iLoop).ResourceData = 2 Then
                sAll = sAll & "define Script" & mLR(iLoop).FileName & " " & iScripts & vbCrLf
                iScripts = iScripts + 1
            ElseIf mLR(iLoop).ResourceType = JMResourceType.BMP Or mLR(iLoop).ResourceType = JMResourceType.PNG Or mLR(iLoop).ResourceType = JMResourceType.JPG Then
                sAll = sAll & "define Texture" & mLR(iLoop).FileName & " " & iTextures & vbCrLf
                iTextures = iTextures + 1
            ElseIf mLR(iLoop).ResourceType = JMResourceType.MSH Then
                sAll = sAll & "define Mesh" & mLR(iLoop).FileName & " " & iMeshes & vbCrLf
                iMeshes = iMeshes + 1
            ElseIf mLR(iLoop).ResourceType = JMResourceType.WAV Then
                sAll = sAll & "define Sound" & mLR(iLoop).FileName & " " & iSounds & vbCrLf
                iSounds = iSounds + 1
            End If
        Next
        FileOpen(17, Path.Combine(sourceDirectory, baseFilename & "Resources.jms"), OpenMode.Output, OpenAccess.Default)
        Print(17, sAll)
        FileClose(17)

        For iLoop = 0 To mLOs - 1
            ProcessLO(mLO(iLoop))
        Next

        FileClose(10)
    End Sub

    Private Sub SortLevelObject(mLOs As Long, mLO() As LevelObject)
        Dim bChange As Boolean
        Dim iLoop As Long
        Dim sSwap As String
        Dim sTemp As String

        bChange = True

        For iLoop = 0 To mLOs - 1
            If mLO(iLoop).Type = "ARBITRARY" Then
                mLO(iLoop).Z1 = mLO(iLoop).V(1).Z
            End If
        Next

        While bChange
            bChange = False
            For iLoop = 0 To mLOs - 2
                If mLO(iLoop).Z1 < mLO(iLoop + 1).Z1 Then
                    sSwap = mLO(iLoop).ConvertToString
                    sTemp = mLO(iLoop + 1).ConvertToString
                    mLO(iLoop).ConvertFromString(sTemp)
                    mLO(iLoop + 1).ConvertFromString(sSwap)
                    bChange = True
                End If
            Next
        End While

    End Sub

    Private Sub ProcessLO(ByVal LO As LevelObject)
        Dim sBuff As String

        If LO.Type = "PLATFORM" Then
            OutputLine("P", LO.V(1).X, LO.V(1).Y, LO.V(2).X, LO.V(2).Y, LO.Z1, LO.Extra, LO.Number, LO.Texture, 0, 0, "")
            sBuff = ""
            AddPCube(sBuff, LO.V(1), LO.V(2), LO.V(3), LO.V(4), LO)
            OutputBuffer(sBuff)
        End If

        If LO.Type = "WALL" Then
            OutputLine("W", LO.V(1).X, LO.V(1).Y, LO.V(2).X, LO.V(2).Y, LO.V(4).X, LO.V(4).Y, LO.V(3).X, LO.V(3).Y, LO.Number, LO.Texture, "")
            sBuff = ""
            AddPCube(sBuff, LO.V(1), LO.V(2), LO.V(3), LO.V(4), LO)
            OutputBuffer(sBuff)
        End If

        If LO.Type = "LADDER" Then
            OutputLine("L", LO.V(1).X, LO.V(1).Y, LO.V(2).Y, LO.Z1, LO.Z1, LO.Number, LO.Texture, 0, 0, 0, "")
            sBuff = ""

            AddOCube(sBuff, LO.V(1).X - 6.5, LO.V(1).Y, LO.Z1, LO.V(1).X - 5.2, LO.V(2).Y, LO.Z2, LO)
            AddOCube(sBuff, LO.V(1).X + 5.2, LO.V(1).Y, LO.Z1, LO.V(1).X + 6.5, LO.V(2).Y, LO.Z2, LO)

            Dim iRung As Single
            For iRung = LO.V(2).Y + 5 To LO.V(1).Y - 3 Step 6
                AddOCube(sBuff, LO.V(1).X - 5.3, iRung, LO.Z1, LO.V(1).X + 5.3, iRung - 1.5, LO.Z2, LO)
            Next

            OutputBuffer(sBuff)
        End If

        If LO.Type = "VINE" Then
            OutputLine("V", LO.V(1).X, LO.V(1).Y, LO.V(2).Y, LO.Z1, LO.Z1, LO.Number, LO.Texture, 0, 0, 0, "")
            sBuff = ""

            Dim iRung As Single
            Dim bSwitch As Boolean
            bSwitch = False
            For iRung = LO.V(2).Y + 3 To LO.V(1).Y Step 3
                bSwitch = Not bSwitch
                If bSwitch Then
                    AddOCube(sBuff, LO.V(1).X - 0.25, iRung, LO.Z1, LO.V(1).X + 0.75, iRung - 3, LO.Z2, LO)
                Else
                    AddOCube(sBuff, LO.V(1).X - 0.75, iRung, LO.Z1, LO.V(1).X + 0.25, iRung - 3, LO.Z2, LO)
                End If
            Next

            OutputBuffer(sBuff)
        End If

        If LO.Type = "ARBITRARY" Then
            Dim iAX As Single
            Dim iAY As Single

            iAX = (LO.V(1).X + LO.V(2).X + LO.V(3).X + LO.V(4).X) / 4
            iAY = (LO.V(1).Y + LO.V(2).Y + LO.V(3).Y + LO.V(4).Y) / 4

            If iAY < 0 Then iAY = 0
            If iAX < 0 Then iAX = 0

            OutputLine("A", LO.Texture, iAX, iAY, LO.Number, 0, 0, 0, 0, 0, 0, "")

            sBuff = ""
            AddTriangle(sBuff, LO.V(1), LO.V(2), LO.V(3))
            AddTriangle(sBuff, LO.V(2), LO.V(4), LO.V(3))

            OutputBuffer(sBuff)
        End If

        If LO.Type = "DONUT" Then
            OutputLine("D", LO.V(1).X, LO.V(1).Y, LO.Z1, LO.Number, LO.Texture, 0, 0, 0, 0, 0, "")
            sBuff = ""

            AddOCube(sBuff, LO.V(1).X - 1, LO.V(1).Y + 3, LO.Z1, LO.V(1).X + 1, LO.V(1).Y + 1, LO.Z2, LO)
            AddOCube(sBuff, LO.V(1).X - 1, LO.V(1).Y - 1, LO.Z1, LO.V(1).X + 1, LO.V(1).Y - 3, LO.Z2, LO)
            AddOCube(sBuff, LO.V(1).X - 3, LO.V(1).Y + 1, LO.Z1, LO.V(1).X - 1, LO.V(1).Y - 1, LO.Z2, LO)
            AddOCube(sBuff, LO.V(1).X + 1, LO.V(1).Y + 1, LO.Z1, LO.V(1).X + 3, LO.V(1).Y - 1, LO.Z2, LO)

            OutputBuffer(sBuff)
        End If

    End Sub

    Private Sub AddOCube(ByRef sBuff As String, ByVal X1 As Single, ByVal Y1 As Single, ByVal Z1 As Single, ByVal X2 As Single, ByVal Y2 As Single, ByVal Z2 As Single, ByVal LO As LevelObject)
        Dim U1 As Vertex
        Dim U2 As Vertex
        Dim U3 As Vertex
        Dim U4 As Vertex
        Dim U5 As Vertex
        Dim U6 As Vertex
        Dim U7 As Vertex
        Dim U8 As Vertex

        U1.X = X1 : U1.Y = Y1 : U1.Z = Z1 : U1.TX = 0 : U1.TY = 0
        U2.X = X2 : U2.Y = Y1 : U2.Z = Z1 : U2.TX = 1 : U2.TY = 0
        U3.X = X1 : U3.Y = Y2 : U3.Z = Z1 : U3.TX = 0 : U3.TY = 1
        U4.X = X2 : U4.Y = Y2 : U4.Z = Z1 : U4.TX = 1 : U4.TY = 1

        U5.X = X1 : U5.Y = Y1 : U5.Z = Z2 : U5.TX = 0 : U5.TY = 0
        U6.X = X2 : U6.Y = Y1 : U6.Z = Z2 : U6.TX = 1 : U6.TY = 0
        U7.X = X1 : U7.Y = Y2 : U7.Z = Z2 : U7.TX = 0 : U7.TY = 1
        U8.X = X2 : U8.Y = Y2 : U8.Z = Z2 : U8.TX = 1 : U8.TY = 1

        If LO.DrawF Then
            AddTriangle(sBuff, U1, U2, U3)
            AddTriangle(sBuff, U2, U4, U3)
        End If
        If LO.DrawX Then
            AddTriangle(sBuff, U6, U5, U8)
            AddTriangle(sBuff, U5, U7, U8)
        End If

        If LO.DrawT Then
            AddTriangle(sBuff, U5, U6, U1)
            AddTriangle(sBuff, U6, U2, U1)
        End If
        If LO.DrawB Then
            AddTriangle(sBuff, U3, U4, U7)
            AddTriangle(sBuff, U4, U8, U7)
        End If

        If LO.DrawL Then
            AddTriangle(sBuff, U5, U1, U7)
            AddTriangle(sBuff, U1, U3, U7)
        End If
        If LO.DrawR Then
            AddTriangle(sBuff, U2, U6, U4)
            AddTriangle(sBuff, U6, U8, U4)
        End If
    End Sub

    Private Function ProjectionLength(ByVal iNX As Single, ByVal iNY As Single, ByVal iBX As Single, ByVal iBY As Single) As Single
        Dim iRatio As Single
        Dim iLen As Single
        iLen = iBX ^ 2 + iBY ^ 2
        If iLen = 0 Then
            ProjectionLength = 0
            Exit Function
        End If
        iRatio = (iNX * iBX + iNY * iBY) / iLen
        ProjectionLength = iRatio * Math.Sqrt(iLen)
    End Function

    Private Sub AddPCube(ByRef sBuff As String, ByVal V1 As Vertex, ByVal V2 As Vertex, ByVal V3 As Vertex, ByVal V4 As Vertex, ByVal LO As LevelObject)
        Dim U1 As Vertex
        Dim U2 As Vertex
        Dim U3 As Vertex
        Dim U4 As Vertex
        Dim U5 As Vertex
        Dim U6 As Vertex
        Dim U7 As Vertex
        Dim U8 As Vertex

        Dim iTX1 As Single, iTX2 As Single, iTX3 As Single, iTX4 As Single

        'OLD METHOD
        'iShift = (V2.Y - V1.Y) / (V2.X - V1.X) * 3 / 15

        iTX1 = ProjectionLength((V1.X - V1.X), (V1.Y - V1.Y), (V2.X - V1.X), (V2.Y - V1.Y))
        iTX2 = ProjectionLength((V2.X - V1.X), (V2.Y - V1.Y), (V2.X - V1.X), (V2.Y - V1.Y))
        iTX3 = ProjectionLength((V3.X - V1.X), (V3.Y - V1.Y), (V2.X - V1.X), (V2.Y - V1.Y))
        iTX4 = ProjectionLength((V4.X - V1.X), (V4.Y - V1.Y), (V2.X - V1.X), (V2.Y - V1.Y))

        Dim iScale As Single
        Dim iReal As Single

        iReal = iTX2 / 15
        iScale = CLng(iReal * 4) / 4
        iScale = (iScale / iReal) / 15

        iTX1 = iTX1 * iScale
        iTX2 = iTX2 * iScale
        iTX3 = iTX3 * iScale
        iTX4 = iTX4 * iScale

        U1.X = V1.X : U1.Y = V1.Y : U1.Z = LO.Z1 : U1.TX = iTX1 : U1.TY = 0
        U2.X = V2.X : U2.Y = V2.Y : U2.Z = LO.Z1 : U2.TX = iTX2 : U2.TY = 0
        U3.X = V3.X : U3.Y = V3.Y : U3.Z = LO.Z1 : U3.TX = iTX3 : U3.TY = 0.5
        U4.X = V4.X : U4.Y = V4.Y : U4.Z = LO.Z1 : U4.TX = iTX4 : U4.TY = 0.5

        U5.X = V1.X : U5.Y = V1.Y : U5.Z = LO.Z2 : U5.TX = iTX1 : U5.TY = 0.5
        U6.X = V2.X : U6.Y = V2.Y : U6.Z = LO.Z2 : U6.TX = iTX2 : U6.TY = 0.5
        U7.X = V3.X : U7.Y = V3.Y : U7.Z = LO.Z2 : U7.TX = iTX3 : U7.TY = 0
        U8.X = V4.X : U8.Y = V4.Y : U8.Z = LO.Z2 : U8.TX = iTX4 : U8.TY = 0

        If LO.DrawT Then
            AddTriangle(sBuff, U5, U6, U1)
            AddTriangle(sBuff, U6, U2, U1)
        End If
        If LO.DrawB Then
            AddTriangle(sBuff, U3, U4, U7)
            AddTriangle(sBuff, U4, U8, U7)
        End If

        If LO.DrawL Then
            AddTriangle(sBuff, U5, U1, U7)
            AddTriangle(sBuff, U1, U3, U7)
        End If
        If LO.DrawR Then
            AddTriangle(sBuff, U2, U6, U4)
            AddTriangle(sBuff, U6, U8, U4)
        End If

        U1.TY = 0.5
        U2.TY = 0.5
        U3.TY = 1
        U4.TY = 1
        U5.TY = 0.5
        U6.TY = 0.5
        U7.TY = 1
        U8.TY = 1
        If LO.DrawX Then
            AddTriangle(sBuff, U6, U5, U8)
            AddTriangle(sBuff, U5, U7, U8)
        End If
        If LO.DrawF Then
            AddTriangle(sBuff, U1, U2, U3)
            AddTriangle(sBuff, U2, U4, U3)
        End If

    End Sub

    Private Sub AddZCube(ByRef sBuff As String, ByVal V1 As Vertex, ByVal V2 As Vertex, ByVal V3 As Vertex, ByVal V4 As Vertex, ByVal LO As LevelObject)
        Dim U1 As Vertex
        Dim U2 As Vertex
        Dim U3 As Vertex
        Dim U4 As Vertex
        Dim U5 As Vertex
        Dim U6 As Vertex
        Dim U7 As Vertex
        Dim U8 As Vertex

        U1.X = V1.X : U1.Y = V1.Y : U1.Z = LO.Z1 : U1.TX = 0 : U1.TY = 0
        U2.X = V2.X : U2.Y = V2.Y : U2.Z = LO.Z1 : U2.TX = 1 : U2.TY = 0
        U3.X = V3.X : U3.Y = V3.Y : U3.Z = LO.Z1 : U3.TX = 0 : U3.TY = 1
        U4.X = V4.X : U4.Y = V4.Y : U4.Z = LO.Z1 : U4.TX = 1 : U4.TY = 1

        U5.X = V1.X : U5.Y = V1.Y : U5.Z = LO.Z2 : U5.TX = 0 : U5.TY = 0
        U6.X = V2.X : U6.Y = V2.Y : U6.Z = LO.Z2 : U6.TX = 1 : U6.TY = 0
        U7.X = V3.X : U7.Y = V3.Y : U7.Z = LO.Z2 : U7.TX = 0 : U7.TY = 1
        U8.X = V4.X : U8.Y = V4.Y : U8.Z = LO.Z2 : U8.TX = 1 : U8.TY = 1

        If LO.DrawF Then
            AddTriangle(sBuff, U1, U2, U3)
            AddTriangle(sBuff, U2, U4, U3)
        End If
        If LO.DrawX Then
            AddTriangle(sBuff, U6, U5, U8)
            AddTriangle(sBuff, U5, U7, U8)
        End If

        If LO.DrawT Then
            AddTriangle(sBuff, U5, U6, U1)
            AddTriangle(sBuff, U6, U2, U1)
        End If
        If LO.DrawB Then
            AddTriangle(sBuff, U3, U4, U7)
            AddTriangle(sBuff, U4, U8, U7)
        End If

        If LO.DrawL Then
            AddTriangle(sBuff, U5, U1, U7)
            AddTriangle(sBuff, U1, U3, U7)
        End If
        If LO.DrawR Then
            AddTriangle(sBuff, U2, U6, U4)
            AddTriangle(sBuff, U6, U8, U4)
        End If
    End Sub

    Private Sub AddTriangle(ByRef sBuff As String, ByVal V1 As Vertex, ByVal V2 As Vertex, ByVal V3 As Vertex)
        Dim uX As Double, uY As Double, uZ As Double
        Dim vX As Double, vY As Double, vZ As Double
        Dim nX As Double, nY As Double, nZ As Double
        Dim nL As Double

        uX = V2.X - V1.X : uY = V2.Y - V1.Y : uZ = V2.Z - V1.Z
        vX = V3.X - V1.X : vY = V3.Y - V1.Y : vZ = V3.Z - V1.Z

        nX = (uY * vZ) - (uZ * vY)
        nY = (uZ * vX) - (uX * vZ)
        nZ = (uX * vY) - (uY * vX)

        nL = Math.Sqrt(nX * nX + nY * nY + nZ * nZ)
        If nL = 0 Then nL = 0.1

        nX = Math.Round(nX / nL, 3)
        nY = Math.Round(nY / nL, 3)
        nZ = Math.Round(nZ / nL, 3)

        sBuff = sBuff & NumToString(V1.X)
        sBuff = sBuff & NumToString(V1.Y)
        sBuff = sBuff & NumToString(V1.Z)
        sBuff = sBuff & NumToString(nX)
        sBuff = sBuff & NumToString(nY)
        sBuff = sBuff & NumToString(nZ)
        sBuff = sBuff & NumToString(100)
        sBuff = sBuff & NumToString(V1.TX)
        sBuff = sBuff & NumToString(V1.TY)

        sBuff = sBuff & NumToString(V2.X)
        sBuff = sBuff & NumToString(V2.Y)
        sBuff = sBuff & NumToString(V2.Z)
        sBuff = sBuff & NumToString(nX)
        sBuff = sBuff & NumToString(nY)
        sBuff = sBuff & NumToString(nZ)
        sBuff = sBuff & NumToString(100)
        sBuff = sBuff & NumToString(V2.TX)
        sBuff = sBuff & NumToString(V2.TY)

        sBuff = sBuff & NumToString(V3.X)
        sBuff = sBuff & NumToString(V3.Y)
        sBuff = sBuff & NumToString(V3.Z)
        sBuff = sBuff & NumToString(nX)
        sBuff = sBuff & NumToString(nY)
        sBuff = sBuff & NumToString(nZ)
        sBuff = sBuff & NumToString(100)
        sBuff = sBuff & NumToString(V3.TX)
        sBuff = sBuff & NumToString(V3.TY)

    End Sub

End Module
