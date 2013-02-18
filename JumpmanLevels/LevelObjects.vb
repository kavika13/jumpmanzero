Public Structure Vertex
    Dim X As Single
    Dim Y As Single
    Dim Z As Single
    Dim TX As Single
    Dim TY As Single
End Structure

Public Enum JMResourceType
    MID = 1
    MSH = 2
    BMP = 3
    JPG = 4
    BIN = 5
    PNG = 6
    WAV = 7
End Enum

Public Structure LevelResource
    Dim ResourceType As JMResourceType
    Dim ResourceData As Long
    Dim ResourceData2 As Long
    Dim FileName As String

    Public Function ConvertToString()
        Dim sLine As String, sTemp As String
        sTemp = Me.FileName
        sTemp = Replace(sTemp, " ", "~32~")
        sLine = sLine & sTemp & " " & Me.ResourceType & " " & Me.ResourceData & " " & Me.ResourceData2
        ConvertToString = sLine
    End Function

    Public Function ConvertFromString(ByVal sLine As String)
        Dim sParts() As String
        Dim sTemp As String
        sParts = Split(sLine, " ")

        sTemp = sParts(0)
        sTemp = Replace(sTemp, "~32~", " ")
        Me.FileName = sTemp
        Me.ResourceType = sParts(1)
        Me.ResourceData = sParts(2)
        If UBound(sParts) > 2 Then
            Me.ResourceData2 = sParts(3)
        End If
    End Function

End Structure

