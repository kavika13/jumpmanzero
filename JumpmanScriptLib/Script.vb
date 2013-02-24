Imports System.IO


Public Structure SubCode
    Dim Name As String
    Dim Code As String
    Dim Args As String

    Dim LineStart As Integer
End Structure

Public Class ScriptCompiler
    Private iSubs As Integer
    Private mSubs(30) As SubCode
    Private msError As String

    Dim sCompiled As String
    Dim iCompiledLine As Long

    Dim iLNSPointer As Long
    Dim iLNS(500) As Long

    Dim iGlobals As Long
    Dim sGloNames(500) As String

    Dim iVarCount As Long
    Dim sVarNames(500) As String

    Dim iAsmLines As Integer
    Dim iAsm(10000) As Int32

    Dim iLookAheads As Integer
    Dim iLookAheadDepth As Integer
    Dim iLADepths(500) As Integer
    Dim iLA(500) As Integer

    Dim iEndIfs As Integer
    Dim iEndIfLine(500) As Integer
    Dim iEndIfLevel(500) As Integer
    Dim iIfDepth As Integer

    Dim iConstants As Integer
    Dim sConstantNames(500) As String
    Dim iConstantValues(500) As Integer

#Region "Public Interface Functions"

    Public Function GetFirstLine(ByVal iSub As Integer) As Integer
        GetFirstLine = mSubs(iSub).LineStart / 3
    End Function

    Public Sub GetLine(ByVal iLine As Long, ByRef iFunc As Integer, ByRef iArg1 As Integer, ByRef iArg2 As Integer)
        iFunc = iAsm(iLine * 3 + 0)
        iArg1 = iAsm(iLine * 3 + 1)
        iArg2 = iAsm(iLine * 3 + 2)
    End Sub

    Public Sub WriteConstants(ByVal sFile As String, ByVal sPrefix As String)
        FileOpen(1, sFile, OpenMode.Output)

        Dim sAll As String = Nothing
        Dim iLoop As Long
        Dim sLast As String

        sLast = ""
        For iLoop = 0 To iGlobals - 1
            If sGloNames(iLoop) <> sLast Then
                sAll = sAll & "define " & sPrefix & sGloNames(iLoop) & " " & iLoop & vbCrLf
            End If
            sLast = sGloNames(iLoop)
        Next

        Print(1, sAll)

        FileClose(1)
    End Sub

    Public Sub WriteBinary(ByVal sFile As String)

        Dim iLoop As Long
        Dim sAll As String = Nothing

        sAll = sAll & IntToString(iSubs + 1)

        For iLoop = 0 To iSubs
            sAll = sAll & aPad(mSubs(iLoop).Name, 20)
            sAll = sAll & IntToString(mSubs(iLoop).LineStart)
        Next

        For iLoop = 0 To iAsmLines - 1
            sAll = sAll & IntToString(iAsm(iLoop))
        Next

        FileOpen(1, sFile, OpenMode.Output, OpenAccess.Default)
        Print(1, sAll)
        FileClose(1)

    End Sub

    Public Function CompileSummary() As String
        CompileSummary = sCompiled
    End Function

#End Region

