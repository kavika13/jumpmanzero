

Public Class RunScript
    Dim oScript As ScriptCompiler

    Public Sub SetScript(ByVal vScript As ScriptCompiler)
        oScript = vScript
    End Sub

    Dim dStarted As Date

    Dim iGlobals(500) As Integer

    Dim iStack(6000) As Integer
    Dim iSP As Integer

    Dim iCS(1000) As Integer
    Dim iCallStack As Integer

    Dim iBP As Integer
    Dim iIP As Integer

    Dim bScriptDone As Boolean

    Dim sOutput As String

    Public Function GetOutput() As String
        GetOutput = sOutput
    End Function

    Public Sub RunScript(ByVal iSub As Integer)
        sOutput = ""

        dStarted = Now

        Dim iFunc As Integer
        Dim iArg1 As Integer
        Dim iArg2 As Integer

        bScriptDone = False
        iBP = 1
        iSP = 1
        iCallStack = 0
        iIP = oScript.GetFirstLine(iSub)

        While Not bScriptDone
            oScript.GetLine(iIP, iFunc, iArg1, iArg2)
            RunLine(iFunc, iArg1, iArg2)
            iIP = iIP + 1
        End While
    End Sub

    Private Sub RunLine(ByVal iFunc As Integer, ByVal iArg1 As Integer, ByVal iArg2 As Integer)
        Dim sFunc As String
        Dim rArg1 As Integer
        Dim rArg2 As Integer

        rArg1 = iArg1
        rArg2 = iArg2

        iArg1 = iArg1 \ 256
        iArg2 = iArg2 \ 256

        sFunc = FunctionName(iFunc)

        Select Case sFunc
            Case "BASECN"
                iBP = iBP + iArg1
            Case "STACKCN"
                iSP = iSP + iArg1

            Case "MOVBCCN"
                iStack(iBP + iArg1) = rArg2
            Case "MOVSCCN"
                iStack(iSP + iArg1) = rArg2

            Case "MOVBSSC"
                iStack(iBP + iStack(iSP + iArg1) \ 256) = iStack(iSP + iArg2)
            Case "MOVSCBC"
                iStack(iSP + iArg1) = iStack(iBP + iArg2)
            Case "MOVSCSC"
                iStack(iSP + iArg1) = iStack(iSP + iArg2)
            Case "ADDSCCN"
                iStack(iSP + iArg1) = iStack(iSP + iArg1) + rArg2

            Case "ADDSCSC"
                iStack(iSP + iArg1) = iStack(iSP + iArg1) + iStack(iSP + iArg2)
            Case "SUBSCSC"
                iStack(iSP + iArg1) = iStack(iSP + iArg1) - iStack(iSP + iArg2)
            Case "MULSCSC"
                iStack(iSP + iArg1) = iStack(iSP + iArg1) * iStack(iSP + iArg2) \ 256
            Case "DIVSCSC"
                iStack(iSP + iArg1) = iStack(iSP + iArg1) * 256 / iStack(iSP + iArg2)

            Case "MOVSCGS"
                iStack(iSP + iArg1) = iGlobals(iStack(iSP + iArg2) / 256)
            Case "MOVSCBS"
                iStack(iSP + iArg1) = iStack(iBP + iStack(iSP + iArg2) / 256)

            Case "MOVGCCN"
                iGlobals(iArg1) = rArg2
            Case "MOVGSSC"
                iGlobals(iStack(iSP + iArg1) \ 256) = iStack(iSP + iArg2)
            Case "MOVSCGC"
                iStack(iSP + iArg1) = iGlobals(iArg2)
            Case "MOVGCSC"
                iGlobals(iArg1) = iStack(iSP + iArg2)

            Case "EQUSCSC"
                iStack(iSP + iArg1) = IIf(iStack(iSP + iArg1) = iStack(iSP + iArg2), 1, 0)
            Case "NEQSCSC"
                iStack(iSP + iArg1) = IIf(iStack(iSP + iArg1) <> iStack(iSP + iArg2), 1, 0)
            Case "GTSCSC"
                iStack(iSP + iArg1) = IIf(iStack(iSP + iArg1) > iStack(iSP + iArg2), 1, 0)
            Case "GTESCSC"
                iStack(iSP + iArg1) = IIf(iStack(iSP + iArg1) >= iStack(iSP + iArg2), 1, 0)

            Case "ORSCSC"
                iStack(iSP + iArg1) = IIf(iStack(iSP + iArg1) <> 0 Or iStack(iSP + iArg2) <> 0, 1, 0)
            Case "ANDSCSC"
                iStack(iSP + iArg1) = IIf(iStack(iSP + iArg1) <> 0 And iStack(iSP + iArg2) <> 0, 1, 0)
            Case "BANDSCSC"
                iStack(iSP + iArg1) = iStack(iSP + iArg1) And iStack(iSP + iArg2)

            Case "CALL"
                iCS(iCallStack) = iIP
                iCallStack = iCallStack + 1
                iIP = iArg1
            Case "RET"
                iCallStack = iCallStack - 1
                If iCallStack = -1 Then
                    bScriptDone = True
                Else
                    iIP = iCS(iCallStack)
                End If

            Case "JUMP"
                iIP = iArg1
            Case "JUMPZ"
                If (iStack(iSP)) = 0 Then iIP = iArg1
            Case "JUMPNZ"
                If (iStack(iSP)) <> 0 Then iIP = iArg1

            Case "EXT"
                iStack(iBP - 1) = ExtFunction(iArg1) * 256
            Case Else
                Stop
        End Select
    End Sub

    Private Function ExtFunction(ByVal iFunc As Integer) As Integer
        Dim iArg1 As Long
        Dim iArg2 As Long

        iArg1 = iStack(iSP + 0) / 256
        iArg2 = iStack(iSP + 1) / 256

        Select Case ExtFunctionName(iFunc)
            Case "print"
                If iStack(iSP) / 256 = -1 Then
                    sOutput = sOutput & vbCrLf
                ElseIf iStack(iSP) / 256 = -2 Then
                    sOutput = sOutput & " "
                ElseIf iStack(iSP) / 256 = -3 Then
                    sOutput = sOutput & Math.Round((Now.ToOADate - dStarted.ToOADate) * 24 * 60 * 60, 2)
                    dStarted = Now
                Else
                    sOutput = sOutput & iStack(iSP) / 256
                End If
            Case "rnd"
                ExtFunction = (CLng(Rnd() * 10000) Mod (iArg2 - iArg1 + 1)) + iArg1
            Case "setext"
                sOutput = sOutput & "SetExt(" & iStack(iSP) \ 256 & "," & iStack(iSP + 1) / 256 & ")" & vbCrLf
            Case "getext"
                sOutput = sOutput & "GetExt(" & iStack(iSP) \ 256 & ")=1" & vbCrLf
                ExtFunction = 1
            Case Else
                sOutput = sOutput & "[" & ExtFunctionName(iFunc) & "] "
                sOutput = sOutput & "[" & iStack(iSP + 0) / 256 & "] "
                sOutput = sOutput & "[" & iStack(iSP + 1) / 256 & "] "
                sOutput = sOutput & "[" & iStack(iSP + 2) / 256 & "] "
                sOutput = sOutput & "[" & iStack(iSP + 3) / 256 & "] "
                sOutput = sOutput & vbCrLf
        End Select
    End Function

End Class
