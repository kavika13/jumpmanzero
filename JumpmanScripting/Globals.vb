

Public Module FunctionConstants

    Const FCBASECN = 2
    Const FCSTACKCN = 3

    Const FCMOVBCCN = 10
    Const FCMOVSCCN = 11
    Const FCMOVBSSC = 12
    Const FCMOVSCBC = 13
    Const FCMOVSCSC = 14

    Const FCMOVGCCN = 20
    Const FCMOVGSSC = 21
    Const FCMOVSCGC = 22
    Const FCMOVGCSC = 23

    Const FCADDSCCN = 30

    Const FCADDSCSC = 40
    Const FCMULSCSC = 41
    Const FCSUBSCSC = 42
    Const FCDIVSCSC = 43

    Const FCMOVSCGS = 44
    Const FCMOVSCBS = 45
    Const FCBANDSCSC = 46

    Const FCJUMPZ = 50
    Const FCJUMPNZ = 51
    Const FCJUMP = 52

    Const FCEQUSCSC = 60
    Const FCNEQSCSC = 61
    Const FCGTSCSC = 62
    Const FCGTESCSC = 63
    Const FCORSCSC = 64
    Const FCANDSCSC = 65
    Const FCCALL = 70
    Const FCRET = 71

    Const FCEXT = 100

    Function ExtFunctionName(ByVal iFunc As Integer) As String
        Select Case iFunc
            Case 1
                ExtFunctionName = "print"
            Case 2
                ExtFunctionName = "setext"
            Case 3
                ExtFunctionName = "setsel"
            Case 8
                ExtFunctionName = "getext"
            Case 9
                ExtFunctionName = "getsel"
            Case 10
                ExtFunctionName = "getnavdir"
            Case 11
                ExtFunctionName = "strcopy"
            Case 12
                ExtFunctionName = "strcat"

            Case 32
                ExtFunctionName = "selectplatform"
            Case 33
                ExtFunctionName = "selectladder"
            Case 34
                ExtFunctionName = "selectdonut"
            Case 35
                ExtFunctionName = "absplatform"
            Case 36
                ExtFunctionName = "collide"
            Case 37
                ExtFunctionName = "kill"
            Case 38
                ExtFunctionName = "selectvine"
            Case 39
                ExtFunctionName = "absladder"

            Case 40
                ExtFunctionName = "spawn"
            Case 41
                ExtFunctionName = "newmesh"
            Case 42
                ExtFunctionName = "setproperties"
            Case 43
                ExtFunctionName = "sound"
            Case 44
                ExtFunctionName = "setdata"
            Case 45
                ExtFunctionName = "getdata"
            Case 46
                ExtFunctionName = "absdonut"
            Case 47
                ExtFunctionName = "collidewall"
            Case 48
                ExtFunctionName = "selectpicture"
            Case 49
                ExtFunctionName = "prioritizeobject"
            Case 51
                ExtFunctionName = "selectwall"
            Case 52
                ExtFunctionName = "selectobjectmesh"
            Case 53
                ExtFunctionName = "deletemesh"
            Case 54
                ExtFunctionName = "deleteobject"
            Case 55
                ExtFunctionName = "win"
            Case 56
                ExtFunctionName = "absvine"
            Case 57
                ExtFunctionName = "service"
            Case 58
                ExtFunctionName = "newcharmesh"
            Case 59
                ExtFunctionName = "resetperspective"

            Case 64
                ExtFunctionName = "rotatex"
            Case 65
                ExtFunctionName = "rotatey"
            Case 66
                ExtFunctionName = "rotatez"
            Case 67
                ExtFunctionName = "translate"
            Case 70
                ExtFunctionName = "identity"
            Case 71
                ExtFunctionName = "perspective"
            Case 72
                ExtFunctionName = "scale"
            Case 73
                ExtFunctionName = "scrolltexture"

            Case 80
                ExtFunctionName = "rnd"
            Case 81
                ExtFunctionName = "findplatform"
            Case 82
                ExtFunctionName = "sin"
            Case 83
                ExtFunctionName = "cos"
            Case 84
                ExtFunctionName = "findladder"
            Case 85
                ExtFunctionName = "atan"
            Case 86
                ExtFunctionName = "sqr"
            Case 87
                ExtFunctionName = "findvine"
            Case 88
                ExtFunctionName = "setfog"
            Case 89
                ExtFunctionName = "changemesh"

        End Select
    End Function

    Function IdentifyExternalFunction(ByVal sName As String) As Long
        IdentifyExternalFunction = -1
        Select Case sName
            Case "print"
                IdentifyExternalFunction = 1

            Case "setext"
                IdentifyExternalFunction = 2
            Case "setsel"
                IdentifyExternalFunction = 3

            Case "getext"
                IdentifyExternalFunction = 8
            Case "getsel"
                IdentifyExternalFunction = 9
            Case "getnavdir"
                IdentifyExternalFunction = 10
            Case "strcopy"
                IdentifyExternalFunction = 11
            Case "strcat"
                IdentifyExternalFunction = 12

            Case "selectplatform"
                IdentifyExternalFunction = 32
            Case "selectladder"
                IdentifyExternalFunction = 33
            Case "selectdonut"
                IdentifyExternalFunction = 34
            Case "absplatform"
                IdentifyExternalFunction = 35
            Case "collide"
                IdentifyExternalFunction = 36
            Case "kill"
                IdentifyExternalFunction = 37
            Case "selectvine"
                IdentifyExternalFunction = 38
            Case "absladder"
                IdentifyExternalFunction = 39

            Case "spawn"
                IdentifyExternalFunction = 40
            Case "newmesh"
                IdentifyExternalFunction = 41
            Case "setproperties"
                IdentifyExternalFunction = 42
            Case "sound"
                IdentifyExternalFunction = 43
            Case "setdata"
                IdentifyExternalFunction = 44
            Case "getdata"
                IdentifyExternalFunction = 45
            Case "absdonut"
                IdentifyExternalFunction = 46
            Case "collidewall"
                IdentifyExternalFunction = 47
            Case "selectpicture"
                IdentifyExternalFunction = 48
            Case "prioritizeobject"
                IdentifyExternalFunction = 49
            Case "selectwall"
                IdentifyExternalFunction = 51
            Case "selectobjectmesh"
                IdentifyExternalFunction = 52
            Case "deletemesh"
                IdentifyExternalFunction = 53
            Case "deleteobject"
                IdentifyExternalFunction = 54
            Case "win"
                IdentifyExternalFunction = 55
            Case "absvine"
                IdentifyExternalFunction = 56
            Case "service"
                IdentifyExternalFunction = 57
            Case "newcharmesh"
                IdentifyExternalFunction = 58
            Case "resetperspective"
                IdentifyExternalFunction = 59

            Case "rotatex"
                IdentifyExternalFunction = 64
            Case "rotatey"
                IdentifyExternalFunction = 65
            Case "rotatez"
                IdentifyExternalFunction = 66
            Case "translate"
                IdentifyExternalFunction = 67
            Case "identity"
                IdentifyExternalFunction = 70
            Case "perspective"
                IdentifyExternalFunction = 71
            Case "scale"
                IdentifyExternalFunction = 72
            Case "scrolltexture"
                IdentifyExternalFunction = 73

            Case "rnd"
                IdentifyExternalFunction = 80
            Case "findplatform"
                IdentifyExternalFunction = 81
            Case "sin"
                IdentifyExternalFunction = 82
            Case "cos"
                IdentifyExternalFunction = 83
            Case "findladder"
                IdentifyExternalFunction = 84
            Case "atan"
                IdentifyExternalFunction = 85
            Case "sqr"
                IdentifyExternalFunction = 86
            Case "findvine"
                IdentifyExternalFunction = 87
            Case "setfog"
                IdentifyExternalFunction = 88
            Case "changemesh"
                IdentifyExternalFunction = 89
        End Select
    End Function

    Public Function FunctionName(ByVal iCode As String) As String
        Select Case iCode
            Case FCBASECN
                FunctionName = "BASECN"
            Case FCSTACKCN
                FunctionName = "STACKCN"
            Case FCMOVBCCN
                FunctionName = "MOVBCCN"
            Case FCMOVSCCN
                FunctionName = "MOVSCCN"
            Case FCMOVBSSC
                FunctionName = "MOVBSSC"
            Case FCMOVSCBC
                FunctionName = "MOVSCBC"
            Case FCMOVSCSC
                FunctionName = "MOVSCSC"
            Case FCADDSCCN
                FunctionName = "ADDSCCN"
            Case FCADDSCSC
                FunctionName = "ADDSCSC"
            Case FCMULSCSC
                FunctionName = "MULSCSC"
            Case FCDIVSCSC
                FunctionName = "DIVSCSC"
            Case FCSUBSCSC
                FunctionName = "SUBSCSC"
            Case FCBANDSCSC
                FunctionName = "BANDSCSC"

            Case FCMOVGCCN
                FunctionName = "MOVGCCN"
            Case FCMOVGCSC
                FunctionName = "MOVGCSC"
            Case FCMOVGSSC
                FunctionName = "MOVGSSC"
            Case FCMOVSCGC
                FunctionName = "MOVSCGC"

            Case FCMOVSCGS
                FunctionName = "MOVSCGS"
            Case FCMOVSCBS
                FunctionName = "MOVSCBS"

            Case FCEQUSCSC
                FunctionName = "EQUSCSC"
            Case FCNEQSCSC
                FunctionName = "NEQSCSC"
            Case FCGTSCSC
                FunctionName = "GTSCSC"
            Case FCGTESCSC
                FunctionName = "GTESCSC"
            Case FCORSCSC
                FunctionName = "ORSCSC"
            Case FCANDSCSC
                FunctionName = "ANDSCSC"

            Case FCJUMP
                FunctionName = "JUMP"
            Case FCJUMPZ
                FunctionName = "JUMPZ"
            Case FCJUMPNZ
                FunctionName = "JUMPNZ"

            Case FCCALL
                FunctionName = "CALL"
            Case FCRET
                FunctionName = "RET"

            Case FCEXT
                FunctionName = "EXT"
            Case Else
                FunctionName = 0
                Stop
        End Select

    End Function

    Public Function FunctionCode(ByVal sCode As String) As Integer
        Select Case sCode
            Case "BASECN"
                FunctionCode = FCBASECN
            Case "STACKCN"
                FunctionCode = FCSTACKCN

            Case "MOVBCCN"
                FunctionCode = FCMOVBCCN
            Case "MOVSCCN"
                FunctionCode = FCMOVSCCN
            Case "MOVBSSC"
                FunctionCode = FCMOVBSSC
            Case "MOVSCBC"
                FunctionCode = FCMOVSCBC
            Case "MOVSCSC"
                FunctionCode = FCMOVSCSC

            Case "MOVGCCN"
                FunctionCode = FCMOVGCCN
            Case "MOVGSSC"
                FunctionCode = FCMOVGSSC
            Case "MOVSCGC"
                FunctionCode = FCMOVSCGC
            Case "MOVGCSC"
                FunctionCode = FCMOVGCSC

            Case "ADDSCCN"
                FunctionCode = FCADDSCCN

            Case "ADDSCSC"
                FunctionCode = FCADDSCSC
            Case "MULSCSC"
                FunctionCode = FCMULSCSC
            Case "DIVSCSC"
                FunctionCode = FCDIVSCSC
            Case "SUBSCSC"
                FunctionCode = FCSUBSCSC
            Case "MOVSCGS"
                FunctionCode = FCMOVSCGS
            Case "MOVSCBS"
                FunctionCode = FCMOVSCBS
            Case "BANDSCSC"
                FunctionCode = FCBANDSCSC

            Case "JUMP"
                FunctionCode = FCJUMP
            Case "JUMPZ"
                FunctionCode = FCJUMPZ
            Case "JUMPNZ"
                FunctionCode = FCJUMPNZ

            Case "EQUSCSC"
                FunctionCode = FCEQUSCSC
            Case "NEQSCSC"
                FunctionCode = FCNEQSCSC
            Case "GTSCSC"
                FunctionCode = FCGTSCSC
            Case "GTESCSC"
                FunctionCode = FCGTESCSC
            Case "ORSCSC"
                FunctionCode = FCORSCSC
            Case "ANDSCSC"
                FunctionCode = FCANDSCSC

            Case "CALL"
                FunctionCode = FCCALL
            Case "RET"
                FunctionCode = FCRET

            Case "EXT"
                FunctionCode = FCEXT
            Case Else
                FunctionCode = 0
                Stop
        End Select
    End Function

    Public Function LoadCode(ByVal sFile As String) As String
        Dim sAll As String
        Dim sTemp As String

        Try
            FileOpen(1, sFile, OpenMode.Input)
        Catch
            LoadCode = ""
            Exit Function
        End Try
        sAll = InputString(1, LOF(1))
        FileClose(1)

        LoadCode = sAll
    End Function

    Public Function TextReplace(ByVal sString As String, ByVal sReplace As String, ByVal sWith As String) As String
        Dim iFind As Long
        Do
            iFind = InStr(sString, sReplace)
            If iFind <> 0 Then
                sString = Mid(sString, 1, iFind - 1) & sWith & Mid(sString, iFind + Len(sReplace))
            End If
        Loop While iFind <> 0
        TextReplace = sString
    End Function

    Public Function IntToString(ByVal iNum As Int32) As String
        Dim bNeg As Boolean
        Dim iNum1 As Integer, iNum2 As Integer, iNum3 As Integer, iNum4 As Integer
        Dim iTemp As Long

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

        IntToString = Chr(iNum1) & Chr(iNum2) & Chr(iNum3) & Chr(iNum4)
    End Function

    Public Function aPad(ByVal sString As String, ByVal iLen As Integer) As String
        If Len(sString) > iLen Then sString = Mid(sString, 1, iLen)
        If Len(sString) < iLen Then sString = sString & New String(Chr(0), iLen - Len(sString))
        aPad = sString
    End Function

End Module