#Region "Precompiling"

    Private Sub FindVariables(ByVal sCode As String, ByVal sArgs As String, ByVal bGlobal As Boolean)
        Dim sLines() As String
        Dim iLine As Integer
        Dim sLine As String
        Dim sParts() As String
        Dim iLoop As Long

        If sArgs <> "" Then
            sParts = Split(sArgs, "~")
            For iLoop = 0 To UBound(sParts)
                sVarNames(iVarCount) = sParts(iLoop)
                iVarCount = iVarCount + 1
            Next
        End If

        sLines = Split(sCode, vbCrLf)

        For iLine = 0 To UBound(sLines)
            sLine = sLines(iLine)

            If InStr(sLine, "[") = 0 Then sLine = sLine & "~[~0~]"

            sParts = Split(sLine, "~")

            If UBound(sParts) = 4 Then
                If sParts(0) = "dim" And GoodVariableName(sParts(1)) And sParts(2) = "[" And IsNumeric(sParts(3)) And sParts(4) = "]" Then
                    For iLoop = 1 To sParts(3) + 1
                        If bGlobal Then
                            sGloNames(iGlobals) = sParts(1)
                            AddInst("MOVGCCN~" & iGlobals & "~0")
                            iGlobals = iGlobals + 1
                        Else
                            sVarNames(iVarCount) = sParts(1)
                            iVarCount = iVarCount + 1
                        End If
                    Next
                End If
            End If
        Next

        If Not bGlobal Then
            AddInst("STACKCN~" & iVarCount)
        End If

    End Sub

    Private Sub FindConstants(ByVal sCode As String)
        Dim iLine As Long
        Dim sLine As String
        Dim sLines() As String
        Dim sParts() As String

        iConstants = 0

        sLines = Split(sCode, vbCrLf)
        For iLine = 0 To UBound(sLines)
            sLine = sLines(iLine)
            sLine = ParseTokens(sLine)
            sParts = Split(sLine, "~")
            If UBound(sParts) = 2 Then
                If sParts(0) = "define" Then
                    iConstantValues(iConstants) = sParts(2)
                    sConstantNames(iConstants) = sParts(1)
                    iConstants = iConstants + 1
                End If
            End If
        Next
    End Sub

    Private Sub AddIncludes(includeDirectory As String, ByRef sCode As String)
        Dim iLine As Long
        Dim sLine As String
        Dim sLines() As String
        Dim sParts() As String

        sLines = Split(sCode, vbCrLf)
        For iLine = 0 To UBound(sLines)
            sLine = sLines(iLine)
            sLine = ParseTokens(sLine)
            sParts = Split(sLine, "~")
            If UBound(sParts) = 1 Then
                If sParts(0) = "include" Then
                    sCode = sCode & LoadCode(Path.Combine(includeDirectory, sParts(1) & ".JMS"))
                End If
            End If
        Next
    End Sub

#End Region

