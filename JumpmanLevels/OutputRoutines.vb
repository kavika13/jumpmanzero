Module OutputRoutines

    Public Sub AddOCube(ByRef sBuff As String, ByVal X1 As Single, ByVal Y1 As Single, ByVal Z1 As Single, ByVal X2 As Single, ByVal Y2 As Single, ByVal Z2 As Single, ByVal LO As LevelObject)
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
    'End Sub


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

    Public Sub AddPCube(ByRef sBuff As String, ByVal V1 As Vertex, ByVal V2 As Vertex, ByVal V3 As Vertex, ByVal V4 As Vertex, ByVal LO As LevelObject)
        Dim U1 As Vertex
        Dim U2 As Vertex
        Dim U3 As Vertex
        Dim U4 As Vertex
        Dim U5 As Vertex
        Dim U6 As Vertex
        Dim U7 As Vertex
        Dim U8 As Vertex

        Dim iTX1 As Single, iTX2 As Single, iTX3 As Single, iTX4 As Single
        Dim iTY1 As Single, iTY2 As Single, iTY3 As Single, iTY4 As Single

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

    Public Sub AddZCube(ByRef sBuff As String, ByVal V1 As Vertex, ByVal V2 As Vertex, ByVal V3 As Vertex, ByVal V4 As Vertex, ByVal LO As LevelObject)
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

    Public Sub AddTriangle(ByRef sBuff As String, ByVal V1 As Vertex, ByVal V2 As Vertex, ByVal V3 As Vertex)
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