Public Structure LevelObject
    Dim Type As String
    Dim V() As Vertex

    Dim Z1 As Single
    Dim Z2 As Single

    Dim DrawT As Boolean
    Dim DrawB As Boolean
    Dim DrawF As Boolean
    Dim DrawX As Boolean
    Dim DrawL As Boolean
    Dim DrawR As Boolean

    Dim TBScaleX As Single, TBScaleY As Single
    Dim TBStartX As Single, TBStartY As Single

    Dim LRScaleX As Single, LRScaleY As Single
    Dim LRStartX As Single, LRStartY As Single

    Dim FXScaleX As Single, FXScaleY As Single
    Dim FXStartX As Single, FXStartY As Single

    Dim Extra As Single
    Dim Number As Long

    Dim Texture As Long

    Public Sub DestroyIfInvalid()
        Dim iTemp As Single
        If Me.Type = "PLATFORM" Then
            If Me.V(1).X >= Me.V(2).X Then
                SwapVertexes(1, 2)
            End If
            If Me.V(3).X >= Me.V(4).X Then
                SwapVertexes(3, 4)
            End If
        End If
    End Sub

    Private Sub SwapVertexes(ByVal v1 As Long, ByVal v2 As Long)
        Dim iTemp As Single

        iTemp = Me.V(v2).X
        Me.V(v2).X = Me.V(v1).X
        Me.V(v1).X = iTemp

        iTemp = Me.V(v2).Y
        Me.V(v2).Y = Me.V(v1).Y
        Me.V(v1).Y = iTemp

        iTemp = Me.V(v2).Z
        Me.V(v2).Z = Me.V(v1).Z
        Me.V(v1).Z = iTemp

        iTemp = Me.V(v2).TX
        Me.V(v2).TX = Me.V(v1).TX
        Me.V(v1).TX = iTemp

        iTemp = Me.V(v2).TY
        Me.V(v2).TY = Me.V(v1).TY
        Me.V(v1).TY = iTemp
    End Sub

    Public Function ConvertFromString(ByVal sLine As String) As String
        Dim sParts() As String
        Dim iPart As Long

        iPart = 0
        sParts = Split(sLine)
        Me.DrawB = sParts(iPart) : iPart = iPart + 1
        Me.DrawF = sParts(iPart) : iPart = iPart + 1
        Me.DrawL = sParts(iPart) : iPart = iPart + 1
        Me.DrawR = sParts(iPart) : iPart = iPart + 1
        Me.DrawT = sParts(iPart) : iPart = iPart + 1
        Me.DrawX = sParts(iPart) : iPart = iPart + 1

        Me.Extra = sParts(iPart) : iPart = iPart + 1
        Me.FXScaleX = sParts(iPart) : iPart = iPart + 1
        Me.FXScaleY = sParts(iPart) : iPart = iPart + 1
        Me.FXStartX = sParts(iPart) : iPart = iPart + 1
        Me.FXStartY = sParts(iPart) : iPart = iPart + 1
        Me.LRScaleX = sParts(iPart) : iPart = iPart + 1
        Me.LRScaleY = sParts(iPart) : iPart = iPart + 1
        Me.LRStartX = sParts(iPart) : iPart = iPart + 1
        Me.LRStartY = sParts(iPart) : iPart = iPart + 1

        Me.Number = sParts(iPart) : iPart = iPart + 1
        Me.TBScaleX = sParts(iPart) : iPart = iPart + 1
        Me.TBScaleY = sParts(iPart) : iPart = iPart + 1
        Me.TBStartX = sParts(iPart) : iPart = iPart + 1
        Me.TBStartY = sParts(iPart) : iPart = iPart + 1

        Me.Type = sParts(iPart) : iPart = iPart + 1

        Dim iVector As Long
        For iVector = 1 To 8
            Me.V(iVector).TX = sParts(iPart) : iPart = iPart + 1
            Me.V(iVector).TY = sParts(iPart) : iPart = iPart + 1
            Me.V(iVector).X = sParts(iPart) : iPart = iPart + 1
            Me.V(iVector).Y = sParts(iPart) : iPart = iPart + 1
            Me.V(iVector).Z = sParts(iPart) : iPart = iPart + 1
        Next

        Me.Z1 = sParts(iPart) : iPart = iPart + 1
        Me.Z2 = sParts(iPart) : iPart = iPart + 1

        Me.Texture = sParts(iPart) : iPart = iPart + 1
    End Function

    Public Function ConvertToString() As String
        Dim sLine As String

        sLine = sLine & Me.DrawB & " "
        sLine = sLine & Me.DrawF & " "
        sLine = sLine & Me.DrawL & " "
        sLine = sLine & Me.DrawR & " "
        sLine = sLine & Me.DrawT & " "
        sLine = sLine & Me.DrawX & " "

        sLine = sLine & Me.Extra & " "
        sLine = sLine & Me.FXScaleX & " "
        sLine = sLine & Me.FXScaleY & " "
        sLine = sLine & Me.FXStartX & " "
        sLine = sLine & Me.FXStartY & " "

        sLine = sLine & Me.LRScaleX & " "
        sLine = sLine & Me.LRScaleY & " "
        sLine = sLine & Me.LRStartX & " "
        sLine = sLine & Me.LRStartY & " "

        sLine = sLine & Me.Number & " "

        sLine = sLine & Me.TBScaleX & " "
        sLine = sLine & Me.TBScaleY & " "
        sLine = sLine & Me.TBStartX & " "
        sLine = sLine & Me.TBStartY & " "

        sLine = sLine & Me.Type & " "

        Dim iVector As Long
        For iVector = 1 To 8
            sLine = sLine & Me.V(iVector).TX & " "
            sLine = sLine & Me.V(iVector).TY & " "
            sLine = sLine & Me.V(iVector).X & " "
            sLine = sLine & Me.V(iVector).Y & " "
            sLine = sLine & Me.V(iVector).Z & " "
        Next

        sLine = sLine & Me.Z1 & " "
        sLine = sLine & Me.Z2 & " "

        sLine = sLine & Me.Texture & " "
        ConvertToString = sLine
    End Function

End Structure