#Region "Compiling"

    Public Sub Compile(sourceDirectory As String, ByVal sCode As String)

        iLookAheads = 0

        sCompiled = ""
        iCompiledLine = 0

        sCode = TextReplace(sCode, Chr(9), " ")

        AddIncludes(sourceDirectory, sCode)
        FindConstants(sCode)

        CodeToSubs(sCode)

        Dim iLoop As Long
        Dim iLine As Long
        Dim sLine As String
        Dim sLines() As String

        iGlobals = 0
        iAsmLines = 0

        mSubs(0).LineStart = iAsmLines
        FindVariables(mSubs(0).Code, "", True)
        AddInst("RET~0~0")

        For iLoop = 1 To iSubs
            iLNSPointer = 0
            iVarCount = 0

            mSubs(iLoop).LineStart = iAsmLines

            FindVariables(mSubs(iLoop).Code, mSubs(iLoop).Args, False)

            sLines = Split(mSubs(iLoop).Code, vbCrLf)

            iIfDepth = 0
            iLookAheads = 0

            For iLine = 0 To UBound(sLines)
                sLine = sLines(iLine)

                If Left(sLine, 1) <> "'" Then
                    CompileLine(sLine)
                End If

                If Len(msError) > 0 Then
                    AddInstComment("ERROR: " & vbTab & sLine & vbCrLf)
                    AddInstComment(vbTab & msError & vbCrLf)
                    msError = ""
                End If
            Next

            If iIfDepth <> 0 Then
                AddInstComment("ERROR: " & vbTab & "sub " & mSubs(iLoop).Name & vbCrLf)
                AddInstComment(vbTab & """If"" without ""End if""" & vbCrLf)
            ElseIf iLookAheads <> 0 Then
                AddInstComment("ERROR: " & vbTab & "sub " & mSubs(iLoop).Name & vbCrLf)
                AddInstComment(vbTab & "Nesting problem" & vbCrLf)
            End If

            AddInst("STACKCN~" & -iVarCount & "~0")
            AddInst("RET~0~0")

        Next

        FixCalls()

    End Sub

    Private Sub FixCalls()
        Dim iLine As Long
        For iLine = 0 To iAsmLines - 1 Step 3
            If FunctionName(iAsm(iLine)) = "CALL" Then
                iAsm(iLine + 1) = (mSubs(iAsm(iLine + 1) \ 256).LineStart / 3 - 1) * 256
            End If
        Next
    End Sub

    Private Sub AddInstComment(ByVal sComment As String)
        sCompiled = sCompiled & Replace(sComment, "~", " ")
    End Sub

    Private Sub AddInst(ByVal sLine As String)
        iCompiledLine = iCompiledLine + 1
        '        sCompiled = sCompiled & iCompiledLine & "." & sLine

        Dim sParts() As String

        sParts = Split(sLine, "~")

        iAsm(iAsmLines) = FunctionCode(sParts(0))
        If UBound(sParts) > 0 Then
            iAsm(iAsmLines + 1) = sParts(1) * 256
        Else
            iAsm(iAsmLines + 1) = 0
        End If
        If UBound(sParts) > 1 Then
            iAsm(iAsmLines + 2) = sParts(2) * 256
        Else
            iAsm(iAsmLines + 2) = 0
        End If

        '     sCompiled = sCompiled & "&nbsp;&nbsp;<I>(" & vbCrLf

        '     sCompiled = sCompiled & iAsm(iAsmLines) & ","
        '     sCompiled = sCompiled & iAsm(iAsmLines + 1) \ 256 & ","
        '     sCompiled = sCompiled & iAsm(iAsmLines + 2) \ 256

        iAsmLines = iAsmLines + 3

        '     sCompiled = sCompiled & ")</I><BR>" & vbCrLf
    End Sub

    Private Function GetGlobalRef(ByVal sName As String) As Long
        GetGlobalRef = -1
        Dim iLoop As Long
        For iLoop = 0 To iGlobals - 1
            If sGloNames(iLoop) = sName Then
                GetGlobalRef = iLoop
                Exit Function
            End If
        Next
    End Function

    Private Function GetVariableRef(ByVal sName As String) As Long
        GetVariableRef = -1
        Dim iLoop As Long
        For iLoop = 0 To iVarCount - 1
            If sVarNames(iLoop) = sName Then
                GetVariableRef = iLoop
                Exit Function
            End If
        Next
    End Function

    Private Sub CodeToSubs(ByVal sCode As String)
        Dim sLines() As String
        Dim iLine As Integer
        Dim sInSub As String = ""

        mSubs(0).Name = "globals"

        sLines = Split(sCode, vbCrLf)

        For iLine = 0 To UBound(sLines)
            Dim sLine As String
            Dim sParts() As String
            Dim iPart As Long
            Dim sParm1 As String
            Dim sParm2 As String

            sLine = sLines(iLine)
            sLine = ParseTokens(sLine)
            sParts = Split(sLine, "~")
            sParm1 = "" : If UBound(sParts) > -1 Then sParm1 = sParts(0)
            sParm2 = "" : If UBound(sParts) > 0 Then sParm2 = sParts(1)

            If sParm1 = "sub" Then
                iSubs = iSubs + 1
                mSubs(iSubs).Code = ""
                mSubs(iSubs).Args = ""

                If sInSub <> "" Then
                    msError = "%Can't have sub inside sub"
                Else
                    If sParts(2) <> "(" Or sParts(UBound(sParts)) <> ")" Then
                        msError = "%Expecting brackets"
                    ElseIf Not GoodVariableName(sParts(1)) Then
                        msError = "%Expecting good sub name - not " & sParts(1)
                    Else
                        For iPart = 3 To UBound(sParts) - 1
                            If iPart Mod 2 = 1 Then
                                If Not GoodVariableName(sParts(iPart)) Then
                                    msError = "%Expecting good variable name - not " & sParts(iPart)
                                Else
                                    mSubs(iSubs).Args = mSubs(iSubs).Args & sParts(iPart) & "~"
                                End If
                            Else
                                If sParts(iPart) <> "," Then
                                    msError = "%Expecting comma"
                                End If
                            End If
                        Next
                    End If
                End If

                If Len(mSubs(iSubs).Args) > 0 Then
                    mSubs(iSubs).Args = Left(mSubs(iSubs).Args, Len(mSubs(iSubs).Args) - 1)
                End If

                If msError = "" Then
                    mSubs(iSubs).Name = sParm2
                    sInSub = sParm2
                Else
                    iSubs = iSubs - 1
                End If

            ElseIf sParm1 = "end" And sParm2 = "sub" Then
                sInSub = ""
            ElseIf sInSub <> "" Then
                mSubs(iSubs).Code = mSubs(iSubs).Code & sLine & vbCrLf
            Else
                mSubs(0).Code = mSubs(0).Code & sLine & vbCrLf
            End If

        Next

    End Sub

    Private Sub CompileLine(ByVal sLine As String)
        Dim sParts() As String
        Dim s0 As String = "", s1 As String = Nothing, s2 As String = Nothing, s3 As String = Nothing, s4 As String
        Dim iRef As Long

        sParts = Split(sLine, "~")
        If (UBound(sParts) >= 0) Then s0 = sParts(0)
        If (UBound(sParts) >= 1) Then s1 = sParts(1)
        If (UBound(sParts) >= 2) Then s2 = sParts(2)
        If (UBound(sParts) >= 3) Then s3 = sParts(3)
        If (UBound(sParts) >= 4) Then s4 = sParts(3)

        If s0 = "" Then Exit Sub

        Dim iArrayLen As Long

        If s0 = "dim" Then
            If s2 = "" Then
                iArrayLen = 1
            Else
                iArrayLen = s3
            End If

            iRef = GetVariableRef(s1)

            AddInst("MOVBCCN~" & iRef & "~0")
            Exit Sub
        End If

        Dim sEval As String
        Dim iLoop As Long
        Dim iStart As Long
        Dim iGRef As Long

        iGRef = GetGlobalRef(s0)
        iRef = GetVariableRef(s0)
        If iRef <> -1 Or iGRef <> -1 Then

            If iGRef <> -1 Then iRef = iGRef

            If s1 = "[" Then
                sEval = ""
                For iLoop = 2 To UBound(sParts)
                    If sParts(iLoop) = "]" Then Exit For
                    sEval = sEval & sParts(iLoop) & "~"
                Next
                iStart = iLoop + 1
                Evaluate(sEval, 0)
                AddInst("ADDSCCN~0~" & iRef)
            Else
                iStart = 1
                AddInst("MOVSCCN~0~" & iRef)
            End If

            If iStart > UBound(sParts) Then Stop
            If sParts(iStart) <> "=" Then Stop

            sEval = ""
            For iLoop = iStart + 1 To UBound(sParts)
                sEval = sEval & sParts(iLoop) & "~"
            Next
            Evaluate(sEval, 1)

            If iGRef <> -1 Then
                AddInst("MOVGSSC~0~1")
            Else
                AddInst("MOVBSSC~0~1")
            End If
        ElseIf s0 = "while" Then
            iLA(iLookAheads) = iAsmLines
            iLADepths(iLookAheads) = iIfDepth
            iLookAheads = iLookAheads + 1

            sEval = Mid(sLine, InStr(sLine, "~") + 1)
            Evaluate(sEval, 0)
            iLA(iLookAheads) = iAsmLines
            iLADepths(iLookAheads) = iIfDepth

            iLookAheads = iLookAheads + 1
            AddInst("JUMPZ~-1")
        ElseIf s0 = "if" Then
            iIfDepth = iIfDepth + 1

            sEval = Mid(sLine, InStr(sLine, "~") + 1)
            Evaluate(sEval, 0)
            iLA(iLookAheads) = iAsmLines
            iLADepths(iLookAheads) = iIfDepth

            iLookAheads = iLookAheads + 1
            AddInst("JUMPZ~-1")
        ElseIf s0 = "elseif" Then
            iEndIfLine(iEndIfs) = iAsmLines
            iEndIfLevel(iEndIfs) = iIfDepth
            iEndIfs = iEndIfs + 1

            AddInst("JUMP~-1")

            iLookAheads = iLookAheads - 1
            iAsm(iLA(iLookAheads) + 1) = (iAsmLines / 3 - 1) * 256

            sEval = Mid(sLine, InStr(sLine, "~") + 1)
            Evaluate(sEval, 0)
            iLA(iLookAheads) = iAsmLines
            iLADepths(iLookAheads) = iIfDepth

            iLookAheads = iLookAheads + 1
            AddInst("JUMPZ~-1")
        ElseIf s0 = "else" Then
            iEndIfLine(iEndIfs) = iAsmLines
            iEndIfLevel(iEndIfs) = iIfDepth
            iEndIfs = iEndIfs + 1

            AddInst("JUMP~-1")

            iLookAheads = iLookAheads - 1
            iAsm(iLA(iLookAheads) + 1) = (iAsmLines / 3 - 1) * 256

        ElseIf s0 = "end" And s1 = "if" Then

            If iLookAheads > 0 Then
                If iLADepths(iLookAheads - 1) = iIfDepth Then
                    iLookAheads = iLookAheads - 1
                    iAsm(iLA(iLookAheads) + 1) = (iAsmLines / 3 - 1) * 256
                End If
            End If

            For iLoop = iEndIfs - 1 To 0 Step -1
                If iEndIfLevel(iLoop) = iIfDepth Then
                    iAsm(iEndIfLine(iLoop) + 1) = (iAsmLines / 3 - 1) * 256
                    iEndIfs = iEndIfs - 1
                End If
            Next

            iIfDepth = iIfDepth - 1

        ElseIf s0 = "loop" Then

            iLookAheads = iLookAheads - 1
            iAsm(iLA(iLookAheads) + 1) = (iAsmLines / 3) * 256

            iLookAheads = iLookAheads - 1
            AddInst("JUMP~" & (iLA(iLookAheads) / 3 - 1))
        ElseIf s0 = "return" Then
            sEval = Mid(sLine, InStr(sLine, "~") + 1)
            Evaluate(sEval, 0)
            AddInst("MOVSCCN~1~0")
            AddInst("MOVBSSC~1~0")
            AddInst("STACKCN~" & -iVarCount & "~0")
            AddInst("RET~0~0")
        Else
            Evaluate(sLine, 0)
        End If

    End Sub

    Private Sub Evaluate(ByVal sExp As String, ByVal iSP As Long)
        Dim iNSP As Long
        Dim sParts() As String

        Debug.Write(sExp & vbCrLf)

        '        If sExp = "" Then Stop

        If Left(sExp, 1) = "~" Then sExp = Mid(sExp, 2)
        If Right(sExp, 1) = "~" Then sExp = Left(sExp, Len(sExp) - 1)

        iNSP = iSP + 1
        sParts = Split(sExp, "~")

        Dim iLoop As Long
        Dim iBracket As Long
        Dim iBracketStart As Long
        Dim sEval As String
        Dim iClear As Long
        Dim iERef As Long
        Dim iLRef As Long

        Dim iVRef As Long
        Dim iGRef As Long

        iBracket = 0
        sEval = ""
        For iLoop = 0 To UBound(sParts)
            If sParts(iLoop) = "]" Then
                iBracket = iBracket - 1
                If iBracket = 0 Then
                    If iBracketStart = 0 Then
                        iVRef = -1
                        iGRef = -1
                    Else
                        iVRef = GetVariableRef(sParts(iBracketStart - 1))
                        iGRef = GetGlobalRef(sParts(iBracketStart - 1))
                    End If
                    If iVRef <> -1 Or iGRef <> -1 Then

                        If iVRef <> -1 Then
                            AddInst("MOVSCCN~" & iNSP & "~" & iVRef)
                            Evaluate(sEval, iNSP + 1)
                            AddInst("ADDSCSC~" & iNSP & "~" & iNSP + 1)
                            AddInst("MOVSCBS~" & iNSP & "~" & iNSP)
                        Else
                            AddInst("MOVSCCN~" & iNSP & "~" & iGRef)
                            Evaluate(sEval, iNSP + 1)
                            AddInst("ADDSCSC~" & iNSP & "~" & iNSP + 1)
                            AddInst("MOVSCGS~" & iNSP & "~" & iNSP)
                        End If

                        For iClear = iBracketStart - 1 To iLoop
                            sParts(iClear) = ""
                        Next
                        sParts(iBracketStart - 1) = "_" & iNSP
                        iNSP = iNSP + 1
                    End If
                End If
            End If
            If iBracket > 0 Then
                If sParts(iLoop) = "[" Then iBracket = iBracket + 1
                sEval = sEval & sParts(iLoop) & "~"
            End If
            If sParts(iLoop) = "[" And iBracket = 0 Then
                iBracket = iBracket + 1
                iBracketStart = iLoop
                sEval = ""
            End If
        Next

        iBracket = 0
        sEval = ""
        For iLoop = 0 To UBound(sParts)
            If sParts(iLoop) = ")" Then
                iBracket = iBracket - 1
                If iBracket = 0 Then
                    If iBracketStart = 0 Then
                        iERef = -1
                        iLRef = -1
                    Else
                        iERef = IdentifyExternalFunction(sParts(iBracketStart - 1))
                        iLRef = IdentifyFunction(sParts(iBracketStart - 1))
                    End If
                    If iERef <> -1 Or iLRef <> -1 Then
                        If iERef <> -1 Then
                            EvaluateExtFunction(iERef, sEval, iNSP)
                        Else
                            EvaluateFunction(iLRef, sEval, iNSP)
                        End If
                        For iClear = iBracketStart - 1 To iLoop
                            sParts(iClear) = ""
                        Next
                        sParts(iBracketStart - 1) = "_" & iNSP
                        iNSP = iNSP + 1
                    Else
                        Evaluate(sEval, iNSP)
                        For iClear = iBracketStart To iLoop
                            sParts(iClear) = ""
                        Next
                        sParts(iBracketStart) = "_" & iNSP
                        iNSP = iNSP + 1
                    End If
                End If
            End If
            If iBracket > 0 Then
                If sParts(iLoop) = "(" Then iBracket = iBracket + 1
                sEval = sEval & sParts(iLoop) & "~"
            End If
            If sParts(iLoop) = "(" And iBracket = 0 Then
                iBracket = iBracket + 1
                iBracketStart = iLoop
                sEval = ""
            End If
        Next

        sExp = "~"
        For iLoop = 0 To UBound(sParts)
            sExp = sExp & sParts(iLoop)
            If Len(sParts(iLoop)) > 0 Then sExp = sExp & "~"
        Next

        Dim iRef As Long

        sParts = Split(sExp, "~")

        If UBound(sParts) = 2 Then
            iRef = GetVariableRef(sParts(1))
            If iRef <> -1 Then
                AddInst("MOVSCBC~" & iSP & "~" & iRef)
                Exit Sub
            End If
            If Left(sParts(1), 1) = "#" Then
                iRef = GetConstantValue(Mid(sParts(1), 2))
                AddInst("MOVSCCN~" & iSP & "~" & iRef)
                Exit Sub
            End If
            If Left(sParts(1), 1) = "_" Then
                iRef = Mid(sParts(1), 2)
                AddInst("MOVSCSC~" & iSP & "~" & iRef)
                Exit Sub
            End If
            If IsNumeric(sParts(1)) Then
                AddInst("MOVSCCN~" & iSP & "~" & sParts(1))
                Exit Sub
            End If
            iRef = GetGlobalRef(sParts(1))
            If iRef <> -1 Then
                AddInst("MOVSCGC~" & iSP & "~" & iRef)
                Exit Sub
            End If

        End If

        Dim sBefore As String = Nothing
        Dim sAfter As String = Nothing
        Dim sOp As String

        sOp = ""

        If sOp = "" Then sOp = FindOp(sExp, "~&&~", sBefore, sAfter)
        If sOp = "" Then sOp = FindOp(sExp, "~||~", sBefore, sAfter)

        If sOp = "" Then sOp = FindOp(sExp, "~=~", sBefore, sAfter)
        If sOp = "" Then sOp = FindOp(sExp, "~!=~", sBefore, sAfter)
        If sOp = "" Then sOp = FindOp(sExp, "~<~", sBefore, sAfter)
        If sOp = "" Then sOp = FindOp(sExp, "~>~", sBefore, sAfter)
        If sOp = "" Then sOp = FindOp(sExp, "~<=~", sBefore, sAfter)
        If sOp = "" Then sOp = FindOp(sExp, "~>=~", sBefore, sAfter)

        If sOp = "" Then sOp = FindOp(sExp, "~+~", sBefore, sAfter)
        If sOp = "" Then sOp = FindOp(sExp, "~-~", sBefore, sAfter)

        If sOp = "" Then sOp = FindOp(sExp, "~&~", sBefore, sAfter)

        If sOp = "" Then sOp = FindOp(sExp, "~*~", sBefore, sAfter)
        If sOp = "" Then sOp = FindOp(sExp, "~/~", sBefore, sAfter)

        If sOp <> "" Then
            Evaluate(sBefore, iNSP)
            iNSP = iNSP + 1
            Evaluate(sAfter, iNSP)
            iNSP = iNSP + 1
        End If

        If sOp = "~+~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 2)
            AddInst("ADDSCSC~" & iSP & "~" & iNSP - 1)
            Exit Sub
        End If

        If sOp = "~-~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 2)
            AddInst("SUBSCSC~" & iSP & "~" & iNSP - 1)
            Exit Sub
        End If

        If sOp = "~*~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 2)
            AddInst("MULSCSC~" & iSP & "~" & iNSP - 1)
            Exit Sub
        End If

        If sOp = "~&~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 2)
            AddInst("BANDSCSC~" & iSP & "~" & iNSP - 1)
            Exit Sub
        End If

        If sOp = "~/~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 2)
            AddInst("DIVSCSC~" & iSP & "~" & iNSP - 1)
            Exit Sub
        End If

        If sOp = "~=~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 2)
            AddInst("EQUSCSC~" & iSP & "~" & iNSP - 1)
            Exit Sub
        End If
        If sOp = "~!=~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 2)
            AddInst("NEQSCSC~" & iSP & "~" & iNSP - 1)
            Exit Sub
        End If
        If sOp = "~<~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 1)
            AddInst("GTSCSC~" & iSP & "~" & iNSP - 2)
            Exit Sub
        End If
        If sOp = "~>~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 2)
            AddInst("GTSCSC~" & iSP & "~" & iNSP - 1)
            Exit Sub
        End If
        If sOp = "~<=~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 1)
            AddInst("GTESCSC~" & iSP & "~" & iNSP - 2)
            Exit Sub
        End If
        If sOp = "~>=~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 2)
            AddInst("GTESCSC~" & iSP & "~" & iNSP - 1)
            Exit Sub
        End If

        If sOp = "~&&~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 2)
            AddInst("ANDSCSC~" & iSP & "~" & iNSP - 1)
            Exit Sub
        End If

        If sOp = "~||~" Then
            AddInst("MOVSCSC~" & iSP & "~" & iNSP - 2)
            AddInst("ORSCSC~" & iSP & "~" & iNSP - 1)
            Exit Sub
        End If

        msError = "Invalid expression"

    End Sub

