Imports System.IO

Public Class Form1
    Inherits System.Windows.Forms.Form

#Region " Windows Form Designer generated code "

    Public Sub New()
        MyBase.New()

        'This call is required by the Windows Form Designer.
        InitializeComponent()

        'Add any initialization after the InitializeComponent() call

    End Sub

    'Form overrides dispose to clean up the component list.
    Protected Overloads Overrides Sub Dispose(ByVal disposing As Boolean)
        If disposing Then
            If Not (components Is Nothing) Then
                components.Dispose()
            End If
        End If
        MyBase.Dispose(disposing)
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    Friend WithEvents picGraphics As System.Windows.Forms.PictureBox
    Friend WithEvents txtOutput As System.Windows.Forms.TextBox
    Friend WithEvents picSample As System.Windows.Forms.PictureBox
    Friend WithEvents cmdSetSample As System.Windows.Forms.Button
    Friend WithEvents picColors As System.Windows.Forms.PictureBox
    Friend WithEvents cmdRender As System.Windows.Forms.Button
    Friend WithEvents cmdSaveSettings As System.Windows.Forms.Button
    Friend WithEvents cmdLoadSettings As System.Windows.Forms.Button
    Friend WithEvents lstSrcFiles As System.Windows.Forms.ListBox
    Friend WithEvents cmdAddSrcFile As System.Windows.Forms.Button
    Friend WithEvents vsZ1 As System.Windows.Forms.VScrollBar
    Friend WithEvents vsZ2 As System.Windows.Forms.VScrollBar
    Friend WithEvents lblZ1 As System.Windows.Forms.Label
    Friend WithEvents lblZ2 As System.Windows.Forms.Label
    Friend WithEvents cmdRenderAll As System.Windows.Forms.Button
    Friend WithEvents cbDrawBack As System.Windows.Forms.CheckBox
    Friend WithEvents cbPosOffset As System.Windows.Forms.CheckBox
    Friend WithEvents picTextured As System.Windows.Forms.PictureBox
    Friend WithEvents cmdReset As System.Windows.Forms.Button
    Friend WithEvents MenuStrip As System.Windows.Forms.MenuStrip
    Friend WithEvents EditMenuItem As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents EditSettingsMenuItem As System.Windows.Forms.ToolStripMenuItem
    Friend WithEvents cmdASE As System.Windows.Forms.Button
    <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
        Me.picGraphics = New System.Windows.Forms.PictureBox()
        Me.txtOutput = New System.Windows.Forms.TextBox()
        Me.picSample = New System.Windows.Forms.PictureBox()
        Me.picColors = New System.Windows.Forms.PictureBox()
        Me.cmdSetSample = New System.Windows.Forms.Button()
        Me.cmdRender = New System.Windows.Forms.Button()
        Me.cmdSaveSettings = New System.Windows.Forms.Button()
        Me.cmdLoadSettings = New System.Windows.Forms.Button()
        Me.lstSrcFiles = New System.Windows.Forms.ListBox()
        Me.cmdAddSrcFile = New System.Windows.Forms.Button()
        Me.vsZ1 = New System.Windows.Forms.VScrollBar()
        Me.vsZ2 = New System.Windows.Forms.VScrollBar()
        Me.lblZ1 = New System.Windows.Forms.Label()
        Me.lblZ2 = New System.Windows.Forms.Label()
        Me.cmdRenderAll = New System.Windows.Forms.Button()
        Me.cbDrawBack = New System.Windows.Forms.CheckBox()
        Me.cbPosOffset = New System.Windows.Forms.CheckBox()
        Me.picTextured = New System.Windows.Forms.PictureBox()
        Me.cmdReset = New System.Windows.Forms.Button()
        Me.cmdASE = New System.Windows.Forms.Button()
        Me.MenuStrip = New System.Windows.Forms.MenuStrip()
        Me.EditMenuItem = New System.Windows.Forms.ToolStripMenuItem()
        Me.EditSettingsMenuItem = New System.Windows.Forms.ToolStripMenuItem()
        CType(Me.picGraphics, System.ComponentModel.ISupportInitialize).BeginInit()
        CType(Me.picSample, System.ComponentModel.ISupportInitialize).BeginInit()
        CType(Me.picColors, System.ComponentModel.ISupportInitialize).BeginInit()
        CType(Me.picTextured, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.MenuStrip.SuspendLayout()
        Me.SuspendLayout()
        '
        'picGraphics
        '
        Me.picGraphics.BackColor = System.Drawing.Color.Black
        Me.picGraphics.Location = New System.Drawing.Point(12, 27)
        Me.picGraphics.Name = "picGraphics"
        Me.picGraphics.Size = New System.Drawing.Size(270, 208)
        Me.picGraphics.TabIndex = 18
        Me.picGraphics.TabStop = False
        '
        'txtOutput
        '
        Me.txtOutput.Location = New System.Drawing.Point(12, 475)
        Me.txtOutput.Multiline = True
        Me.txtOutput.Name = "txtOutput"
        Me.txtOutput.Size = New System.Drawing.Size(270, 64)
        Me.txtOutput.TabIndex = 19
        '
        'picSample
        '
        Me.picSample.BackColor = System.Drawing.Color.Black
        Me.picSample.Location = New System.Drawing.Point(475, 27)
        Me.picSample.Name = "picSample"
        Me.picSample.Size = New System.Drawing.Size(169, 168)
        Me.picSample.TabIndex = 20
        Me.picSample.TabStop = False
        '
        'picColors
        '
        Me.picColors.BackColor = System.Drawing.Color.Black
        Me.picColors.Location = New System.Drawing.Point(288, 27)
        Me.picColors.Name = "picColors"
        Me.picColors.Size = New System.Drawing.Size(140, 512)
        Me.picColors.TabIndex = 21
        Me.picColors.TabStop = False
        '
        'cmdSetSample
        '
        Me.cmdSetSample.Location = New System.Drawing.Point(475, 203)
        Me.cmdSetSample.Name = "cmdSetSample"
        Me.cmdSetSample.Size = New System.Drawing.Size(169, 24)
        Me.cmdSetSample.TabIndex = 22
        Me.cmdSetSample.Text = "Set Sample"
        '
        'cmdRender
        '
        Me.cmdRender.Location = New System.Drawing.Point(12, 449)
        Me.cmdRender.Name = "cmdRender"
        Me.cmdRender.Size = New System.Drawing.Size(76, 20)
        Me.cmdRender.TabIndex = 23
        Me.cmdRender.Text = "Render"
        '
        'cmdSaveSettings
        '
        Me.cmdSaveSettings.Location = New System.Drawing.Point(475, 235)
        Me.cmdSaveSettings.Name = "cmdSaveSettings"
        Me.cmdSaveSettings.Size = New System.Drawing.Size(169, 24)
        Me.cmdSaveSettings.TabIndex = 24
        Me.cmdSaveSettings.Text = "Save Settings"
        '
        'cmdLoadSettings
        '
        Me.cmdLoadSettings.Location = New System.Drawing.Point(475, 267)
        Me.cmdLoadSettings.Name = "cmdLoadSettings"
        Me.cmdLoadSettings.Size = New System.Drawing.Size(169, 24)
        Me.cmdLoadSettings.TabIndex = 25
        Me.cmdLoadSettings.Text = "Load Settings"
        '
        'lstSrcFiles
        '
        Me.lstSrcFiles.Location = New System.Drawing.Point(475, 299)
        Me.lstSrcFiles.Name = "lstSrcFiles"
        Me.lstSrcFiles.Size = New System.Drawing.Size(169, 186)
        Me.lstSrcFiles.TabIndex = 26
        '
        'cmdAddSrcFile
        '
        Me.cmdAddSrcFile.Location = New System.Drawing.Point(434, 491)
        Me.cmdAddSrcFile.Name = "cmdAddSrcFile"
        Me.cmdAddSrcFile.Size = New System.Drawing.Size(116, 20)
        Me.cmdAddSrcFile.TabIndex = 27
        Me.cmdAddSrcFile.Text = "Add File"
        '
        'vsZ1
        '
        Me.vsZ1.LargeChange = 5
        Me.vsZ1.Location = New System.Drawing.Point(432, 27)
        Me.vsZ1.Maximum = 50
        Me.vsZ1.Name = "vsZ1"
        Me.vsZ1.Size = New System.Drawing.Size(16, 220)
        Me.vsZ1.TabIndex = 28
        '
        'vsZ2
        '
        Me.vsZ2.LargeChange = 5
        Me.vsZ2.Location = New System.Drawing.Point(456, 27)
        Me.vsZ2.Maximum = 50
        Me.vsZ2.Name = "vsZ2"
        Me.vsZ2.Size = New System.Drawing.Size(16, 220)
        Me.vsZ2.TabIndex = 29
        '
        'lblZ1
        '
        Me.lblZ1.Location = New System.Drawing.Point(432, 251)
        Me.lblZ1.Name = "lblZ1"
        Me.lblZ1.Size = New System.Drawing.Size(20, 24)
        Me.lblZ1.TabIndex = 30
        Me.lblZ1.Text = "1"
        '
        'lblZ2
        '
        Me.lblZ2.Location = New System.Drawing.Point(456, 251)
        Me.lblZ2.Name = "lblZ2"
        Me.lblZ2.Size = New System.Drawing.Size(20, 24)
        Me.lblZ2.TabIndex = 31
        Me.lblZ2.Text = "2"
        '
        'cmdRenderAll
        '
        Me.cmdRenderAll.Location = New System.Drawing.Point(94, 449)
        Me.cmdRenderAll.Name = "cmdRenderAll"
        Me.cmdRenderAll.Size = New System.Drawing.Size(76, 20)
        Me.cmdRenderAll.TabIndex = 32
        Me.cmdRenderAll.Text = "Render All"
        '
        'cbDrawBack
        '
        Me.cbDrawBack.Location = New System.Drawing.Point(565, 491)
        Me.cbDrawBack.Name = "cbDrawBack"
        Me.cbDrawBack.Size = New System.Drawing.Size(80, 16)
        Me.cbDrawBack.TabIndex = 33
        Me.cbDrawBack.Text = "Draw Back"
        '
        'cbPosOffset
        '
        Me.cbPosOffset.Location = New System.Drawing.Point(565, 513)
        Me.cbPosOffset.Name = "cbPosOffset"
        Me.cbPosOffset.Size = New System.Drawing.Size(80, 16)
        Me.cbPosOffset.TabIndex = 34
        Me.cbPosOffset.Text = "Pos Offset"
        '
        'picTextured
        '
        Me.picTextured.BackColor = System.Drawing.Color.Black
        Me.picTextured.Location = New System.Drawing.Point(12, 239)
        Me.picTextured.Name = "picTextured"
        Me.picTextured.Size = New System.Drawing.Size(270, 204)
        Me.picTextured.TabIndex = 35
        Me.picTextured.TabStop = False
        '
        'cmdReset
        '
        Me.cmdReset.Location = New System.Drawing.Point(202, 449)
        Me.cmdReset.Name = "cmdReset"
        Me.cmdReset.Size = New System.Drawing.Size(80, 20)
        Me.cmdReset.TabIndex = 36
        Me.cmdReset.Text = "Reset Colors"
        '
        'cmdASE
        '
        Me.cmdASE.Location = New System.Drawing.Point(434, 517)
        Me.cmdASE.Name = "cmdASE"
        Me.cmdASE.Size = New System.Drawing.Size(116, 20)
        Me.cmdASE.TabIndex = 37
        Me.cmdASE.Text = "Import ASE"
        '
        'MenuStrip
        '
        Me.MenuStrip.Items.AddRange(New System.Windows.Forms.ToolStripItem() {Me.EditMenuItem})
        Me.MenuStrip.Location = New System.Drawing.Point(0, 0)
        Me.MenuStrip.Name = "MenuStrip"
        Me.MenuStrip.Size = New System.Drawing.Size(657, 24)
        Me.MenuStrip.TabIndex = 38
        Me.MenuStrip.Text = "MenuStrip"
        '
        'EditMenuItem
        '
        Me.EditMenuItem.DropDownItems.AddRange(New System.Windows.Forms.ToolStripItem() {Me.EditSettingsMenuItem})
        Me.EditMenuItem.Name = "EditMenuItem"
        Me.EditMenuItem.Size = New System.Drawing.Size(39, 20)
        Me.EditMenuItem.Text = "&Edit"
        '
        'EditSettingsMenuItem
        '
        Me.EditSettingsMenuItem.Name = "EditSettingsMenuItem"
        Me.EditSettingsMenuItem.Size = New System.Drawing.Size(116, 22)
        Me.EditSettingsMenuItem.Text = "&Settings"
        '
        'Form1
        '
        Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
        Me.ClientSize = New System.Drawing.Size(657, 552)
        Me.Controls.Add(Me.cmdASE)
        Me.Controls.Add(Me.cmdReset)
        Me.Controls.Add(Me.picTextured)
        Me.Controls.Add(Me.cbDrawBack)
        Me.Controls.Add(Me.cbPosOffset)
        Me.Controls.Add(Me.cmdRenderAll)
        Me.Controls.Add(Me.lblZ2)
        Me.Controls.Add(Me.lblZ1)
        Me.Controls.Add(Me.vsZ2)
        Me.Controls.Add(Me.vsZ1)
        Me.Controls.Add(Me.cmdAddSrcFile)
        Me.Controls.Add(Me.lstSrcFiles)
        Me.Controls.Add(Me.cmdLoadSettings)
        Me.Controls.Add(Me.cmdSaveSettings)
        Me.Controls.Add(Me.cmdRender)
        Me.Controls.Add(Me.cmdSetSample)
        Me.Controls.Add(Me.picColors)
        Me.Controls.Add(Me.picSample)
        Me.Controls.Add(Me.txtOutput)
        Me.Controls.Add(Me.picGraphics)
        Me.Controls.Add(Me.MenuStrip)
        Me.MainMenuStrip = Me.MenuStrip
        Me.Name = "Form1"
        Me.Text = "Jumpman Graphics"
        CType(Me.picGraphics, System.ComponentModel.ISupportInitialize).EndInit()
        CType(Me.picSample, System.ComponentModel.ISupportInitialize).EndInit()
        CType(Me.picColors, System.ComponentModel.ISupportInitialize).EndInit()
        CType(Me.picTextured, System.ComponentModel.ISupportInitialize).EndInit()
        Me.MenuStrip.ResumeLayout(False)
        Me.MenuStrip.PerformLayout()
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub

#End Region

    'Private jmWidth As Single = 1.5

    'Private iBMHeight As Integer
    'Private iBMWidth As Integer

    'Private iMeshZ1 As Single
    'Private iMeshZ2 As Single

    'Private sColorMode As String

    'Sub DoImport()
    '    txtOut.Text = ""

    '    Dim bm As Bitmap
    '    Dim gr As Graphics

    '    FileOpen(1, txtFileOut.Text, OpenMode.Output, OpenAccess.Write, OpenShare.Default)

    '    bm = Bitmap.FromFile(txtFileIn.Text)
    '    gr = Me.CreateGraphics()

    '    gr.DrawImageUnscaled(bm, 10, 10)

    '    Dim iX As Long
    '    Dim iY As Long
    '    Dim bBlackU As Boolean
    '    Dim bBlackD As Boolean
    '    Dim bBlackL As Boolean
    '    Dim bBlackR As Boolean
    '    Dim bBlackC As Boolean
    '    Dim iTX As Single
    '    Dim iTY As Single

    '    iBMHeight = bm.Height
    '    iBMWidth = bm.Width

    '    For iX = 1 To bm.Width - 2
    '        For iY = 0 To bm.Height - 2

    '            bBlackC = IsBlack(bm, iX, iY)
    '            If Not bBlackC And Not IsBehind(bm, iX, iY) Then
    '                bBlackL = IsBlack(bm, iX - 1, iY) Or IsBehind(bm, iX - 1, iY)
    '                bBlackR = IsBlack(bm, iX + 1, iY) Or IsBehind(bm, iX + 1, iY)
    '                bBlackU = IsBlack(bm, iX, iY - 1) Or IsBehind(bm, iX, iY - 1)
    '                bBlackD = IsBlack(bm, iX, iY + 1) Or IsBehind(bm, iX, iY + 1)
    '            Else
    '                bBlackL = IsBlack(bm, iX - 1, iY)
    '                bBlackR = IsBlack(bm, iX + 1, iY)
    '                bBlackU = IsBlack(bm, iX, iY - 1)
    '                bBlackD = IsBlack(bm, iX, iY + 1)
    '            End If

    '            GetTexturePosition(bm.GetPixel(iX, iY).R, bm.GetPixel(iX, iY).G, bm.GetPixel(iX, iY).B, iTX, iTY)

    '            If Not bBlackC Then
    '                If bBlackL Then AddZSquare(iX + 0, iY + 1, iX + 0, iY + 0, iTX, iTY, iMeshZ1, iMeshZ2)
    '                If bBlackR Then AddZSquare(iX + 1, iY + 0, iX + 1, iY + 1, iTX, iTY, iMeshZ1, iMeshZ2)
    '                If bBlackU Then AddZSquare(iX + 0, iY + 0, iX + 1, iY + 0, iTX, iTY, iMeshZ1, iMeshZ2)
    '                If bBlackD Then AddZSquare(iX + 1, iY + 1, iX + 0, iY + 1, iTX, iTY, iMeshZ1, iMeshZ2)
    '                AddPSquare(iX, iY, iX + 1, iY + 1, iTX, iTY, iMeshZ1)
    '                AddBSquare(iX, iY, iX + 1, iY + 1, iTX, iTY, iMeshZ2)
    '            End If
    '        Next
    '    Next

    '    txtOut.Text = "Done"

    '    FileClose(1)
    'End Sub

    'Private Function IsBehind(ByVal bm As Bitmap, ByVal iX As Integer, ByVal iY As Integer) As Boolean
    '    Dim iTX As Single, iTY As Single
    '    If iY < 0 Or iX < 0 Then
    '        IsBehind = False
    '    ElseIf IsBlack(bm, iX, iY) Then
    '        IsBehind = True
    '    Else
    '        GetTexturePosition(bm.GetPixel(iX, iY).R, bm.GetPixel(iX, iY).G, bm.GetPixel(iX, iY).B, iTX, iTY)
    '        If iMeshZ1 <> 0 Then IsBehind = True
    '    End If
    'End Function

    'Private Sub GetTexturePosition(ByVal r As Single, ByVal g As Single, ByVal b As Single, ByRef tx As Single, ByRef ty As Single)
    '    iMeshZ1 = 0
    '    iMeshZ2 = jmWidth

    '    If sColorMode = "dinosaur" Then
    '        iMeshZ1 = 0
    '        iMeshZ2 = 2
    '        If r = 0 And g = 0 And b = 0 Then
    '            tx = 0
    '            ty = 0
    '        ElseIf r = 69 And g = 180 And b = 50 Then
    '            tx = 0.5
    '            ty = 0
    '        ElseIf r = 255 And g = 255 And b = 255 Then
    '            tx = 0.5
    '            ty = 0.5
    '        ElseIf r = 128 And g = 128 And b = 128 Then
    '            tx = 0
    '            ty = 0.5
    '            iMeshZ1 = 1.5
    '            iMeshZ2 = 3
    '        ElseIf r = 0 And g = 128 And b = 0 Then
    '            tx = 0.0
    '            ty = 0.0
    '        Else
    '            Stop
    '        End If

    '        Exit Sub
    '    End If

    '    If sColorMode = "ghost" Then
    '        iMeshZ1 = jmWidth * 0.5
    '        iMeshZ2 = jmWidth * 1.5
    '        If r = 0 And g = 0 And b = 0 Then
    '            tx = 0
    '            ty = 0
    '        ElseIf r = 255 And g = 255 And b = 255 Then  'white
    '            tx = 0.51
    '            ty = 0
    '        ElseIf r = 128 And g = 128 And b = 128 Then  'Dark gray
    '            tx = 0
    '            ty = 0
    '        ElseIf r = 192 And g = 192 And b = 192 Then  'Light gray
    '            tx = 0
    '            ty = 0
    '        ElseIf r = 0 And g = 224 And b = 128 Then  'eye green
    '            tx = 0
    '            ty = 0.51
    '        ElseIf r = 0 And g = 255 And b = 0 Then  'eye green
    '            iMeshZ1 = jmWidth * 0
    '            iMeshZ2 = jmWidth * 1.5
    '            tx = 0
    '            ty = 0.51
    '        Else
    '            Stop
    '        End If
    '        Exit Sub
    '    End If

    '    If sColorMode = "penguin" Then
    '        If r = 0 And g = 0 And b = 0 Then
    '            tx = 0
    '            ty = 0
    '        ElseIf r = 255 And g = 255 And b = 255 Then  'white
    '            tx = 0.51
    '            ty = 0
    '        ElseIf r = 128 And g = 128 And b = 128 Then  'Dark gray
    '            tx = 0
    '            ty = 0
    '        ElseIf r = 198 And g = 207 And b = 22 Then  'custom yellow
    '            tx = 0.51
    '            ty = 0.51
    '        ElseIf r = 0 And g = 0 And b = 255 Then  'blue
    '            tx = 0
    '            ty = 0.51
    '        Else
    '            Stop
    '        End If
    '    ElseIf sColorMode = "ninja" Then
    '        If r = 0 And g = 0 And b = 0 Then
    '            tx = 0
    '            ty = 0
    '        ElseIf r = 128 And g = 128 And b = 128 Then  'Dark gray
    '            tx = 0
    '            ty = 0
    '        ElseIf r = 192 And g = 192 And b = 192 Then  'Light gray
    '            tx = 0.51
    '            ty = 0
    '        ElseIf r = 255 And g = 255 And b = 255 Then  'white
    '            tx = 0.51
    '            ty = 0.51
    '        Else
    '            Stop
    '        End If
    '    ElseIf r = 0 And g = 0 And b = 0 Then
    '        tx = 0
    '        ty = 0
    '    ElseIf r = 0 And g = 0 And b = 1 Then
    '        tx = 0
    '        ty = 0
    '    ElseIf r = 255 And g = 0 And b = 0 Then
    '        tx = 0.51
    '        ty = 0.51
    '    ElseIf r = 255 And g = 255 And b = 255 Then
    '        tx = 0.01
    '        ty = 0.01
    '    ElseIf r = 0 And g = 128 And b = 192 Then
    '        tx = 0.51
    '        ty = 0.01
    '    ElseIf r = 0 And g = 0 And b = 255 Then
    '        tx = 0.51
    '        ty = 0.01
    '    ElseIf r = 64 And g = 0 And b = 192 Then
    '        tx = 0.51
    '        ty = 0.01
    '    ElseIf r = 0 And g = 255 And b = 255 Then
    '        tx = 0.01
    '        ty = 0.01


    '    ElseIf r = 128 And g = 64 And b = 0 Then  'Bear dark brown
    '        iMeshZ1 = 0
    '        iMeshZ2 = 4
    '        tx = 0.01
    '        ty = 0.01
    '    ElseIf r = 255 And g = 128 And b = 64 Then  'Bear light brown
    '        iMeshZ1 = 0
    '        iMeshZ2 = 4
    '        tx = 0.51
    '        ty = 0.01
    '    ElseIf r = 128 And g = 128 And b = 128 Then  'Bear dark gray
    '        iMeshZ1 = 2
    '        iMeshZ2 = 4
    '        tx = 0.01
    '        ty = 0.51
    '    ElseIf r = 192 And g = 192 And b = 192 Then  'Bear light gray
    '        iMeshZ1 = 0
    '        iMeshZ2 = 4
    '        tx = 0.01
    '        ty = 0.51

    '    ElseIf r = 0 And g = 255 And b = 0 Then  'Kremlin green
    '        tx = 0.01
    '        ty = 0.51

    '    Else
    '        Stop
    '    End If
    'End Sub

    'Private Sub AddTriangle(ByVal iX1 As Integer, ByVal iY1 As Integer, ByVal iZ1 As Integer, ByVal iX2 As Integer, ByVal iY2 As Integer, ByVal iZ2 As Integer, ByVal iX3 As Integer, ByVal iY3 As Integer, ByVal iZ3 As Integer, ByVal tX As Single, ByVal tY As Single)
    '    Dim uX As Double, uY As Double, uZ As Double
    '    Dim vX As Double, vY As Double, vZ As Double

    '    iX1 = iX1 - CLng(iBMWidth / 2)
    '    iX2 = iX2 - CLng(iBMWidth / 2)
    '    iX3 = iX3 - CLng(iBMWidth / 2)

    '    iY1 = iY1 - CLng(iBMHeight / 2) : iY1 = -iY1
    '    iY2 = iY2 - CLng(iBMHeight / 2) : iY2 = -iY2
    '    iY3 = iY3 - CLng(iBMHeight / 2) : iY3 = -iY3

    '    uX = iX2 - iX1 : uY = iY2 - iY1 : uZ = iZ2 - iZ1
    '    vX = iX3 - iX1 : vY = iY3 - iY1 : vZ = iZ3 - iZ1

    '    Dim nX As Double, nY As Double, nZ As Double

    '    nX = (uY * vZ) - (uZ * vY)
    '    nY = (uZ * vX) - (uX * vZ)
    '    nZ = (uX * vY) - (uY * vX)

    '    Dim nL As Double

    '    nL = Math.Sqrt(nX * nX + nY * nY + nZ * nZ)
    '    nX = Math.Round(nX / nL, 3)
    '    nY = Math.Round(nY / nL, 3)
    '    nZ = Math.Round(nZ / nL, 3)

    '    Dim sTX As Single, sTY As Single

    '    sTX = tX : sTY = tY

    '    Dim sAll As String

    '    sAll = sAll & iX1 & "," & iY1 & "," & iZ1 & ","
    '    sAll = sAll & nX & "," & nY & "," & nZ & ","
    '    sAll = sAll & "&HFFFFFF" & "," & sTX & "," & sTY & vbCrLf

    '    sAll = sAll & iX2 & "," & iY2 & "," & iZ2 & ","
    '    sAll = sAll & nX & "," & nY & "," & nZ & ","
    '    sAll = sAll & "&HFFFFFF" & "," & Math.Round(sTX + 0.05, 3) & "," & sTY & vbCrLf

    '    sAll = sAll & iX3 & "," & iY3 & "," & iZ3 & ","
    '    sAll = sAll & nX & "," & nY & "," & nZ & ","
    '    sAll = sAll & "&HFFFFFF" & "," & sTX & "," & Math.Round(sTY + 0.05, 3) & vbCrLf

    '    '        txtOut.Text = txtOut.Text & sAll
    '    txtOut.Text = txtOut.Text & "."

    '    Print(1, NumToString(iX1))
    '    Print(1, NumToString(iY1))
    '    Print(1, NumToString(iZ1))
    '    Print(1, NumToString(nX))
    '    Print(1, NumToString(nY))
    '    Print(1, NumToString(nZ))
    '    Print(1, NumToString(100))

    '    sTX = iX1 + iBMWidth / 2
    '    sTX = tX + sTX / iBMWidth / 2
    '    sTY = iY1 + iBMHeight / 2
    '    sTY = tY + sTY / iBMHeight / 2

    '    Print(1, NumToString(sTX))
    '    Print(1, NumToString(sTY))

    '    Print(1, NumToString(iX2))
    '    Print(1, NumToString(iY2))
    '    Print(1, NumToString(iZ2))
    '    Print(1, NumToString(nX))
    '    Print(1, NumToString(nY))
    '    Print(1, NumToString(nZ))
    '    Print(1, NumToString(100))

    '    sTX = iX2 + iBMWidth / 2
    '    sTX = tX + sTX / iBMWidth / 2
    '    sTY = iY2 + iBMHeight / 2
    '    sTY = tY + sTY / iBMHeight / 2

    '    Print(1, NumToString(sTX))
    '    Print(1, NumToString(sTY))

    '    Print(1, NumToString(iX3))
    '    Print(1, NumToString(iY3))
    '    Print(1, NumToString(iZ3))
    '    Print(1, NumToString(nX))
    '    Print(1, NumToString(nY))
    '    Print(1, NumToString(nZ))
    '    Print(1, NumToString(100))

    '    sTX = iX3 + iBMWidth / 2
    '    sTX = tX + sTX / iBMWidth / 2
    '    sTY = iY3 + iBMHeight / 2
    '    sTY = tY + sTY / iBMHeight / 2

    '    Print(1, NumToString(sTX))
    '    Print(1, NumToString(sTY))

    'End Sub

    'Private Function NumToString(ByVal sNum As Single, Optional ByVal iRep As Integer = 4) As String
    '    If iRep = 4 Then
    '        NumToString = IIf(sNum < 0, Chr(1), Chr(0))
    '        sNum = Math.Abs(sNum)
    '    End If

    '    Dim iTest As Integer
    '    iTest = Math.Floor(sNum)
    '    NumToString = NumToString & Chr(iTest Mod 256)

    '    If iRep > 2 Then
    '        sNum = sNum - iTest
    '        sNum = sNum * 256
    '        NumToString = NumToString & NumToString(sNum, iRep - 1)
    '    End If
    'End Function

    'Private Sub AddBSquare(ByVal iX1 As Integer, ByVal iY1 As Integer, ByVal iX2 As Integer, ByVal iY2 As Integer, ByVal iTX As Single, ByVal iTY As Single, ByVal iZ As Integer)
    '    AddTriangle(iX2, iY1, iZ, iX1, iY1, iZ, iX1, iY2, iZ, iTX, iTY)
    '    AddTriangle(iX1, iY2, iZ, iX2, iY2, iZ, iX2, iY1, iZ, iTX, iTY)
    'End Sub

    'Private Sub AddPSquare(ByVal iX1 As Integer, ByVal iY1 As Integer, ByVal iX2 As Integer, ByVal iY2 As Integer, ByVal iTX As Single, ByVal iTY As Single, ByVal iZ As Integer)
    '    AddTriangle(iX1, iY1, iZ, iX2, iY1, iZ, iX1, iY2, iZ, iTX, iTY)
    '    AddTriangle(iX2, iY2, iZ, iX1, iY2, iZ, iX2, iY1, iZ, iTX, iTY)
    'End Sub

    'Private Sub AddZSquare(ByVal iX1 As Integer, ByVal iY1 As Integer, ByVal iX2 As Integer, ByVal iY2 As Integer, ByVal iTX As Single, ByVal iTY As Single, ByVal iZ1 As Single, ByVal iZ2 As Single)
    '    AddTriangle(iX1, iY1, iZ2, iX2, iY2, iZ2, iX1, iY1, iZ1, iTX, iTY)
    '    AddTriangle(iX2, iY2, iZ1, iX1, iY1, iZ1, iX2, iY2, iZ2, iTX, iTY)
    'End Sub

    'Private Function IsBlack(ByVal bm As Bitmap, ByVal iX As Integer, ByVal iY As Integer) As Boolean
    '    If iY < 0 Then
    '        IsBlack = 0
    '        Exit Function
    '    End If

    '    If bm.GetPixel(iX, iY).R = 0 And bm.GetPixel(iX, iY).G = 0 And bm.GetPixel(iX, iY).B = 0 Then
    '        IsBlack = True
    '    End If
    'End Function

    'Private Sub cmdAll_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdAll.Click
    '    '        RegImport("Stand")
    '    '        RegImport("Left1")
    '    '        RegImport("Left2")
    '    '        RegImport("Right1")
    '    '        RegImport("Right2")
    '    '        RegImport("JumpLeft")
    '    '        RegImport("JumpRight")
    '    '        RegImport("KickLeft")
    '    '        RegImport("KickRight")
    '    '        RegImport("JumpUp")
    '    '        RegImport("LadderClimb1")
    '    '        RegImport("LadderClimb2")
    '    '        RegImport("RopeClimb1")
    '    '        RegImport("RopeClimb2")

    '    '        RegImport("DiveRight")
    '    '        RegImport("RollRight1")
    '    '        RegImport("RollRight2")
    '    '        RegImport("RollRight3")
    '    '        RegImport("RollRight4")
    '    '
    '    '        RegImport("DiveLeft")
    '    '        RegImport("RollLeft1")
    '    '        RegImport("RollLeft2")
    '    '        RegImport("RollLeft3")
    '    '        RegImport("RollLeft4")
    '    '
    '    '       RegImport("PunchRight")
    '    '       RegImport("PunchRight2")
    '    '       RegImport("PunchLeft")
    '    '       RegImport("PunchLeft2")

    '    '        RegImport("Dead")

    '    RegImport("Slider")
    '    RegImport("SliderB")
    '    RegImport("SlideL")
    '    RegImport("SlideLB")

    'End Sub

    'Private Sub RegImport(ByVal sFile As String)
    '    txtFileIn.Text = Path.Combine(My.Settings.SourceDirectory, sFile & ".BMP")
    '    txtFileOut.Text = Path.Combine(My.Settings.OutputDirectory, sFile & ".MSH")
    '    DoImport()
    'End Sub

    'Private Sub LoadMap()
    '    Dim sLine As String
    '    Dim sAll As String
    '    FileOpen(1, Path.Combine(My.Settings.SourceDirectory, "Jumpman.map"), OpenMode.Input, OpenAccess.Default)
    '    While Not EOF(1)
    '        Input(1, sLine)
    '        sAll = sAll & sLine & vbCrLf
    '    End While

    '    txtMappings.Text = sAll
    '    FileClose(1)
    'End Sub

    'Private Function TextReplace(ByVal sText As String, ByVal sReplace As String, ByVal sWith As String) As String
    '    While InStr(sText, sReplace) <> 0
    '        TextReplace = TextReplace & Mid(sText, 1, InStr(sText, sReplace) - 1) & sWith
    '        sText = Mid(sText, InStr(sText, sReplace) + Len(sReplace))
    '    End While
    '    TextReplace = TextReplace & sText
    'End Function


    'Private Sub cmdBackground_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdBackground.Click
    '    Dim sAll As String

    '    Dim iX1 As Single, iY1 As Single, iX2 As Single, iY2 As Single, iZ As Single
    '    Dim iTX1 As Single, iTX2 As Single, iTY1 As Single, iTY2 As Single

    '    FileOpen(1, Path.Combine(My.Settings.OutputDirectory, "BG.msh"), OpenMode.Output)
    '    iX1 = -100 : iY1 = 200 : iX2 = 255 : iY2 = -140 : iZ = 80
    '    AddFullTriangle(iX1, iY1, iZ, iX2, iY1, iZ, iX1, iY2, iZ, 0, 0, 1, 0, 0, 1)
    '    AddFullTriangle(iX2, iY1, iZ, iX2, iY2, iZ, iX1, iY2, iZ, 1, 0, 1, 1, 0, 1)
    '    FileClose(1)


    '    FileOpen(1, Path.Combine(My.Settings.OutputDirectory, "Wave.msh"), OpenMode.Output)
    '    iX1 = -60 : iY1 = 10 : iX2 = 220 : iY2 = -10 : iZ = 0
    '    iTX1 = 0.01 : iTX2 = 41.99
    '    iTY1 = 0.03 : iTY2 = 0.99
    '    AddFullTriangle(iX1, iY1, iZ, iX2, iY1, iZ, iX1, iY2, iZ, iTX1, iTY1, iTX2, iTY1, iTX1, iTY2)
    '    AddFullTriangle(iX2, iY1, iZ, iX2, iY2, iZ, iX1, iY2, iZ, iTX2, iTY1, iTX2, iTY2, iTX1, iTY2)
    '    FileClose(1)

    '    FileOpen(1, Path.Combine(My.Settings.OutputDirectory, "Sea.msh"), OpenMode.Output)
    '    iX1 = -60 : iY1 = -5 : iX2 = 220 : iY2 = -135 : iZ = 0
    '    iTX1 = 0.1 : iTX2 = 0.9
    '    iTY1 = 0.1 : iTY2 = 0.9
    '    AddFullTriangle(iX1, iY1, iZ, iX2, iY1, iZ, iX1, iY2, iZ, iTX1, iTY1, iTX2, iTY1, iTX1, iTY2)
    '    AddFullTriangle(iX2, iY1, iZ, iX2, iY2, iZ, iX1, iY2, iZ, iTX2, iTY1, iTX2, iTY2, iTX1, iTY2)
    '    FileClose(1)

    '    FileOpen(1, Path.Combine(My.Settings.OutputDirectory, "Drop.msh"), OpenMode.Output)
    '    iX1 = -7 : iY1 = 7 : iX2 = 7 : iY2 = -7 : iZ = 0
    '    iTX1 = 0.1 : iTX2 = 1
    '    iTY1 = 0.1 : iTY2 = 1
    '    AddFullTriangle(iX1, iY1, iZ, iX2, iY1, iZ, iX1, iY2, iZ, iTX1, iTY1, iTX2, iTY1, iTX1, iTY2)
    '    AddFullTriangle(iX2, iY1, iZ, iX2, iY2, iZ, iX1, iY2, iZ, iTX2, iTY1, iTX2, iTY2, iTX1, iTY2)
    '    FileClose(1)

    'End Sub


    'Private Sub cmdImpFy_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdImpFy.Click
    '    sColorMode = "bear"
    '    '        RegImport("FyStand")
    '    '        RegImport("FyRight1")
    '    '        RegImport("FyRight2")
    '    '        RegImport("FyFR1")
    '    '        RegImport("FyFR2")
    '    '        RegImport("FYFlopR")
    '    '        RegImport("FYSR1")
    '    '        RegImport("FYSR2")

    '    '       RegImport("FyStandL")
    '    '       RegImport("FyLeft1")
    '    '       RegImport("FyLeft2")
    '    '       RegImport("FyFL1")
    '    '       RegImport("FyFL2")
    '    '       RegImport("FYFlopL")
    '    '       RegImport("FYSL1")
    '    '       RegImport("FYSL2")

    '    RegImport("FYLC1")
    '    RegImport("FYLC2")

    'End Sub

    'Private Sub Button1_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)

    'End Sub

    'Private Sub Button2_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Button2.Click
    '    sColorMode = "ninja"
    '    RegImport("njRight1")
    '    RegImport("njRight2")
    '    RegImport("njKR")
    '    RegImport("njJR")
    '    RegImport("njRR1")
    '    RegImport("njRR2")
    '    RegImport("njRR3")
    '    RegImport("njRR4")
    '    RegImport("njLeft1")
    '    RegImport("njLeft2")
    '    RegImport("njKL")
    '    RegImport("njJL")
    '    RegImport("njRL1")
    '    RegImport("njRL2")
    '    RegImport("njRL3")
    '    RegImport("njRL4")
    '    RegImport("njDead")
    '    RegImport("njW1")
    '    RegImport("njW2")
    'End Sub

    'Private Sub Button3_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Button3.Click
    '    sColorMode = "penguin"
    '    RegImport("PenguinLeft1")
    '    RegImport("PenguinLeft2")
    '    RegImport("PenguinRight1")
    '    RegImport("PenguinRight2")
    '    RegImport("PenguinStand")
    '    RegImport("PenguinBack")
    '    RegImport("PenguinLC1")
    '    RegImport("PenguinLC2")
    'End Sub

    'Private Sub cmdGhost_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdGhost.Click
    '    sColorMode = "ghost"
    '    RegImport("GhostLeft")
    '    RegImport("GhostRight")
    '    RegImport("GhostLeft2")
    '    RegImport("GhostRight2")
    'End Sub

    'Private Sub cmdTSaur_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdTSaur.Click
    '    sColorMode = "dinosaur"
    '    RegImport("tSaurStandL")
    '    RegImport("tSaurWalkL1")
    '    RegImport("tSaurWalkL2")
    '    RegImport("tSaurWalkL3")
    '    RegImport("tSaurWalkL4")

    '    RegImport("tSaurYL1")
    '    RegImport("tSaurYL2")
    '    RegImport("tSaurYL3")
    '    RegImport("tSaurYL4")
    'End Sub

    Private sCurFile As String
    Private iSrcFiles As Long
    Private sSrcFile(50) As String
    Private bSrcBack(50) As Boolean
    Private bSrcOffset(50) As Boolean

    Private iWidth As Integer
    Private iHeight As Integer
    Private iColor(50, 50) As Integer

    Private iDefinedColors As Integer
    Private iDefinedColor(30) As Color
    Private iColT(30) As Single
    Private iColL(30) As Single
    Private iColW(30) As Single
    Private iColH(30) As Single
    Private iColZ1(30) As Single
    Private iColZ2(30) As Single

    Private sSampleFile As String
    Private bSampleBitmap As Bitmap

    Private iSelectedColor As Integer

    Private Function GetColorNumber(ByVal cCol As Color) As Long
        If cCol.R = 0 And cCol.G = 0 And cCol.B = 0 Then
            GetColorNumber = 0
            Exit Function
        End If

        Dim iLoop As Integer
        For iLoop = 1 To iDefinedColors
            If iDefinedColor(iLoop).R = cCol.R And iDefinedColor(iLoop).G = cCol.G And iDefinedColor(iLoop).B = cCol.B Then
                GetColorNumber = iLoop
                Exit Function
            End If
        Next

        iDefinedColors = iDefinedColors + 1
        iDefinedColor(iDefinedColors) = cCol
        GetColorNumber = iDefinedColors

    End Function

    Private Sub ShowColorList(ByVal g As Graphics)
        Dim iLoop As Long
        Dim b As SolidBrush
        Dim rSrc As System.Drawing.Rectangle
        Dim rDest As System.Drawing.Rectangle
        Dim iSize As Long
        Dim iStartY As Long

        iSize = 50

        g.Clear(Color.Black)

        If iSelectedColor > 0 Then
            b = New SolidBrush(Color.LightSeaGreen)
            g.FillRectangle(b, 0, (iSize + 10) * (iSelectedColor - 1), picColors.Width, iSize + 10)
            vsZ1.Value = iColZ1(iSelectedColor) * 10
            lblZ1.Text = iColZ1(iSelectedColor)
            vsZ2.Value = iColZ2(iSelectedColor) * 10
            lblZ2.Text = iColZ2(iSelectedColor)
        End If

        For iLoop = 1 To iDefinedColors
            b = New SolidBrush(iDefinedColor(iLoop))
            iStartY = (iSize + 10) * (iLoop - 1)
            g.FillRectangle(b, 5, 5 + iStartY, iSize, iSize)

            If Not (bSampleBitmap Is Nothing) Then
                rSrc = Rectangle.FromLTRB(iColL(iLoop) * bSampleBitmap.Width, iColT(iLoop) * bSampleBitmap.Height, (iColW(iLoop) + iColL(iLoop)) * bSampleBitmap.Width, (iColH(iLoop) + iColT(iLoop)) * bSampleBitmap.Height)
                rDest = Rectangle.FromLTRB(iSize + 25, 5 + iStartY, iSize + 25 + iSize, 5 + iStartY + iSize)
                g.DrawImage(bSampleBitmap, rDest, rSrc, GraphicsUnit.Pixel)
            End If
        Next

    End Sub

    Private Sub ResetColors()
        iDefinedColors = 0
        iSelectedColor = 0
        Dim iLoop As Long
        For iLoop = 0 To 30
            iColT(iLoop) = 0
            iColL(iLoop) = 0
            iColW(iLoop) = 1
            iColH(iLoop) = 1
            iColZ1(iLoop) = 0
            iColZ2(iLoop) = 2
        Next
    End Sub

    Private Sub LoadBitmap(ByVal sBMP As String)
        Dim bm As Bitmap

        sCurFile = sBMP

        bm = Bitmap.FromFile(Path.Combine(My.Settings.SourceDirectory, sBMP & ".BMP"))
        iWidth = bm.Width
        iHeight = bm.Height

        Dim iX As Long
        Dim iY As Long
        Dim Col As Drawing.Color

        For iX = 0 To iWidth - 1
            For iY = 0 To iHeight - 1
                Col = bm.GetPixel(iX, iY)
                iColor(iX + 1, iY + 1) = GetColorNumber(Col)
            Next
        Next

        DrawSrcObject(picGraphics.CreateGraphics())

    End Sub

    Private Sub DrawSrcObject(ByVal gr As Graphics)
        Dim iX As Long
        Dim iY As Long
        Dim b As SolidBrush
        Dim iScale As Long
        Dim Col As Color

        iScale = 7

        gr.Clear(Color.Black)

        For iX = 0 To iWidth - 1
            For iY = 0 To iHeight - 1
                Col = iDefinedColor(iColor(iX + 1, iY + 1))
                b = New SolidBrush(Col)
                gr.FillRectangle(b, iX * iScale, iY * iScale, iScale, iScale)
            Next
        Next

    End Sub

    Private Sub DrawTexturedObject(ByVal gr As Graphics)
        Dim iX As Long
        Dim iY As Long
        Dim b As SolidBrush
        Dim iScale As Long
        Dim iCurCol As Long

        Dim iStartU As Single, iEndU As Single
        Dim iStartV As Single, iEndV As Single

        Dim rSrc As Rectangle, rDest As Rectangle

        If bSampleBitmap Is Nothing Then Exit Sub

        iScale = 7

        gr.Clear(Color.Black)

        For iX = 0 To iWidth - 1
            For iY = 0 To iHeight - 1
                iCurCol = iColor(iX + 1, iY + 1)

                iStartU = (iX) * (iColW(iCurCol) / iWidth)
                iStartV = (iY) * (iColH(iCurCol) / iHeight)
                iEndU = (iX + 1) * (iColW(iCurCol) / iWidth)
                iEndV = (iY + 1) * (iColH(iCurCol) / iHeight)

                iStartU = iStartU + iColL(iCurCol)
                iStartV = iStartV + iColT(iCurCol)
                iEndU = iEndU + iColL(iCurCol)
                iEndV = iEndV + iColT(iCurCol)

                iStartU = iStartU * bSampleBitmap.Width
                iEndU = iEndU * bSampleBitmap.Width
                iStartV = iStartV * bSampleBitmap.Height
                iEndV = iEndV * bSampleBitmap.Height

                If iCurCol <> 0 Then
                    rSrc = Rectangle.FromLTRB(iStartU, iStartV, iEndU, iEndV)
                    rDest = Rectangle.FromLTRB(iX * iScale, iY * iScale, iX * iScale + iScale, iY * iScale + iScale)
                    gr.DrawImage(bSampleBitmap, rDest, rSrc, GraphicsUnit.Pixel)
                Else
                    b = New SolidBrush(Color.Black)
                    gr.FillRectangle(b, iX * iScale, iY * iScale, iScale, iScale)
                End If
            Next
        Next

    End Sub

    Private Sub RenderObject(drawBack As Boolean, doOffset As Boolean)
        FileOpen(1, Path.Combine(My.Settings.OutputDirectory, sCurFile & ".msh"), OpenMode.Output, OpenAccess.Default)
        Dim iCol As Long
        Dim iCurCol As Long
        Dim iCount As Long
        Dim iTriangleCount As Long
        Dim iX As Long
        Dim iY As Long
        Dim iStartX As Single, iEndX As Single, iShiftX As Single
        Dim iStartY As Single, iEndY As Single, iShiftY As Single
        Dim iStartU As Single, iEndU As Single
        Dim iStartV As Single, iEndV As Single
        Dim iZ1 As Single, iZ2 As Single

        iShiftX = iWidth / 2
        iShiftY = iHeight / 2 + 1

        iCount = 0
        iTriangleCount = 0

        For iY = 1 To iHeight
            iCurCol = 0

            For iX = 1 To iWidth
                iCol = iColor(iX, iY)

                If iCurCol <> iCol Then
                    If iCurCol <> 0 Then
                        If doOffset Then
                            iStartX = iX - iCount - iShiftX - 0.01
                            iStartY = iY - iShiftY - 0.01
                        Else
                            iStartX = iX - iCount - iShiftX
                            iStartY = iY - iShiftY
                        End If

                        iEndX = iX - iShiftX
                        iEndY = iY + 1 - iShiftY

                        iStartU = (iStartX + iShiftX) * (iColW(iCurCol) / iWidth)
                        iStartV = (iStartY + iShiftY) * (iColH(iCurCol) / iHeight)
                        iEndU = (iEndX + iShiftX) * (iColW(iCurCol) / iWidth)
                        iEndV = (iEndY + iShiftY) * (iColH(iCurCol) / iHeight)
                        iStartU = iStartU + iColL(iCurCol)
                        iStartV = iStartV + iColT(iCurCol)
                        iEndU = iEndU + iColL(iCurCol)
                        iEndV = iEndV + iColT(iCurCol)

                        iZ1 = iColZ1(iCurCol)
                        iZ2 = iColZ2(iCurCol)
                        AddFullTriangle(iTriangleCount, iStartX, 0 - iStartY, iZ1, iEndX, 0 - iStartY, iZ1, iStartX, 0 - iEndY, iZ1, iStartU, iStartV, iEndU, iStartV, iStartU, iEndV)
                        AddFullTriangle(iTriangleCount, iEndX, 0 - iStartY, iZ1, iEndX, 0 - iEndY, iZ1, iStartX, 0 - iEndY, iZ1, iEndU, iStartV, iEndU, iEndV, iStartU, iEndV)

                        If drawBack Then
                            AddFullTriangle(iTriangleCount, iEndX, 0 - iStartY, iZ2, iStartX, 0 - iStartY, iZ2, iEndX, 0 - iEndY, iZ2, iEndU, iStartV, iStartU, iStartV, iEndU, iEndV)
                            AddFullTriangle(iTriangleCount, iStartX, 0 - iStartY, iZ2, iStartX, 0 - iEndY, iZ2, iEndX, 0 - iEndY, iZ2, iStartU, iStartV, iStartU, iEndV, iEndU, iEndV)
                        End If
                    End If

                    iCurCol = iCol
                    iCount = 1
                Else
                    iCount = iCount + 1
                End If
            Next
        Next

        RenderObjectSide(iTriangleCount, -1, 0, 0, 0, 0, 1)
        RenderObjectSide(iTriangleCount, 1, 0, 1, 1, 0, 1)
        RenderObjectSide(iTriangleCount, 0, -1, 0, 1, 0, 0)
        RenderObjectSide(iTriangleCount, 0, 1, 0, 1, 1, 1)

        txtOutput.Text = "Exported " & sCurFile & ".MSH " & Now & " Tri Count: " & iTriangleCount & vbCrLf

        FileClose(1)

    End Sub

    Private Sub RenderObjectSide(ByRef iTriangleCount As Long, ByVal iXV As Long, ByVal iYV As Long, ByVal iPX1 As Long, ByVal iPX2 As Long, ByVal iPY1 As Long, ByVal iPY2 As Long)
        Dim iD1 As Long, iD2 As Long, iD1Max As Long, iD2Max As Long
        Dim iX As Long
        Dim iY As Long

        Dim iStartX As Single, iEndX As Single, iShiftX As Single
        Dim iStartY As Single, iEndY As Single, iShiftY As Single
        Dim iStartU As Single, iEndU As Single
        Dim iStartV As Single, iEndV As Single
        iShiftX = iWidth / 2
        iShiftY = iHeight / 2 + 1

        Dim iForeCol As Long
        Dim iBackCol As Long

        If iXV = 0 Then
            'Going left to right
            iD2Max = iHeight
            iD1Max = iWidth
        Else
            'Going top to bottom
            iD1Max = iHeight
            iD2Max = iWidth
        End If

        For iD1 = 1 To iD1Max - 1
            For iD2 = 1 To iD2Max - 1
                If iXV = 0 Then
                    iX = iD1
                    iY = iD2
                Else
                    iX = iD2
                    iY = iD1
                End If

                iForeCol = iColor(iX, iY)
                iBackCol = iColor(iX + iXV, iY + iYV)

                If iForeCol <> 0 Then
                    Dim iZ1 As Single
                    Dim iZ2 As Single

                    iZ1 = iColZ1(iForeCol)
                    If iBackCol <> 0 Then
                        iZ2 = iColZ1(iBackCol)
                    Else
                        iZ2 = iColZ2(iForeCol)
                    End If

                    If iZ1 < iZ2 Then

                        iStartX = iX + iPX1 - iShiftX
                        iStartY = iY + iPY1 - iShiftY
                        iEndX = iX + iPX2 - iShiftX
                        iEndY = iY + iPY2 - iShiftY

                        iStartU = (iStartX + iShiftX) * (iColW(iForeCol) / (iWidth + 3))
                        iStartV = (iStartY + iShiftY) * (iColH(iForeCol) / (iHeight + 3))
                        If iXV = 0 Then
                            iEndU = (iEndX + iShiftX) * (iColW(iForeCol) / (iWidth + 3))
                            iEndV = (iZ2 - iZ1 + iEndY + iShiftY) * (iColH(iForeCol) / (iHeight + 3))
                        Else
                            iEndU = (iZ2 - iZ1 + iEndX + iShiftX) * (iColW(iForeCol) / (iWidth + 3))
                            iEndV = (iEndY + iShiftY) * (iColH(iForeCol) / (iHeight + 3))
                        End If
                        iStartU = iStartU + iColL(iForeCol)
                        iStartV = iStartV + iColT(iForeCol)
                        iEndU = iEndU + iColL(iForeCol)
                        iEndV = iEndV + iColT(iForeCol)

                        If iYV = -1 And iXV = 0 Then
                            AddFullTriangle(iTriangleCount, iStartX, 0 - iStartY, iZ1, iStartX, 0 - iStartY, iZ2, iEndX, 0 - iEndY, iZ1, iStartU, iStartV, iEndU, iStartV, iStartU, iEndV)
                            AddFullTriangle(iTriangleCount, iStartX, 0 - iStartY, iZ2, iEndX, 0 - iEndY, iZ2, iEndX, 0 - iEndY, iZ1, iEndU, iStartV, iEndU, iEndV, iStartU, iEndV)
                        ElseIf iYV = 1 And iXV = 0 Then
                            AddFullTriangle(iTriangleCount, iEndX, 0 - iStartY, iZ1, iEndX, 0 - iStartY, iZ2, iStartX, 0 - iEndY, iZ1, iStartU, iStartV, iEndU, iStartV, iStartU, iEndV)
                            AddFullTriangle(iTriangleCount, iEndX, 0 - iStartY, iZ2, iStartX, 0 - iEndY, iZ2, iStartX, 0 - iEndY, iZ1, iEndU, iStartV, iEndU, iEndV, iStartU, iEndV)
                        ElseIf iXV = 1 And iYV = 0 Then
                            AddFullTriangle(iTriangleCount, iStartX, 0 - iStartY, iZ1, iEndX, 0 - iStartY, iZ2, iStartX, 0 - iEndY, iZ1, iStartU, iStartV, iEndU, iStartV, iStartU, iEndV)
                            AddFullTriangle(iTriangleCount, iEndX, 0 - iStartY, iZ2, iEndX, 0 - iEndY, iZ2, iStartX, 0 - iEndY, iZ1, iEndU, iStartV, iEndU, iEndV, iStartU, iEndV)
                        ElseIf iXV = -1 And iYV = 0 Then
                            AddFullTriangle(iTriangleCount, iStartX, 0 - iEndY, iZ1, iEndX, 0 - iEndY, iZ2, iStartX, 0 - iStartY, iZ1, iStartU, iEndV, iEndU, iEndV, iStartU, iStartV)
                            AddFullTriangle(iTriangleCount, iEndX, 0 - iEndY, iZ2, iEndX, 0 - iStartY, iZ2, iStartX, 0 - iStartY, iZ1, iEndU, iEndV, iEndU, iStartV, iStartU, iStartV)
                        End If
                    End If

                End If
            Next
        Next

    End Sub

    Private Sub AddFullTriangle(ByRef iTriangleCount As Long, ByVal iX1 As Double, ByVal iY1 As Double, ByVal iZ1 As Double, ByVal iX2 As Double, ByVal iY2 As Double, ByVal iZ2 As Double, ByVal iX3 As Double, ByVal iY3 As Double, ByVal iZ3 As Double, ByVal tX1 As Single, ByVal tY1 As Single, ByVal tX2 As Single, ByVal tY2 As Single, ByVal tX3 As Single, ByVal tY3 As Single)
        Dim uX As Double, uY As Double, uZ As Double
        Dim vX As Double, vY As Double, vZ As Double

        uX = iX2 - iX1 : uY = iY2 - iY1 : uZ = iZ2 - iZ1
        vX = iX3 - iX1 : vY = iY3 - iY1 : vZ = iZ3 - iZ1

        Dim nX As Double, nY As Double, nZ As Double

        nX = (uY * vZ) - (uZ * vY)
        nY = (uZ * vX) - (uX * vZ)
        nZ = (uX * vY) - (uY * vX)

        Dim nL As Double

        nL = Math.Sqrt(nX * nX + nY * nY + nZ * nZ)

        If nL = 0 Then
            Exit Sub
        End If

        nX = Math.Round(nX / nL, 3)
        nY = Math.Round(nY / nL, 3)
        nZ = Math.Round(nZ / nL, 3)

        Print(1, NumToString(iX1))
        Print(1, NumToString(iY1))
        Print(1, NumToString(iZ1))
        Print(1, NumToString(nX))
        Print(1, NumToString(nY))
        Print(1, NumToString(nZ))
        Print(1, NumToString(100))

        Print(1, NumToString(tX1))
        Print(1, NumToString(tY1))

        Print(1, NumToString(iX2))
        Print(1, NumToString(iY2))
        Print(1, NumToString(iZ2))
        Print(1, NumToString(nX))
        Print(1, NumToString(nY))
        Print(1, NumToString(nZ))
        Print(1, NumToString(100))

        Print(1, NumToString(tX2))
        Print(1, NumToString(tY2))

        Print(1, NumToString(iX3))
        Print(1, NumToString(iY3))
        Print(1, NumToString(iZ3))
        Print(1, NumToString(nX))
        Print(1, NumToString(nY))
        Print(1, NumToString(nZ))
        Print(1, NumToString(100))

        Print(1, NumToString(tX3))
        Print(1, NumToString(tY3))

        iTriangleCount = iTriangleCount + 1
    End Sub

    Private Function NumToString(ByVal sNum As Single, Optional ByVal iRep As Integer = 4) As String
        NumToString = Nothing

        If iRep = 4 Then
            NumToString = IIf(sNum < 0, Chr(1), Chr(0))
            sNum = Math.Abs(sNum)
        End If

        Dim iTest As Integer
        iTest = Math.Floor(sNum)
        NumToString = NumToString & Chr(iTest Mod 256)

        If iRep > 2 Then
            sNum = sNum - iTest
            sNum = sNum * 256
            NumToString = NumToString & NumToString(sNum, iRep - 1)
        End If
    End Function

    Private Sub cmdSetSample_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdSetSample.Click
        Dim ld As New LoadDialog()
        ld.Description = "Load Sample Texture"
        ld.Directory = My.Settings.OutputDirectory
        ld.Extensions = "BMP,PNG,JPG"

        ld.ShowDialog()

        Dim sFile As String

        sFile = ld.ReturnFile
        If Len(sFile) > 0 Then LoadSampleFile(ld.Directory & sFile)

    End Sub

    Private Sub LoadSampleFile(ByVal sFile As String)
        sSampleFile = sFile

        Try
            bSampleBitmap = Bitmap.FromFile(sSampleFile)
        Catch
            MsgBox("Can't open sample texture!")
        Finally

        End Try

        ShowSampleBitmap()
    End Sub

    Private Sub picSample_Paint(ByVal sender As Object, ByVal e As System.Windows.Forms.PaintEventArgs) Handles picSample.Paint
        ShowSampleBitmap()
        If Not (bSampleBitmap Is Nothing) Then
            e.Graphics.DrawImage(bSampleBitmap, 0, 0, picSample.Width, picSample.Height)
        End If
    End Sub

    Sub ShowSampleBitmap()
        Dim gr As Graphics
        gr = picSample.CreateGraphics
        If Not (bSampleBitmap Is Nothing) Then
            gr.DrawImage(bSampleBitmap, 0, 0, picSample.Width, picSample.Height)
        End If
    End Sub

    Private Sub picColors_MouseUp(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles picColors.MouseUp
        iSelectedColor = (e.Y + 30) / 60
        ShowColorList(picColors.CreateGraphics)
    End Sub

    Private iMouseDragSX As Long
    Private iMouseDragSY As Long

    Private Sub picSample_MouseDown(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles picSample.MouseDown
        iMouseDragSX = e.X
        iMouseDragSY = e.Y
    End Sub

    Private Sub picSample_MouseUp(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles picSample.MouseUp
        Dim iX1 As Long
        Dim iX2 As Long
        Dim iY1 As Long
        Dim iY2 As Long

        If iSelectedColor > 0 And e.X <> iMouseDragSX & e.Y <> iMouseDragSY Then
            If e.X > iMouseDragSX Then
                iX2 = e.X
                iX1 = iMouseDragSX
            Else
                iX1 = e.X
                iX2 = iMouseDragSX
            End If
            If e.Y > iMouseDragSY Then
                iY2 = e.Y
                iY1 = iMouseDragSY
            Else
                iY1 = e.Y
                iY2 = iMouseDragSY
            End If
            iColT(iSelectedColor) = iY1 / picSample.Height
            iColH(iSelectedColor) = (iY2 - iY1) / picSample.Height
            iColL(iSelectedColor) = iX1 / picSample.Width
            iColW(iSelectedColor) = (iX2 - iX1) / picSample.Width

            ShowColorList(picColors.CreateGraphics)
            DrawTexturedObject(picTextured.CreateGraphics())

        End If

    End Sub

    Private Sub cmdRender_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdRender.Click
        ' TODO: Selected index instead of current checked value?
        RenderObject(cbDrawBack.Checked, cbPosOffset.Checked)
    End Sub

    Private Sub picGraphics_Paint(ByVal sender As Object, ByVal e As System.Windows.Forms.PaintEventArgs) Handles picGraphics.Paint
        DrawSrcObject(e.Graphics)
    End Sub

    Dim sSettingFile As String
    Private Sub Form1_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        SetSettingFile("untitled")
    End Sub

    Private Sub SetSettingFile(ByVal sFile As String)
        sSettingFile = sFile
        Me.Text = "Jumpman Mesh Importer - " & sFile & ".SET"
    End Sub

    Private Sub cmdSaveSettings_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdSaveSettings.Click
        If sSettingFile = "untitled" Then
            sSettingFile = InputBox("File name?", "Save as...", sSettingFile)
            If sSettingFile = "" Then
                sSettingFile = "untitled"
                Exit Sub
            End If
            SetSettingFile(sSettingFile)
        End If

        Dim sAll As String = Nothing
        Dim iLoop As Long

        sAll = sAll & sSampleFile & vbCrLf

        sAll = sAll & iSrcFiles & vbCrLf
        For iLoop = 0 To iSrcFiles - 1
            sAll = sAll & sSrcFile(iLoop) & " " & bSrcBack(iLoop) & " " & bSrcOffset(iLoop) & vbCrLf
        Next

        sAll = sAll & iDefinedColors & vbCrLf
        For iLoop = 1 To iDefinedColors
            sAll = sAll & iDefinedColor(iLoop).R & " " & iDefinedColor(iLoop).G & " " & iDefinedColor(iLoop).B & " "
            sAll = sAll & iColL(iLoop) & " " & iColT(iLoop) & " "
            sAll = sAll & iColW(iLoop) & " " & iColH(iLoop) & " "
            sAll = sAll & iColZ1(iLoop) & " " & iColZ2(iLoop) & vbCrLf
        Next

        FileOpen(1, Path.Combine(My.Settings.SourceDirectory, sSettingFile & ".SET"), OpenMode.Output)
        Print(1, sAll)
        FileClose(1)
    End Sub

    Private Sub cmdLoadSettings_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdLoadSettings.Click
        Dim ld As New LoadDialog()
        ld.Description = "Load Import Settings"
        ld.Directory = My.Settings.SourceDirectory
        ld.Extensions = "SET"

        ld.ShowDialog()

        Dim sFile As String
        Dim sAll As String
        Dim sLines() As String
        Dim iLine As String = Nothing
        Dim sParts() As String
        Dim iLoop As Long

        sFile = ld.ReturnFile
        If Len(sFile) > 0 Then

            ResetColors()
            iDefinedColors = 0

            sFile = Microsoft.VisualBasic.Left(sFile, InStr(sFile, ".") - 1)
            SetSettingFile(sFile)

            FileOpen(1, Path.Combine(My.Settings.SourceDirectory, sFile & ".SET"), OpenMode.Input)
            sAll = InputString(1, LOF(1))
            sLines = Split(sAll, vbCrLf)
            LoadSampleFile(sLines(0))
            iLine = iLine + 1

            iSrcFiles = sLines(iLine)
            sAll = sAll & iSrcFiles & vbCrLf
            For iLoop = 0 To iSrcFiles - 1
                sParts = Split(sLines(iLoop + iLine + 1))
                sSrcFile(iLoop) = sParts(0)
                If UBound(sParts) > 0 Then bSrcBack(iLoop) = sParts(1) Else bSrcBack(iLoop) = False
                If UBound(sParts) > 1 Then bSrcOffset(iLoop) = sParts(2) Else bSrcOffset(iLoop) = False
            Next
            iLine = iLine + iSrcFiles + 1

            ShowSrcFiles()
            If iSrcFiles > 0 Then
                lstSrcFiles.Select()
                lstSrcFiles.SelectedIndex = 0
            End If

            Dim cCol As Color
            iDefinedColors = sLines(iLine)
            For iLoop = 1 To iDefinedColors
                sParts = Split(sLines(iLine + iLoop), " ")

                cCol = Color.FromArgb(255, sParts(0), sParts(1), sParts(2))
                iDefinedColor(iLoop) = cCol

                iColL(iLoop) = sParts(3)
                iColT(iLoop) = sParts(4)
                iColW(iLoop) = sParts(5)
                iColH(iLoop) = sParts(6)

                If UBound(sParts) = 8 Then
                    iColZ1(iLoop) = sParts(7)
                    iColZ2(iLoop) = sParts(8)
                End If
            Next

            If iDefinedColors > 0 Then iSelectedColor = 1

            ShowColorList(picColors.CreateGraphics)
            DrawTexturedObject(picTextured.CreateGraphics())

            FileClose(1)
        End If
    End Sub

    Sub ShowSrcFiles()
        Dim iLoop As Long

        lstSrcFiles.Items.Clear()

        For iLoop = 0 To iSrcFiles - 1
            lstSrcFiles.Items.Insert(iLoop, sSrcFile(iLoop))
        Next
    End Sub

    Private Sub picColors_Paint(ByVal sender As Object, ByVal e As System.Windows.Forms.PaintEventArgs) Handles picColors.Paint
        ShowColorList(e.Graphics)
    End Sub

    Private Sub lstSrcFiles_KeyUp(ByVal sender As Object, ByVal e As System.Windows.Forms.KeyEventArgs) Handles lstSrcFiles.KeyUp
        If e.KeyCode = Keys.Delete Then
            If lstSrcFiles.SelectedIndex >= 0 And lstSrcFiles.SelectedIndex < iSrcFiles Then
                Dim iLoop As Long

                For iLoop = lstSrcFiles.SelectedIndex To iSrcFiles - 2
                    sSrcFile(iLoop) = sSrcFile(iLoop + 1)
                Next

                iSrcFiles = iSrcFiles - 1
                ShowSrcFiles()
            End If
        End If
    End Sub

    Private Sub cmdAddSrcFile_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdAddSrcFile.Click
        Dim ld As New LoadDialog()
        ld.Description = "Add Source File"
        ld.Directory = My.Settings.SourceDirectory
        ld.Extensions = "BMP"
        ld.AllowMultiple = True

        ld.ShowDialog()

        Dim sFile As String
        Dim sParts() As String
        Dim iLoop As Long

        sFile = ld.ReturnFile

        If Len(sFile) > 0 Then
            sParts = Split(sFile, "~")
            For iLoop = 0 To UBound(sParts)
                sFile = Microsoft.VisualBasic.Left(sParts(iLoop), InStr(sParts(iLoop), ".") - 1)
                sSrcFile(iSrcFiles) = sFile
                iSrcFiles = iSrcFiles + 1
            Next
            ShowSrcFiles()
        End If

    End Sub

    Private Sub lstSrcFiles_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles lstSrcFiles.SelectedIndexChanged
        Dim iLoop As Long
        iLoop = lstSrcFiles.SelectedIndex
        If iLoop >= 0 And iLoop < iSrcFiles Then
            LoadBitmap(sSrcFile(iLoop))
            cbDrawBack.Checked = bSrcBack(iLoop)
            cbPosOffset.Checked = bSrcOffset(iLoop)

            ShowColorList(picColors.CreateGraphics)
            DrawTexturedObject(picTextured.CreateGraphics())
        End If
    End Sub

    Private Sub vsZ1_Scroll(ByVal sender As System.Object, ByVal e As System.Windows.Forms.ScrollEventArgs) Handles vsZ1.Scroll
        If iSelectedColor <> 0 Then
            iColZ1(iSelectedColor) = vsZ1.Value / 10
            lblZ1.Text = vsZ1.Value / 10
        End If
    End Sub

    Private Sub vsZ2_Scroll(ByVal sender As System.Object, ByVal e As System.Windows.Forms.ScrollEventArgs) Handles vsZ2.Scroll
        If iSelectedColor <> 0 Then
            iColZ2(iSelectedColor) = vsZ2.Value / 10
            lblZ2.Text = vsZ2.Value / 10
        End If
    End Sub

    Private Sub cmdRenderAll_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdRenderAll.Click
        Dim iLoop As Long
        For iLoop = 0 To iSrcFiles - 1
            LoadBitmap(sSrcFile(iLoop))  ' TODO: Don't edit UI settings! Just spit out data from item in list
            RenderObject(bSrcBack(iLoop), bSrcOffset(iLoop))
        Next
    End Sub

    Private Sub cbDrawBack_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cbDrawBack.CheckedChanged
        Dim iLoop As Long
        iLoop = lstSrcFiles.SelectedIndex
        If iLoop >= 0 And iLoop < iSrcFiles Then
            bSrcBack(iLoop) = cbDrawBack.Checked
        End If
    End Sub

    Private Sub cbPosOffset_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cbPosOffset.CheckedChanged
        Dim iLoop As Long
        iLoop = lstSrcFiles.SelectedIndex
        If iLoop >= 0 And iLoop < iSrcFiles Then
            bSrcOffset(iLoop) = cbPosOffset.Checked
        End If
    End Sub

    Private Sub picTextured_Paint(ByVal sender As Object, ByVal e As System.Windows.Forms.PaintEventArgs) Handles picTextured.Paint
        DrawTexturedObject(e.Graphics)
    End Sub

    Private Sub cmdReset_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdReset.Click
        ResetColors()
        ShowColorList(picColors.CreateGraphics)
    End Sub






    Private Sub cmdImpASE_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdASE.Click
        Dim sAll As String

        Dim sImportIn As String
        Dim sImportOut As String
        Dim sImport As String

        sImport = InputBox("File to import?")

        sImportIn = Path.Combine(My.Settings.AseImportDirectory, sImport & ".ase")
        sImportOut = Path.Combine(My.Settings.OutputDirectory, sImport & ".msh")

        If Dir(sImportIn) = "" Then
            MsgBox("Cannot open " & sImportIn & ".")
            Exit Sub
        End If

        FileOpen(1, sImportIn, OpenMode.Input)
        sAll = InputString(1, LOF(1))
        FileClose(1)

        FileOpen(1, sImportOut, OpenMode.Output)

        Dim sLines() As String
        sLines = Split(sAll, vbCrLf)

        Dim sItem As String
        Dim sObjectName As String = Nothing
        Dim fTransform(4, 4) As Double
        Dim fVertex(800, 3) As Double

        Dim iMaxVert As Integer

        Dim iV1 As Integer, iV2 As Integer, iV3 As Integer

        Dim iLine As Long
        Dim sLine As String
        Dim sParts() As String
        Dim iNum As Integer
        Dim iTemp As Integer
        Dim iTriangleCount As Integer

        For iLine = 0 To UBound(sLines)
            sLine = sLines(iLine)

            sLine = Replace(sLine, Chr(9), " ")
            sLine = Replace(sLine, Chr(7), " ")
            While InStr(sLine, "  ") <> 0
                sLine = Replace(sLine, "  ", " ")
            End While

            While Mid(sLine, 1, 1) = " "
                sLine = Mid(sLine, 2)
            End While

            sParts = Split(sLine, " ")

            sItem = sParts(0)

            If sItem = "*NODE_NAME" Then
                sObjectName = sParts(1)
            End If

            If Len(sItem) > 0 Then
                If Mid(sItem, 1, Len(sItem) - 1) = "*TM_ROW" Then
                    iNum = Mid(sItem, 8)
                    fTransform(iNum, 0) = sParts(1)
                    fTransform(iNum, 1) = sParts(2)
                    fTransform(iNum, 2) = sParts(3)
                End If
            End If

            If sItem = "*MESH_FACE_LIST" Then
                Dim iVert As Long
                Dim iCol As Long
                Dim fCalc As Double
                Dim iRow As Long
                Dim fTemp(2) As Double

                For iVert = 0 To iMaxVert

                    For iCol = 0 To 2
                        fCalc = 0
                        For iRow = 0 To 3
                            fCalc = fCalc + fTransform(iRow, iCol) * fVertex(iVert, iRow)
                        Next
                        fTemp(iCol) = fCalc
                    Next

                    For iCol = 0 To 2
                        fVertex(iVert, iCol) = fTemp(iCol) / 10.0
                    Next

                Next

                iMaxVert = 0

            End If

            If sItem = "*MESH_VERTEX" Then
                iNum = sParts(1)
                fVertex(iNum, 0) = sParts(2)
                fVertex(iNum, 1) = sParts(3)
                fVertex(iNum, 2) = sParts(4)
                fVertex(iNum, 3) = 1
                iMaxVert = iNum
            End If

            If sItem = "*MESH_FACE" Then
                iV1 = sParts(3)
                iV2 = sParts(5)
                iV3 = sParts(7)

                If InStr(sObjectName, "Triangle") <> 0 Then
                    iTemp = iV1
                    iV1 = iV2
                    iV2 = iTemp
                End If

                AddASETriangle(fVertex(iV1, 0), fVertex(iV1, 1), fVertex(iV1, 2), fVertex(iV2, 0), fVertex(iV2, 1), fVertex(iV2, 2), fVertex(iV3, 0), fVertex(iV3, 1), fVertex(iV3, 2), 0.1, 0)
                iTriangleCount = iTriangleCount + 1
            End If
        Next

        txtOutput.Text = "Finished importing " & sImport & ".ASE " & Now & " Tri Count: " & iTriangleCount & vbCrLf

        FileClose(1)
    End Sub

    Private Sub AddASETriangle(ByVal iX1 As Double, ByVal iY1 As Double, ByVal iZ1 As Double, ByVal iX2 As Double, ByVal iY2 As Double, ByVal iZ2 As Double, ByVal iX3 As Double, ByVal iY3 As Double, ByVal iZ3 As Double, ByVal tX As Single, ByVal tY As Single)
        Dim uX As Double, uY As Double, uZ As Double
        Dim vX As Double, vY As Double, vZ As Double
        Static iTeX As Long

        iTeX = IIf(iTeX = 0, 1, 0)

        uX = iX2 - iX1 : uY = iY2 - iY1 : uZ = iZ2 - iZ1
        vX = iX3 - iX1 : vY = iY3 - iY1 : vZ = iZ3 - iZ1

        Dim nX As Double, nY As Double, nZ As Double

        nX = (uY * vZ) - (uZ * vY)
        nY = (uZ * vX) - (uX * vZ)
        nZ = (uX * vY) - (uY * vX)

        Dim nL As Double

        nL = Math.Sqrt(nX * nX + nY * nY + nZ * nZ)

        If nL = 0 Then
            Exit Sub
        End If

        nX = Math.Round(nX / nL, 3)
        nY = Math.Round(nY / nL, 3)
        nZ = Math.Round(nZ / nL, 3)

        Dim sTX As Single, sTY As Single

        sTX = tX : sTY = tY

        Print(1, NumToString(iX1))
        Print(1, NumToString(iY1))
        Print(1, NumToString(iZ1))
        Print(1, NumToString(nX))
        Print(1, NumToString(nY))
        Print(1, NumToString(nZ))
        Print(1, NumToString(100))

        Print(1, NumToString(IIf(iTeX = 1, 1, 0)))
        Print(1, NumToString(IIf(iTeX = 1, 1, 0)))

        Print(1, NumToString(iX2))
        Print(1, NumToString(iY2))
        Print(1, NumToString(iZ2))
        Print(1, NumToString(nX))
        Print(1, NumToString(nY))
        Print(1, NumToString(nZ))
        Print(1, NumToString(100))

        Print(1, NumToString(IIf(iTeX = 1, 0, 1)))
        Print(1, NumToString(IIf(iTeX = 1, 1, 0)))

        Print(1, NumToString(iX3))
        Print(1, NumToString(iY3))
        Print(1, NumToString(iZ3))
        Print(1, NumToString(nX))
        Print(1, NumToString(nY))
        Print(1, NumToString(nZ))
        Print(1, NumToString(100))

        Print(1, NumToString(IIf(iTeX = 1, 0, 1)))
        Print(1, NumToString(IIf(iTeX = 1, 0, 1)))

    End Sub

    Private Sub EditSettingsMenuItem_Click(sender As Object, e As EventArgs) Handles EditSettingsMenuItem.Click
        Dim settingsDialog As SettingsDialog = New SettingsDialog()
        settingsDialog.StartPosition = FormStartPosition.CenterParent
        settingsDialog.ShowDialog(Me)
    End Sub
End Class