Module Module1
    Public Sub DefaultWall(ByRef LO As LevelObject, ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long)
        LO.Type = "WALL"

        LO.Texture = 1

        LO.Extra = 0
        LO.Number = 0

        LO.Z1 = 1
        LO.Z2 = 5

        LO.DrawF = True
        LO.DrawT = True
        LO.DrawL = True
        LO.DrawR = True
        LO.DrawB = False
        LO.DrawX = False

        LO.V(1).X = X1
        LO.V(1).Y = Y1
        LO.V(2).X = X2
        LO.V(2).Y = Y1
        LO.V(3).X = X1
        LO.V(3).Y = Y2
        LO.V(4).X = X2
        LO.V(4).Y = Y2
    End Sub

    Public Sub DefaultPlatform(ByRef LO As LevelObject, ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long)
        LO.Type = "PLATFORM"

        LO.Texture = 1

        LO.Extra = 0
        LO.Number = 0

        LO.Z1 = 1
        LO.Z2 = 5

        LO.DrawF = True
        LO.DrawT = True
        LO.DrawL = True
        LO.DrawR = True
        LO.DrawB = False
        LO.DrawX = False

        LO.V(1).X = X1
        LO.V(1).Y = Y1
        LO.V(2).X = X2
        LO.V(2).Y = Y2

        LO.V(3).X = X1
        LO.V(3).Y = Y1 - 3
        LO.V(4).X = X2
        LO.V(4).Y = Y2 - 3
    End Sub

    Public Sub DefaultDonut(ByRef LO As LevelObject, ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long)
        LO.Type = "DONUT"

        LO.Extra = 0
        LO.Number = 0

        LO.Texture = 3

        LO.Z1 = 0
        LO.Z2 = 1

        LO.DrawF = True
        LO.DrawT = True
        LO.DrawL = True
        LO.DrawR = True
        LO.DrawB = True
        LO.DrawX = False

        LO.V(1).X = X1
        LO.V(1).Y = Y1

    End Sub

    Public Sub DefaultVine(ByRef LO As LevelObject, ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long)
        LO.Type = "VINE"

        LO.Extra = 0
        LO.Number = 0

        LO.Texture = 2

        LO.Z1 = 0
        LO.Z2 = 1

        LO.DrawF = True
        LO.DrawT = True
        LO.DrawL = True
        LO.DrawR = True
        LO.DrawB = True
        LO.DrawX = False

        LO.V(1).X = X1
        LO.V(1).Y = Y1
        LO.V(2).Y = Y2

    End Sub

    Public Sub DefaultArbitrary(ByRef LO As LevelObject, ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long)
        LO.Type = "ARBITRARY"

        LO.Extra = 0
        LO.Number = 0

        LO.Texture = 0

        LO.Z1 = 0
        LO.Z2 = 1

        LO.DrawF = True
        LO.DrawT = True
        LO.DrawL = True
        LO.DrawR = True
        LO.DrawB = True
        LO.DrawX = False

        LO.V(1).X = X1
        LO.V(1).Y = Y1
        LO.V(1).Z = 0
        LO.V(1).TX = 0
        LO.V(1).TY = 0

        LO.V(2).X = X2
        LO.V(2).Y = Y1
        LO.V(2).Z = 0
        LO.V(2).TX = 1
        LO.V(2).TY = 0

        LO.V(3).X = X1
        LO.V(3).Y = Y2
        LO.V(3).Z = 0
        LO.V(3).TX = 0
        LO.V(3).TY = 1

        LO.V(4).X = X2
        LO.V(4).Y = Y2
        LO.V(4).Z = 0
        LO.V(4).TX = 1
        LO.V(4).TY = 1

    End Sub

    Public Sub DefaultLadder(ByRef LO As LevelObject, ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long)
        LO.Type = "LADDER"

        LO.Extra = 0
        LO.Number = 0

        LO.Texture = 2

        LO.Z1 = 0
        LO.Z2 = 1

        LO.DrawF = True
        LO.DrawT = True
        LO.DrawL = True
        LO.DrawR = True
        LO.DrawB = True
        LO.DrawX = False

        LO.V(1).X = X1
        LO.V(1).Y = Y1
        LO.V(2).Y = Y2

    End Sub

End Module