#End Region

#Region "Support Functions"
    Private Function GetConstantValue(ByVal sName As String) As Integer
        GetConstantValue = Nothing
        Dim iLoop As Long

        For iLoop = 0 To iConstants - 1
            If sConstantNames(iLoop) = sName Then
                GetConstantValue = iConstantValues(iLoop)
            End If
        Next
    End Function

    Private Function IdentifyFunction(ByVal sName As String) As Long
        IdentifyFunction = -1

        Dim iLoop As Long

        For iLoop = 1 To iSubs
            If mSubs(iLoop).Name = sName Then
                IdentifyFunction = iLoop
                Exit Function
            End If
        Next

    End Function

    Private Function FindOp(ByVal sExp As String, ByVal sOp As String, ByRef sBefore As String, ByRef sAfter As String) As String
        FindOp = Nothing

        If InStr(sExp, sOp) Then
            sBefore = Left(sExp, InStr(sExp, sOp) - 1)
            sAfter = Mid(sExp, InStr(sExp, sOp) + Len(sOp))
            FindOp = sOp
        End If
    End Function

    Private Sub EvaluateFunction(ByVal iFunc As Long, ByVal sPass As String, ByVal iSP As Long)
        Dim sArgs() As String
        Dim iArg As Long
        Dim iLoop As Long
        Dim iNSP As Long

        iNSP = iSP + 1

        If Len(sPass) > 0 Then

            sPass = MaskCommasInBrackets(sPass)
            sArgs = Split(sPass, "~,~")

            For iArg = 0 To UBound(sArgs)
                sArgs(iLoop) = TextReplace(sArgs(iLoop), "!!!", ",")
                Evaluate(sArgs(iArg), iNSP)
                iNSP = iNSP + 1
            Next
        End If

        AddInst("BASECN~" & iVarCount + iSP + 1)
        AddInst("STACKCN~" & iSP + 1)

        AddInst("CALL~" & iFunc)

        AddInst("STACKCN~" & -(iSP + 1))
        AddInst("BASECN~" & -(iVarCount + iSP + 1))

        AddInst("MOVSCSC~" & iSP & "~" & iSP + 1)
    End Sub

    Private Function MaskCommasInBrackets(ByVal sExp As String) As String
        Dim sParts() As String
        Dim iLoop As Long
        Dim iBracket As Long
        Dim sAll As String = Nothing

        sParts = Split(sExp, "~")
        For iLoop = 0 To UBound(sParts)
            If sParts(iLoop) = "(" Then iBracket = iBracket + 1
            If sParts(iLoop) = ")" Then iBracket = iBracket - 1
            If sParts(iLoop) = "," And iBracket > 0 Then
                sParts(iLoop) = "!!!"
            End If
            sAll = sAll & sParts(iLoop) & "~"
        Next

        If Len(sAll) > 0 Then sAll = Left(sAll, Len(sAll) - 1)

        MaskCommasInBrackets = sAll
    End Function

    Private Sub EvaluateExtFunction(ByVal iFunc As Long, ByVal sPass As String, ByVal iSP As Long)
        Dim sArgs() As String
        Dim iArg As Long
        Dim iLoop As Long
        Dim iNSP As Long

        iNSP = iSP + 1

        sPass = MaskCommasInBrackets(sPass)
        sArgs = Split(sPass, "~,~")

        For iArg = 0 To UBound(sArgs)
            sArgs(iLoop) = TextReplace(sArgs(iLoop), "!!!", ",")
            If Len(sArgs(iArg)) > 0 Then
                Evaluate(sArgs(iArg), iNSP)
                iNSP = iNSP + 1
            End If
        Next

        AddInst("BASECN~" & iVarCount + iSP + 1)
        AddInst("STACKCN~" & iSP + 1)

        AddInst("EXT~" & iFunc)

        AddInst("STACKCN~" & -(iSP + 1))
        AddInst("BASECN~" & -(iVarCount + iSP + 1))
    End Sub

#End Region

#Region "Boring helper functions"
    Private Function GoodVariableName(ByVal sName As String) As Boolean
        Dim sTemp As String
        GoodVariableName = True
        sTemp = "a" & ParseTokens(sName) & "a"
        If InStr(sTemp, "~") Then GoodVariableName = False
        If IsNumeric(Left(sName, 1)) Then GoodVariableName = False
    End Function

    Private Function ParseTokens(ByVal sLine As String) As String
        Dim sChar As String
        Dim iChar As Long
        Dim sBuild As String = Nothing
        Dim sDone As String = Nothing
        Dim sNext As String
        Dim sOperator As String

        Dim sLastThing As String = Nothing

        Dim bQuote As Boolean
        Dim sQuoted As String
        Dim iStart As Long
        Dim iEnd As Long
        Dim sVals As String
        Dim iLoop As Long

        While InStr(sLine, """") <> 0
            iStart = InStr(sLine, """")
            sQuoted = Mid(sLine, iStart + 1)
            iEnd = InStr(sQuoted, """")
            If iEnd = 0 Then
                MsgBox("Unterminated string!")
                ParseTokens = Nothing
                Exit Function
            End If
            sQuoted = Left(sQuoted, iEnd - 1)
            sVals = Len(sQuoted)
            For iLoop = 1 To Len(sQuoted)
                sVals = sVals & "," & Asc(Mid(sQuoted, iLoop, 1))
            Next
            sLine = Left(sLine, iStart - 1) & sVals & Mid(sLine, iStart + iEnd + 1)
        End While

        For iChar = 1 To Len(sLine)

            sChar = Mid(sLine, iChar, 1)
            If Len(sLine) > iChar Then
                sNext = Mid(sLine, iChar + 1, 1)
            Else
                sNext = ""
            End If

            If bQuote Then
                If sChar = """" Then
                    If sNext = """" Then
                        sBuild = sBuild & sChar
                        iChar = iChar + 1
                    Else
                        bQuote = False
                        sDone = sDone & sBuild & """~"
                        sBuild = ""
                    End If
                Else
                    sBuild = sBuild & sChar
                End If
            ElseIf sChar = """" Then
                sDone = sDone & sBuild & "~"
                sBuild = """"
                bQuote = True
            ElseIf sChar = " " Then
                If Len(sBuild) > 0 Then
                    sDone = sDone & sBuild & "~"
                    sLastThing = sBuild
                    sBuild = ""
                End If
            Else
                sOperator = ""
                If sChar = "!" And sNext = "=" Then
                    sOperator = "!="
                ElseIf sChar = "<" And sNext = "=" Then
                    sOperator = "<="
                ElseIf sChar = "&" And sNext = "&" Then
                    sOperator = "&&"
                ElseIf sChar = ">" And sNext = "=" Then
                    sOperator = ">="
                ElseIf sChar = "<" And sNext = ">" Then
                    sOperator = "!="
                ElseIf sChar = "-" And sBuild = "" And (sLastThing = "=" Or sLastThing = "(" Or sLastThing = "+" Or sLastThing = "[" Or sLastThing = "/" Or sLastThing = "&" Or sLastThing = "*" Or sLastThing = "<" Or sLastThing = ">" Or sLastThing = "," Or sLastThing = "-") Then

                ElseIf sChar = "[" Or sChar = "]" Or sChar = "*" Or sChar = "+" Or sChar = "/" Or sChar = "-" Or sChar = "(" Or sChar = ")" Or sChar = "=" Or sChar = "<" Or sChar = ">" Or sChar = "!" Or sChar = "," Or sChar = "&" Then
                    sOperator = sChar
                End If

                If Len(sOperator) > 1 Then iChar = iChar + 1

                If sOperator <> "" Then
                    sDone = sDone & sBuild & "~" & sOperator & "~"
                    sLastThing = sOperator
                    sBuild = ""
                Else
                    sBuild = sBuild & LCase(sChar)
                End If

            End If
        Next

        If Len(sBuild) > 0 Then sDone = sDone & sBuild & "~"
        If Len(sDone) > 0 Then sDone = Left(sDone, Len(sDone) - 1)
        sDone = TextReplace(sDone, "~~", "~")

        If bQuote Then sDone = "%Unterminated string"

        ParseTokens = sDone

    End Function

#End Region

End Class


