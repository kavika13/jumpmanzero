Imports System.IO

Public Class JLForm
    Inherits System.Windows.Forms.Form

    Dim miLevel As Bitmap

    Dim msFile As String

    Dim msTool As String
    Dim miSelectedItem As Long

    Dim mbMouse As Boolean
    Dim mnMouseX As Single
    Dim mnMouseY As Single

    Public mLRs As Long
    Public mLR(500) As LevelResource

    Public loNull As New LevelObject()
    Public mLOs As Long
    Public mLO(500) As LevelObject

    Dim msBuff As String

    Dim miSSBox As Long
    Dim miSBoxes As Long
    Dim miSBX(10) As Long
    Dim miSBY(10) As Long
    Friend WithEvents SettingsMenuItem As System.Windows.Forms.MenuItem
    Dim miSBT(10) As Long

    Private Sub SetCaption()
        Me.Text = "Level Editor - " & msFile & ".lvl"
    End Sub

    Private Sub SortLevelObject()
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

    Private Sub Form1_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Dim iLoop As Long
        For iLoop = 0 To 100
            ReDim mLO(iLoop).V(8)
        Next

        miSelectedItem = -1
        UpdateHints(loNull, True)
        miSelectedItem = -1
        ResetButtons(True)
        cmdSelect.FlatStyle = FlatStyle.Flat
        msTool = "SELECT"
        msFile = "untitled"
        SetCaption()

        Dim g As Graphics
        g = picLevel.CreateGraphics
        miLevel = New Bitmap(picLevel.Width, picLevel.Height, g)
        g.Dispose()

        g = Graphics.FromImage(miLevel)
        g.Clear(Color.Black)
        g.Dispose()

    End Sub

#Region "Selecting Tools"
    Private Sub cmdSelect_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdSelect.Click
        ResetButtons(False)
        cmdSelect.FlatStyle = FlatStyle.Flat
        msTool = "SELECT"
    End Sub

    Private Sub cmdPlatform_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdPlatform.Click
        ResetButtons(False)
        cmdPlatform.FlatStyle = FlatStyle.Flat
        msTool = "PLATFORM"
    End Sub

    Private Sub cmdLadder_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdLadder.Click
        ResetButtons(False)
        cmdLadder.FlatStyle = FlatStyle.Flat
        msTool = "LADDER"
    End Sub

    Private Sub cmdDonut_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdDonut.Click
        ResetButtons(False)
        cmdDonut.FlatStyle = FlatStyle.Flat
        msTool = "DONUT"
    End Sub

    Private Sub cmdArbitrary_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdArbitrary.Click
        ResetButtons(False)
        cmdArbitrary.FlatStyle = FlatStyle.Flat
        msTool = "ARBITRARY"
    End Sub

    Private Sub cmdWall_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdWall.Click
        ResetButtons(False)
        cmdWall.FlatStyle = FlatStyle.Flat
        msTool = "WALL"
    End Sub

    Private Sub cmdVine_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdVine.Click
        ResetButtons(False)
        cmdVine.FlatStyle = FlatStyle.Flat
        msTool = "VINE"
    End Sub
#End Region

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
    Friend WithEvents picLevel As System.Windows.Forms.PictureBox
    Friend WithEvents MainMenu1 As System.Windows.Forms.MainMenu
    Friend WithEvents MenuItem1 As System.Windows.Forms.MenuItem
    Friend WithEvents MenuNew As System.Windows.Forms.MenuItem
    Friend WithEvents MenuLoad As System.Windows.Forms.MenuItem
    Friend WithEvents MenuSave As System.Windows.Forms.MenuItem
    Friend WithEvents MenuSaveAs As System.Windows.Forms.MenuItem
    Friend WithEvents MenuExit As System.Windows.Forms.MenuItem
    Friend WithEvents cmdPlatform As System.Windows.Forms.Button
    Friend WithEvents cmdSelect As System.Windows.Forms.Button
    Friend WithEvents cmdLadder As System.Windows.Forms.Button
    Friend WithEvents cmdDonut As System.Windows.Forms.Button
    Friend WithEvents cmdVine As System.Windows.Forms.Button
    Friend WithEvents MenuItem2 As System.Windows.Forms.MenuItem
    Friend WithEvents MenuItem4 As System.Windows.Forms.MenuItem
    Friend WithEvents MenuRender As System.Windows.Forms.MenuItem
    Friend WithEvents MenuResources As System.Windows.Forms.MenuItem
    Friend WithEvents timRepaint As System.Timers.Timer
    Friend WithEvents cmdDelete As System.Windows.Forms.Button
    Friend WithEvents cmdEdit As System.Windows.Forms.Button
    Friend WithEvents vsZ1 As System.Windows.Forms.VScrollBar
    Friend WithEvents vsZ2 As System.Windows.Forms.VScrollBar
    Friend WithEvents lblZ1 As System.Windows.Forms.Label
    Friend WithEvents lblZ2 As System.Windows.Forms.Label
    Friend WithEvents lblV1 As System.Windows.Forms.Label
    Friend WithEvents lblV2 As System.Windows.Forms.Label
    Friend WithEvents lblV3 As System.Windows.Forms.Label
    Friend WithEvents lblV4 As System.Windows.Forms.Label
    Friend WithEvents cmdArbitrary As System.Windows.Forms.Button
    Friend WithEvents vsZ3 As System.Windows.Forms.VScrollBar
    Friend WithEvents vsZ4 As System.Windows.Forms.VScrollBar
    Friend WithEvents lblZ3 As System.Windows.Forms.Label
    Friend WithEvents lblZ4 As System.Windows.Forms.Label
    Friend WithEvents cmdWall As System.Windows.Forms.Button
    Friend WithEvents grpDepth As System.Windows.Forms.GroupBox
    Friend WithEvents grpCoordinates As System.Windows.Forms.GroupBox
    Friend WithEvents cbShowPictures As System.Windows.Forms.CheckBox
    Friend WithEvents cmdSaveRender As System.Windows.Forms.Button
    <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
        Me.components = New System.ComponentModel.Container()
        Me.picLevel = New System.Windows.Forms.PictureBox()
        Me.MainMenu1 = New System.Windows.Forms.MainMenu(Me.components)
        Me.MenuItem1 = New System.Windows.Forms.MenuItem()
        Me.MenuNew = New System.Windows.Forms.MenuItem()
        Me.MenuLoad = New System.Windows.Forms.MenuItem()
        Me.MenuSave = New System.Windows.Forms.MenuItem()
        Me.MenuSaveAs = New System.Windows.Forms.MenuItem()
        Me.MenuRender = New System.Windows.Forms.MenuItem()
        Me.MenuExit = New System.Windows.Forms.MenuItem()
        Me.MenuItem2 = New System.Windows.Forms.MenuItem()
        Me.MenuResources = New System.Windows.Forms.MenuItem()
        Me.MenuItem4 = New System.Windows.Forms.MenuItem()
        Me.SettingsMenuItem = New System.Windows.Forms.MenuItem()
        Me.cmdPlatform = New System.Windows.Forms.Button()
        Me.cmdSelect = New System.Windows.Forms.Button()
        Me.cmdLadder = New System.Windows.Forms.Button()
        Me.cmdDonut = New System.Windows.Forms.Button()
        Me.cmdVine = New System.Windows.Forms.Button()
        Me.timRepaint = New System.Timers.Timer()
        Me.cmdDelete = New System.Windows.Forms.Button()
        Me.cmdEdit = New System.Windows.Forms.Button()
        Me.vsZ1 = New System.Windows.Forms.VScrollBar()
        Me.vsZ2 = New System.Windows.Forms.VScrollBar()
        Me.lblZ1 = New System.Windows.Forms.Label()
        Me.lblZ2 = New System.Windows.Forms.Label()
        Me.lblV1 = New System.Windows.Forms.Label()
        Me.lblV2 = New System.Windows.Forms.Label()
        Me.lblV3 = New System.Windows.Forms.Label()
        Me.lblV4 = New System.Windows.Forms.Label()
        Me.cmdArbitrary = New System.Windows.Forms.Button()
        Me.vsZ3 = New System.Windows.Forms.VScrollBar()
        Me.vsZ4 = New System.Windows.Forms.VScrollBar()
        Me.lblZ3 = New System.Windows.Forms.Label()
        Me.lblZ4 = New System.Windows.Forms.Label()
        Me.cmdWall = New System.Windows.Forms.Button()
        Me.grpDepth = New System.Windows.Forms.GroupBox()
        Me.grpCoordinates = New System.Windows.Forms.GroupBox()
        Me.cbShowPictures = New System.Windows.Forms.CheckBox()
        Me.cmdSaveRender = New System.Windows.Forms.Button()
        CType(Me.picLevel, System.ComponentModel.ISupportInitialize).BeginInit()
        CType(Me.timRepaint, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.grpDepth.SuspendLayout()
        Me.grpCoordinates.SuspendLayout()
        Me.SuspendLayout()
        '
        'picLevel
        '
        Me.picLevel.BackColor = System.Drawing.Color.Black
        Me.picLevel.Location = New System.Drawing.Point(48, 8)
        Me.picLevel.Name = "picLevel"
        Me.picLevel.Size = New System.Drawing.Size(650, 650)
        Me.picLevel.TabIndex = 4
        Me.picLevel.TabStop = False
        '
        'MainMenu1
        '
        Me.MainMenu1.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.MenuItem1, Me.MenuItem2})
        '
        'MenuItem1
        '
        Me.MenuItem1.Index = 0
        Me.MenuItem1.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.MenuNew, Me.MenuLoad, Me.MenuSave, Me.MenuSaveAs, Me.MenuRender, Me.MenuExit})
        Me.MenuItem1.Text = "File"
        '
        'MenuNew
        '
        Me.MenuNew.Index = 0
        Me.MenuNew.Text = "New"
        '
        'MenuLoad
        '
        Me.MenuLoad.Index = 1
        Me.MenuLoad.Text = "Load"
        '
        'MenuSave
        '
        Me.MenuSave.Index = 2
        Me.MenuSave.Text = "Save"
        '
        'MenuSaveAs
        '
        Me.MenuSaveAs.Index = 3
        Me.MenuSaveAs.Text = "Save as..."
        '
        'MenuRender
        '
        Me.MenuRender.Index = 4
        Me.MenuRender.Text = "Render"
        '
        'MenuExit
        '
        Me.MenuExit.Index = 5
        Me.MenuExit.Text = "Exit"
        '
        'MenuItem2
        '
        Me.MenuItem2.Index = 1
        Me.MenuItem2.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.MenuResources, Me.MenuItem4, Me.SettingsMenuItem})
        Me.MenuItem2.Text = "Edit"
        '
        'MenuResources
        '
        Me.MenuResources.Index = 0
        Me.MenuResources.Text = "Resources"
        '
        'MenuItem4
        '
        Me.MenuItem4.Index = 1
        Me.MenuItem4.Text = "Scripts"
        '
        'SettingsMenuItem
        '
        Me.SettingsMenuItem.Index = 2
        Me.SettingsMenuItem.Text = "&Settings"
        '
        'cmdPlatform
        '
        Me.cmdPlatform.Location = New System.Drawing.Point(8, 40)
        Me.cmdPlatform.Name = "cmdPlatform"
        Me.cmdPlatform.Size = New System.Drawing.Size(32, 32)
        Me.cmdPlatform.TabIndex = 5
        '
        'cmdSelect
        '
        Me.cmdSelect.Location = New System.Drawing.Point(8, 8)
        Me.cmdSelect.Name = "cmdSelect"
        Me.cmdSelect.Size = New System.Drawing.Size(32, 32)
        Me.cmdSelect.TabIndex = 6
        '
        'cmdLadder
        '
        Me.cmdLadder.Location = New System.Drawing.Point(8, 72)
        Me.cmdLadder.Name = "cmdLadder"
        Me.cmdLadder.Size = New System.Drawing.Size(32, 32)
        Me.cmdLadder.TabIndex = 7
        '
        'cmdDonut
        '
        Me.cmdDonut.Location = New System.Drawing.Point(8, 104)
        Me.cmdDonut.Name = "cmdDonut"
        Me.cmdDonut.Size = New System.Drawing.Size(32, 32)
        Me.cmdDonut.TabIndex = 8
        '
        'cmdVine
        '
        Me.cmdVine.Location = New System.Drawing.Point(8, 136)
        Me.cmdVine.Name = "cmdVine"
        Me.cmdVine.Size = New System.Drawing.Size(32, 32)
        Me.cmdVine.TabIndex = 9
        '
        'timRepaint
        '
        Me.timRepaint.Interval = 300.0R
        Me.timRepaint.SynchronizingObject = Me
        '
        'cmdDelete
        '
        Me.cmdDelete.Location = New System.Drawing.Point(8, 272)
        Me.cmdDelete.Name = "cmdDelete"
        Me.cmdDelete.Size = New System.Drawing.Size(32, 32)
        Me.cmdDelete.TabIndex = 10
        '
        'cmdEdit
        '
        Me.cmdEdit.Location = New System.Drawing.Point(8, 240)
        Me.cmdEdit.Name = "cmdEdit"
        Me.cmdEdit.Size = New System.Drawing.Size(32, 32)
        Me.cmdEdit.TabIndex = 11
        '
        'vsZ1
        '
        Me.vsZ1.LargeChange = 1
        Me.vsZ1.Location = New System.Drawing.Point(16, 16)
        Me.vsZ1.Maximum = 20
        Me.vsZ1.Name = "vsZ1"
        Me.vsZ1.Size = New System.Drawing.Size(16, 168)
        Me.vsZ1.TabIndex = 12
        Me.vsZ1.Visible = False
        '
        'vsZ2
        '
        Me.vsZ2.LargeChange = 1
        Me.vsZ2.Location = New System.Drawing.Point(40, 16)
        Me.vsZ2.Maximum = 20
        Me.vsZ2.Name = "vsZ2"
        Me.vsZ2.Size = New System.Drawing.Size(16, 168)
        Me.vsZ2.TabIndex = 14
        Me.vsZ2.Visible = False
        '
        'lblZ1
        '
        Me.lblZ1.Location = New System.Drawing.Point(8, 192)
        Me.lblZ1.Name = "lblZ1"
        Me.lblZ1.Size = New System.Drawing.Size(32, 16)
        Me.lblZ1.TabIndex = 15
        Me.lblZ1.Text = "Z1"
        Me.lblZ1.TextAlign = System.Drawing.ContentAlignment.MiddleCenter
        '
        'lblZ2
        '
        Me.lblZ2.Location = New System.Drawing.Point(32, 192)
        Me.lblZ2.Name = "lblZ2"
        Me.lblZ2.Size = New System.Drawing.Size(32, 16)
        Me.lblZ2.TabIndex = 16
        Me.lblZ2.Text = "Z2"
        Me.lblZ2.TextAlign = System.Drawing.ContentAlignment.MiddleCenter
        '
        'lblV1
        '
        Me.lblV1.Location = New System.Drawing.Point(8, 24)
        Me.lblV1.Name = "lblV1"
        Me.lblV1.Size = New System.Drawing.Size(80, 16)
        Me.lblV1.TabIndex = 17
        Me.lblV1.Text = "V1"
        '
        'lblV2
        '
        Me.lblV2.Location = New System.Drawing.Point(8, 40)
        Me.lblV2.Name = "lblV2"
        Me.lblV2.Size = New System.Drawing.Size(80, 16)
        Me.lblV2.TabIndex = 18
        Me.lblV2.Text = "V2"
        '
        'lblV3
        '
        Me.lblV3.Location = New System.Drawing.Point(8, 56)
        Me.lblV3.Name = "lblV3"
        Me.lblV3.Size = New System.Drawing.Size(80, 16)
        Me.lblV3.TabIndex = 19
        Me.lblV3.Text = "V3"
        '
        'lblV4
        '
        Me.lblV4.Location = New System.Drawing.Point(8, 72)
        Me.lblV4.Name = "lblV4"
        Me.lblV4.Size = New System.Drawing.Size(80, 16)
        Me.lblV4.TabIndex = 20
        Me.lblV4.Text = "V4"
        '
        'cmdArbitrary
        '
        Me.cmdArbitrary.Location = New System.Drawing.Point(8, 168)
        Me.cmdArbitrary.Name = "cmdArbitrary"
        Me.cmdArbitrary.Size = New System.Drawing.Size(32, 32)
        Me.cmdArbitrary.TabIndex = 21
        '
        'vsZ3
        '
        Me.vsZ3.LargeChange = 1
        Me.vsZ3.Location = New System.Drawing.Point(64, 16)
        Me.vsZ3.Maximum = 20
        Me.vsZ3.Name = "vsZ3"
        Me.vsZ3.Size = New System.Drawing.Size(16, 168)
        Me.vsZ3.TabIndex = 22
        Me.vsZ3.Visible = False
        '
        'vsZ4
        '
        Me.vsZ4.LargeChange = 1
        Me.vsZ4.Location = New System.Drawing.Point(88, 16)
        Me.vsZ4.Maximum = 20
        Me.vsZ4.Name = "vsZ4"
        Me.vsZ4.Size = New System.Drawing.Size(16, 168)
        Me.vsZ4.TabIndex = 23
        Me.vsZ4.Visible = False
        '
        'lblZ3
        '
        Me.lblZ3.Location = New System.Drawing.Point(56, 192)
        Me.lblZ3.Name = "lblZ3"
        Me.lblZ3.Size = New System.Drawing.Size(32, 16)
        Me.lblZ3.TabIndex = 24
        Me.lblZ3.Text = "Z3"
        Me.lblZ3.TextAlign = System.Drawing.ContentAlignment.MiddleCenter
        '
        'lblZ4
        '
        Me.lblZ4.Location = New System.Drawing.Point(80, 192)
        Me.lblZ4.Name = "lblZ4"
        Me.lblZ4.Size = New System.Drawing.Size(32, 16)
        Me.lblZ4.TabIndex = 25
        Me.lblZ4.Text = "Z4"
        Me.lblZ4.TextAlign = System.Drawing.ContentAlignment.MiddleCenter
        '
        'cmdWall
        '
        Me.cmdWall.Location = New System.Drawing.Point(8, 200)
        Me.cmdWall.Name = "cmdWall"
        Me.cmdWall.Size = New System.Drawing.Size(32, 32)
        Me.cmdWall.TabIndex = 26
        '
        'grpDepth
        '
        Me.grpDepth.Controls.Add(Me.vsZ4)
        Me.grpDepth.Controls.Add(Me.vsZ1)
        Me.grpDepth.Controls.Add(Me.vsZ2)
        Me.grpDepth.Controls.Add(Me.vsZ3)
        Me.grpDepth.Controls.Add(Me.lblZ2)
        Me.grpDepth.Controls.Add(Me.lblZ4)
        Me.grpDepth.Controls.Add(Me.lblZ1)
        Me.grpDepth.Controls.Add(Me.lblZ3)
        Me.grpDepth.Location = New System.Drawing.Point(712, 16)
        Me.grpDepth.Name = "grpDepth"
        Me.grpDepth.Size = New System.Drawing.Size(120, 216)
        Me.grpDepth.TabIndex = 27
        Me.grpDepth.TabStop = False
        Me.grpDepth.Text = "Depth"
        '
        'grpCoordinates
        '
        Me.grpCoordinates.Controls.Add(Me.lblV4)
        Me.grpCoordinates.Controls.Add(Me.lblV3)
        Me.grpCoordinates.Controls.Add(Me.lblV2)
        Me.grpCoordinates.Controls.Add(Me.lblV1)
        Me.grpCoordinates.Location = New System.Drawing.Point(712, 240)
        Me.grpCoordinates.Name = "grpCoordinates"
        Me.grpCoordinates.Size = New System.Drawing.Size(120, 96)
        Me.grpCoordinates.TabIndex = 28
        Me.grpCoordinates.TabStop = False
        Me.grpCoordinates.Text = "Co-ordinates"
        '
        'cbShowPictures
        '
        Me.cbShowPictures.Location = New System.Drawing.Point(712, 344)
        Me.cbShowPictures.Name = "cbShowPictures"
        Me.cbShowPictures.Size = New System.Drawing.Size(120, 16)
        Me.cbShowPictures.TabIndex = 29
        Me.cbShowPictures.Text = "Show Pictures"
        '
        'cmdSaveRender
        '
        Me.cmdSaveRender.Location = New System.Drawing.Point(8, 312)
        Me.cmdSaveRender.Name = "cmdSaveRender"
        Me.cmdSaveRender.Size = New System.Drawing.Size(32, 32)
        Me.cmdSaveRender.TabIndex = 30
        '
        'JLForm
        '
        Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
        Me.ClientSize = New System.Drawing.Size(840, 673)
        Me.Controls.Add(Me.cmdSaveRender)
        Me.Controls.Add(Me.cbShowPictures)
        Me.Controls.Add(Me.grpCoordinates)
        Me.Controls.Add(Me.grpDepth)
        Me.Controls.Add(Me.cmdWall)
        Me.Controls.Add(Me.cmdArbitrary)
        Me.Controls.Add(Me.cmdEdit)
        Me.Controls.Add(Me.cmdDelete)
        Me.Controls.Add(Me.cmdVine)
        Me.Controls.Add(Me.cmdDonut)
        Me.Controls.Add(Me.cmdLadder)
        Me.Controls.Add(Me.cmdSelect)
        Me.Controls.Add(Me.cmdPlatform)
        Me.Controls.Add(Me.picLevel)
        Me.KeyPreview = True
        Me.Menu = Me.MainMenu1
        Me.Name = "JLForm"
        Me.Text = "Jumpman Levels"
        CType(Me.picLevel, System.ComponentModel.ISupportInitialize).EndInit()
        CType(Me.timRepaint, System.ComponentModel.ISupportInitialize).EndInit()
        Me.grpDepth.ResumeLayout(False)
        Me.grpCoordinates.ResumeLayout(False)
        Me.ResumeLayout(False)

    End Sub

#End Region

    Private Sub RenderLevel(ByVal bFile As Boolean)
        Dim g As Graphics

        If bFile Then SortLevelObject()

        g = Graphics.FromImage(miLevel)
        g.Clear(Color.Black)
        g.Dispose()

        If bFile Then
            FileOpen(10, Path.Combine(My.Settings.LevelCompileOutputDirectory, msFile & ".DAT"), OpenMode.Output, OpenAccess.Default)
        End If

        Dim iLoop As Long

        If bFile Then
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
            FileOpen(17, Path.Combine(My.Settings.LevelSourceDirectory, msFile & "Resources.jms"), OpenMode.Output, OpenAccess.Default)
            Print(17, sAll)
            FileClose(17)
        End If

        For iLoop = 0 To mLOs - 1
            ProcessLO(mLO(iLoop), bFile, False, False)
        Next

        g = picLevel.CreateGraphics
        g.DrawImage(miLevel, 0, 0)

        miSBoxes = 0
        If miSelectedItem <> -1 Then
            ProcessLO(mLO(miSelectedItem), False, True, True)
            DrawSBoxes()
            UpdateHints(mLO(miSelectedItem), True)
        Else
            UpdateHints(loNull, True)
        End If

        If bFile Then
            FileClose(10)
            MsgBox("Render complete.")
        End If
    End Sub

    Private Sub UpdateHints(ByVal LO As LevelObject, ByVal bDoScrolls As Boolean)

        If LO.Type = "" Then
            vsZ1.Visible = False
            vsZ2.Visible = False
            vsZ3.Visible = False
            vsZ4.Visible = False
            lblZ1.Text = ""
            lblZ2.Text = ""
            lblZ3.Text = ""
            lblZ4.Text = ""
            lblV1.Text = ""
            lblV2.Text = ""
            lblV3.Text = ""
            lblV4.Text = ""
            Exit Sub
        End If

        If bDoScrolls Then
            If LO.Type = "ARBITRARY" Then
                vsZ1.Maximum = 200
                vsZ2.Maximum = 200
                vsZ3.Maximum = 200
                vsZ4.Maximum = 200
                vsZ1.Visible = True
                vsZ2.Visible = True
                vsZ3.Visible = True
                vsZ4.Visible = True
                vsZ1.Value = LO.V(1).Z
                vsZ2.Value = LO.V(2).Z
                vsZ3.Value = LO.V(3).Z
                vsZ4.Value = LO.V(4).Z
                lblZ1.Text = LO.V(1).Z
                lblZ2.Text = LO.V(2).Z
                lblZ3.Text = LO.V(3).Z
                lblZ4.Text = LO.V(4).Z
            Else
                vsZ1.Maximum = 20
                vsZ2.Maximum = 20
                vsZ1.Visible = True
                vsZ2.Visible = True
                vsZ3.Visible = False
                vsZ4.Visible = False
                vsZ1.Value = LO.Z1
                vsZ2.Value = LO.Z2
                lblZ1.Text = LO.Z1
                lblZ2.Text = LO.Z2
                lblZ3.Text = ""
                lblZ4.Text = ""
            End If
        End If

        lblV1.Text = ""
        lblV2.Text = ""
        lblV3.Text = ""
        lblV4.Text = ""

        If LO.Type = "LADDER" Or LO.Type = "VINE" Then
            lblV1.Text = LO.V(1).X & ", " & LO.V(1).Y & "-" & LO.V(2).Y
        ElseIf LO.Type = "DONUT" Then
            lblV1.Text = LO.V(1).X & ", " & LO.V(1).Y
        ElseIf LO.Type = "ARBITRARY" Or LO.Type = "WALL" Or LO.Type = "PLATFORM" Then
            lblV1.Text = LO.V(1).X & ", " & LO.V(1).Y
            lblV2.Text = LO.V(2).X & ", " & LO.V(2).Y
            lblV3.Text = LO.V(3).X & ", " & LO.V(3).Y
            lblV4.Text = LO.V(4).X & ", " & LO.V(4).Y
        End If

    End Sub

    Private Sub DrawSBoxes()
        Dim iLoop As Long

        For iLoop = 0 To miSBoxes - 1
            DSLine(miSBX(iLoop) - 1, miSBY(iLoop) - 1, miSBX(iLoop) + 1, miSBY(iLoop) - 1, Color.Beige, True)
            DSLine(miSBX(iLoop) - 1, miSBY(iLoop) + 1, miSBX(iLoop) + 1, miSBY(iLoop) + 1, Color.Beige, True)
            DSLine(miSBX(iLoop) - 1, miSBY(iLoop) - 1, miSBX(iLoop) - 1, miSBY(iLoop) + 1, Color.Beige, True)
            DSLine(miSBX(iLoop) + 1, miSBY(iLoop) - 1, miSBX(iLoop) + 1, miSBY(iLoop) + 1, Color.Beige, True)
        Next
    End Sub

    Private Sub ProcessLO(ByVal LO As LevelObject, ByVal bFile As Boolean, ByVal bToScreen As Boolean, ByVal bSelected As Boolean)
        Dim sBuff As String

        If LO.Type = "PLATFORM" Then
            If bSelected Then
                DSLine(LO.V(1).X, LO.V(1).Y, LO.V(2).X, LO.V(2).Y, Color.Red, bToScreen)
                DSLine(LO.V(2).X, LO.V(2).Y, LO.V(4).X, LO.V(4).Y, Color.Pink, bToScreen)
                DSLine(LO.V(3).X, LO.V(3).Y, LO.V(4).X, LO.V(4).Y, Color.Pink, bToScreen)
                DSLine(LO.V(3).X, LO.V(3).Y, LO.V(1).X, LO.V(1).Y, Color.Pink, bToScreen)
                miSBoxes = 0
                miSBX(miSBoxes) = LO.V(1).X
                miSBY(miSBoxes) = LO.V(1).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(2).X
                miSBY(miSBoxes) = LO.V(2).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(3).X
                miSBY(miSBoxes) = LO.V(3).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(4).X
                miSBY(miSBoxes) = LO.V(4).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = (LO.V(1).X + LO.V(2).X) / 2
                miSBY(miSBoxes) = (LO.V(1).Y + LO.V(2).Y) / 2
                miSBoxes = miSBoxes + 1
            Else
                DSLine(LO.V(1).X, LO.V(1).Y, LO.V(2).X, LO.V(2).Y, Color.Green, bToScreen)
                DSLine(LO.V(2).X, LO.V(2).Y, LO.V(4).X, LO.V(4).Y, Color.Gray, bToScreen)
                DSLine(LO.V(3).X, LO.V(3).Y, LO.V(4).X, LO.V(4).Y, Color.Gray, bToScreen)
                DSLine(LO.V(3).X, LO.V(3).Y, LO.V(1).X, LO.V(1).Y, Color.Gray, bToScreen)
            End If

            If bFile Then
                OutputLine("P", LO.V(1).X, LO.V(1).Y, LO.V(2).X, LO.V(2).Y, LO.Z1, LO.Extra, LO.Number, LO.Texture, 0, 0, "")
                sBuff = ""
                AddPCube(sBuff, LO.V(1), LO.V(2), LO.V(3), LO.V(4), LO)
                OutputBuffer(sBuff)
            End If
        End If

        If LO.Type = "WALL" Then
            If bSelected Then
                DSLine(LO.V(1).X, LO.V(1).Y, LO.V(2).X, LO.V(2).Y, Color.White, bToScreen)
                DSLine(LO.V(2).X, LO.V(2).Y, LO.V(4).X, LO.V(4).Y, Color.Red, bToScreen)
                DSLine(LO.V(3).X, LO.V(3).Y, LO.V(4).X, LO.V(4).Y, Color.Red, bToScreen)
                DSLine(LO.V(3).X, LO.V(3).Y, LO.V(1).X, LO.V(1).Y, Color.Red, bToScreen)
                miSBoxes = 0
                miSBX(miSBoxes) = LO.V(1).X
                miSBY(miSBoxes) = LO.V(1).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(2).X
                miSBY(miSBoxes) = LO.V(2).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(3).X
                miSBY(miSBoxes) = LO.V(3).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(4).X
                miSBY(miSBoxes) = LO.V(4).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = (LO.V(1).X + LO.V(2).X + LO.V(3).X + LO.V(4).X) / 4
                miSBY(miSBoxes) = (LO.V(1).Y + LO.V(2).Y + LO.V(3).Y + LO.V(4).Y) / 4
                miSBoxes = miSBoxes + 1
            Else
                DSLine(LO.V(1).X, LO.V(1).Y, LO.V(2).X, LO.V(2).Y, Color.Purple, bToScreen)
                DSLine(LO.V(2).X, LO.V(2).Y, LO.V(4).X, LO.V(4).Y, Color.Purple, bToScreen)
                DSLine(LO.V(3).X, LO.V(3).Y, LO.V(4).X, LO.V(4).Y, Color.Purple, bToScreen)
                DSLine(LO.V(3).X, LO.V(3).Y, LO.V(1).X, LO.V(1).Y, Color.Purple, bToScreen)
            End If

            If bFile Then
                OutputLine("W", LO.V(1).X, LO.V(1).Y, LO.V(2).X, LO.V(2).Y, LO.V(4).X, LO.V(4).Y, LO.V(3).X, LO.V(3).Y, LO.Number, LO.Texture, "")
                sBuff = ""
                AddPCube(sBuff, LO.V(1), LO.V(2), LO.V(3), LO.V(4), LO)
                OutputBuffer(sBuff)
            End If
        End If

        If LO.Type = "LADDER" Then
            If bSelected Then
                DrawLadder(LO.V(1).X, LO.V(1).Y, LO.V(2).Y, Color.Red, bToScreen)
                miSBoxes = 0
                miSBX(miSBoxes) = LO.V(1).X
                miSBY(miSBoxes) = LO.V(1).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(1).X
                miSBY(miSBoxes) = LO.V(2).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(1).X
                miSBY(miSBoxes) = (LO.V(1).Y + LO.V(2).Y) / 2
                miSBoxes = miSBoxes + 1
            Else
                DrawLadder(LO.V(1).X, LO.V(1).Y, LO.V(2).Y, Color.Blue, bToScreen)
            End If

            If bFile Then
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
        End If

        If LO.Type = "VINE" Then
            If bSelected Then
                DrawVine(LO.V(1).X, LO.V(1).Y, LO.V(2).Y, Color.Red, bToScreen)
                miSBoxes = 0
                miSBX(miSBoxes) = LO.V(1).X
                miSBY(miSBoxes) = LO.V(1).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(1).X
                miSBY(miSBoxes) = LO.V(2).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(1).X
                miSBY(miSBoxes) = (LO.V(1).Y + LO.V(2).Y) / 2
                miSBoxes = miSBoxes + 1
            Else
                DrawVine(LO.V(1).X, LO.V(1).Y, LO.V(2).Y, Color.Purple, bToScreen)
            End If

            If bFile Then
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
        End If

        If LO.Type = "ARBITRARY" Then
            If bSelected Then
                DrawArbitrary(LO, Color.Red, bToScreen)
                miSBoxes = 0
                miSBX(miSBoxes) = LO.V(1).X
                miSBY(miSBoxes) = LO.V(1).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(2).X
                miSBY(miSBoxes) = LO.V(2).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(3).X
                miSBY(miSBoxes) = LO.V(3).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = LO.V(4).X
                miSBY(miSBoxes) = LO.V(4).Y
                miSBoxes = miSBoxes + 1
                miSBX(miSBoxes) = (LO.V(1).X + LO.V(2).X + LO.V(3).X + LO.V(4).X) / 4
                miSBY(miSBoxes) = (LO.V(1).Y + LO.V(2).Y + LO.V(3).Y + LO.V(4).Y) / 4
                miSBoxes = miSBoxes + 1
            ElseIf cbShowPictures.Checked Then
                DrawArbitrary(LO, Color.Gray, bToScreen)
            End If

            If bFile Then
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
        End If

        If LO.Type = "DONUT" Then
            If bSelected Then
                DrawDonut(LO.V(1).X, LO.V(1).Y, Color.Red, bToScreen)
                miSBoxes = 0
                miSBX(miSBoxes) = LO.V(1).X
                miSBY(miSBoxes) = LO.V(1).Y
                miSBoxes = miSBoxes + 1
            Else
                DrawDonut(LO.V(1).X, LO.V(1).Y, Color.Brown, bToScreen)
            End If

            If bFile Then
                OutputLine("D", LO.V(1).X, LO.V(1).Y, LO.Z1, LO.Number, LO.Texture, 0, 0, 0, 0, 0, "")
                sBuff = ""

                AddOCube(sBuff, LO.V(1).X - 1, LO.V(1).Y + 3, LO.Z1, LO.V(1).X + 1, LO.V(1).Y + 1, LO.Z2, LO)
                AddOCube(sBuff, LO.V(1).X - 1, LO.V(1).Y - 1, LO.Z1, LO.V(1).X + 1, LO.V(1).Y - 3, LO.Z2, LO)
                AddOCube(sBuff, LO.V(1).X - 3, LO.V(1).Y + 1, LO.Z1, LO.V(1).X - 1, LO.V(1).Y - 1, LO.Z2, LO)
                AddOCube(sBuff, LO.V(1).X + 1, LO.V(1).Y + 1, LO.Z1, LO.V(1).X + 3, LO.V(1).Y - 1, LO.Z2, LO)

                OutputBuffer(sBuff)
            End If
        End If

    End Sub


    Private Sub DrawArbitrary(ByVal LO As LevelObject, ByVal iCol As System.Drawing.Color, ByVal bToScreen As Boolean)
        DSLine(LO.V(1).X, LO.V(1).Y, LO.V(2).X, LO.V(2).Y, iCol, bToScreen)
        DSLine(LO.V(2).X, LO.V(2).Y, LO.V(4).X, LO.V(4).Y, iCol, bToScreen)
        DSLine(LO.V(4).X, LO.V(4).Y, LO.V(3).X, LO.V(3).Y, iCol, bToScreen)
        DSLine(LO.V(3).X, LO.V(3).Y, LO.V(1).X, LO.V(1).Y, iCol, bToScreen)

        If iCol.R = Color.Red.R Then
            DSLine(LO.V(1).X, LO.V(1).Y, LO.V(4).X, LO.V(4).Y, iCol, bToScreen)
            DSLine(LO.V(3).X, LO.V(3).Y, LO.V(2).X, LO.V(2).Y, iCol, bToScreen)
        End If
    End Sub

    Private Sub DrawDonut(ByVal iX As Long, ByVal iY As Long, ByVal iCol As System.Drawing.Color, ByVal bToScreen As Boolean)
        DSLine(iX - 1, iY - 2, iX + 1, iY - 2, iCol, bToScreen)
        DSLine(iX - 1, iY + 2, iX + 1, iY + 2, iCol, bToScreen)
        DSLine(iX - 1, iY - 1, iX + 1, iY - 1, iCol, bToScreen)
        DSLine(iX - 1, iY + 1, iX + 1, iY + 1, iCol, bToScreen)

        DSLine(iX - 2, iY - 1, iX - 2, iY + 1, iCol, bToScreen)
        DSLine(iX + 2, iY - 1, iX + 2, iY + 1, iCol, bToScreen)
        DSLine(iX - 1, iY - 1, iX - 1, iY + 1, iCol, bToScreen)
        DSLine(iX + 1, iY - 1, iX + 1, iY + 1, iCol, bToScreen)
    End Sub

    Private Sub DrawVine(ByVal iX As Long, ByVal iY1 As Long, ByVal iY2 As Long, ByVal iCol As System.Drawing.Color, ByVal bToScreen As Boolean)

        Dim iRung As Long
        Dim bSwitch As Boolean

        bSwitch = False
        For iRung = iY2 + 3 To iY1 Step 3
            bSwitch = Not bSwitch
            DSLine(iX, iRung, iX, iRung - 3, iCol, bToScreen)
            If bSwitch Then
                DSLine(iX - 1, iRung, iX - 1, iRung - 3, iCol, bToScreen)
            Else
                DSLine(iX + 1, iRung, iX + 1, iRung - 3, iCol, bToScreen)
            End If
        Next

    End Sub

    Private Sub DrawLadder(ByVal iX As Long, ByVal iY1 As Long, ByVal iY2 As Long, ByVal iCol As System.Drawing.Color, ByVal bToScreen As Boolean)

        DSLine(iX - 6, iY1, iX - 6, iY2, iCol, bToScreen)
        DSLine(iX + 6, iY1, iX + 6, iY2, iCol, bToScreen)

        Dim iRung As Long
        For iRung = iY2 + 3 To iY1 - 3 Step 5
            DSLine(iX - 6, iRung, iX + 6, iRung, iCol, bToScreen)
        Next

    End Sub


    'Private Sub ProcessDonut(ByVal iX1 As Long, ByVal iY1 As Long, ByVal iZ1 As Long, ByVal iNum As Long, ByVal bFile As Boolean)
    '    Dim iLen As Single
    '    Dim iLoop As Long
    '    Dim sX1 As Single, sX2 As Single, sY1 As Single, sY2 As Single

    '    If bFile Then
    '        msBuff = ""

    '        'TOP
    '        AddCube(iX1 - 1, iY1 - 1, iZ1 - 1, iX1 + 1, iY1 - 3, iZ1, 0.55, 0.55)
    '        'BOTTOM
    '        AddCube(iX1 - 1, iY1 + 3, iZ1 - 1, iX1 + 1, iY1 + 1, iZ1, 0.55, 0.55)
    '        'LEFT
    '        AddCube(iX1 - 3, iY1 + 1, iZ1 - 1, iX1 - 1, iY1 - 1, iZ1, 0.55, 0.55)
    '        'RIGHT
    '        AddCube(iX1 + 1, iY1 + 1, iZ1 - 1, iX1 + 3, iY1 - 1, iZ1, 0.55, 0.55)

    '        OutputLine("D", iX1, iY1, iZ1, iNum, 0, 0, 0, 0, 0, 0, "")
    '        OutputBuffer()
    '    End If

    '    'TOP & BOTTOM
    '    DSLine(iX1, iY1 - 2, iX1 + 1, iY1 - 2, Color.Red)
    '    DSLine(iX1, iY1 - 1, iX1 + 1, iY1 - 1, Color.Red)
    '    DSLine(iX1, iY1 + 2, iX1 + 1, iY1 + 2, Color.Red)
    '    DSLine(iX1, iY1 + 3, iX1 + 1, iY1 + 3, Color.Red)

    '    'LEFT AND RIGHT
    '    DSLine(iX1 - 2, iY1, iX1 - 2, iY1 + 1, Color.Red)
    '    DSLine(iX1 - 1, iY1, iX1 - 1, iY1 + 1, Color.Red)
    '    DSLine(iX1 + 2, iY1, iX1 + 2, iY1 + 1, Color.Red)
    '    DSLine(iX1 + 3, iY1, iX1 + 3, iY1 + 1, Color.Red)

    'End Sub

    Private Sub DSLine(ByVal iX1 As Long, ByVal iY1 As Long, ByVal iX2 As Long, ByVal iY2 As Long, ByVal iCol As Color, ByVal bToScreen As Boolean)
        Dim g As Graphics
        Dim p As New Pen(iCol)

        iX1 = iX1 * 2 + 5 : iX2 = iX2 * 2 + 5
        iY1 = iY1 * 2 + 5 : iY2 = iY2 * 2 + 5
        p.Width = 2
        If bToScreen Then
            g = picLevel.CreateGraphics
        Else
            g = Graphics.FromImage(miLevel)
        End If
        g.DrawLine(p, iX1, 650 - iY1, iX2, 650 - iY2)
        g.Dispose()
    End Sub


    Private Sub MenuLoad_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuLoad.Click
        Dim LD As New LoadDialog()
        Dim sFile As String

        miSelectedItem = -1
        LD.Description = "Load Level File"
        LD.Extensions = "LVL"
        LD.Directory = My.Settings.LevelSourceDirectory
        LD.ShowDialog()
        sFile = LD.ReturnFile

        If Len(sFile) > 0 Then
            mLOs = 0
            mLRs = 0

            picLevel.CreateGraphics.Clear(Color.Black)
            Dim sAll As String
            FileOpen(1, Path.Combine(My.Settings.LevelSourceDirectory, sFile), OpenMode.Input, OpenAccess.Read)
            sAll = InputString(1, LOF(1))

            Dim sLines() As String
            Dim sLine As String
            Dim iLine As Long
            sLines = Split(sAll, vbCrLf)
            For iLine = 0 To UBound(sLines)
                sLine = sLines(iLine)
                If Microsoft.VisualBasic.Left(sLine, 2) = "O " Then
                    mLO(mLOs).ConvertFromString(Mid(sLine, 3))
                    mLO(mLOs).DestroyIfInvalid()
                    mLOs = mLOs + 1
                End If
                If Microsoft.VisualBasic.Left(sLine, 2) = "R " Then
                    mLR(mLRs).ConvertFromString(Mid(sLine, 3))
                    mLRs = mLRs + 1
                End If
            Next

            msFile = Microsoft.VisualBasic.Left(sFile, InStr(sFile, ".") - 1)
            FileClose(1)

            SetCaption()
        End If

    End Sub

    Private Sub ResetButtons(ByVal bLoadGraphics As Boolean)
        If bLoadGraphics Then
            ' TODO: Embed these instead of loading from file system
            cmdSelect.Image = Image.FromFile(Path.Combine(My.Settings.ApplicationResourceDirectory, "Select.bmp"))
            cmdPlatform.Image = Image.FromFile(Path.Combine(My.Settings.ApplicationResourceDirectory, "Platform.bmp"))
            cmdDonut.Image = Image.FromFile(Path.Combine(My.Settings.ApplicationResourceDirectory, "Donut.bmp"))
            cmdVine.Image = Image.FromFile(Path.Combine(My.Settings.ApplicationResourceDirectory, "Vine.bmp"))
            cmdLadder.Image = Image.FromFile(Path.Combine(My.Settings.ApplicationResourceDirectory, "Ladder.bmp"))
            cmdDelete.Image = Image.FromFile(Path.Combine(My.Settings.ApplicationResourceDirectory, "Trash.bmp"))
            cmdEdit.Image = Image.FromFile(Path.Combine(My.Settings.ApplicationResourceDirectory, "Edit.bmp"))
            cmdArbitrary.Image = Image.FromFile(Path.Combine(My.Settings.ApplicationResourceDirectory, "Picture.bmp"))
            cmdWall.Image = Image.FromFile(Path.Combine(My.Settings.ApplicationResourceDirectory, "Wall.bmp"))
            cmdSaveRender.Image = Image.FromFile(Path.Combine(My.Settings.ApplicationResourceDirectory, "SaveRender.bmp"))
        End If

        cmdSelect.FlatStyle = FlatStyle.Standard
        cmdPlatform.FlatStyle = FlatStyle.Standard
        cmdDonut.FlatStyle = FlatStyle.Standard
        cmdVine.FlatStyle = FlatStyle.Standard
        cmdLadder.FlatStyle = FlatStyle.Standard
        cmdArbitrary.FlatStyle = FlatStyle.Standard
        cmdWall.FlatStyle = FlatStyle.Standard
    End Sub

    Private Sub MenuExit_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuExit.Click
        Me.Close()
    End Sub

    Private Sub cmdSaveRender_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdSaveRender.Click
        If msFile = "untitled" Then
            Dim sFile As String
            sFile = InputBox("File name?", "Level Editor", msFile)
            If sFile = "" Then Exit Sub
            msFile = sFile
            SaveFile()
        Else
            SaveFile()
        End If
        SetCaption()

        Me.Cursor = Cursors.WaitCursor
        RenderLevel(True)
        Me.Cursor = Cursors.Arrow
    End Sub

    Private Sub MenuRender_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuRender.Click
        RenderLevel(True)
    End Sub

    Private Sub MenuSaveAs_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuSaveAs.Click
        Dim sFile As String
        sFile = InputBox("File name?", "Level Editor", msFile)
        If sFile = "" Then Exit Sub
        msFile = sFile
        SetCaption()
        SaveFile()
    End Sub

    Private Sub MenuSave_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuSave.Click
        If msFile = "untitled" Then
            Dim sFile As String
            sFile = InputBox("File name?", "Level Editor", msFile)
            If sFile = "" Then Exit Sub
            msFile = sFile
            SaveFile()
        Else
            SaveFile()
        End If
        SetCaption()
    End Sub

    Private Sub SaveFile()
        Dim sAll As String = Nothing
        Dim sLine As String
        Dim iLoop As Long

        FileOpen(3, Path.Combine(My.Settings.LevelSourceDirectory, msFile & ".LVL"), OpenMode.Output)

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

    Private Sub MenuResources_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MenuResources.Click
        Dim er As New EditResources()
        er.MainForm = Me
        er.ShowDialog()
    End Sub

    Private Sub timRepaint_Elapsed(ByVal sender As System.Object, ByVal e As System.Timers.ElapsedEventArgs) Handles timRepaint.Elapsed
        timRepaint.Enabled = False
        RenderLevel(False)
    End Sub

    Private Sub picLevel_Paint(ByVal sender As Object, ByVal e As System.Windows.Forms.PaintEventArgs) Handles picLevel.Paint
        timRepaint.Enabled = True
    End Sub

    Private Function CollideObject(ByVal iX As Long, ByVal iY As Long) As Long
        Dim iLoop As Long
        Dim sType As String
        Dim iCollide(100) As Long
        Dim iCollides As Long

        For iLoop = 0 To mLOs - 1
            sType = mLO(iLoop).Type

            If sType = "PLATFORM" Then
                If PointInQuad(iX, iY, mLO(iLoop).V(1).X, mLO(iLoop).V(1).Y, mLO(iLoop).V(2).X, mLO(iLoop).V(2).Y, mLO(iLoop).V(4).X, mLO(iLoop).V(4).Y, mLO(iLoop).V(3).X, mLO(iLoop).V(3).Y) Then
                    iCollide(iCollides) = iLoop
                    iCollides = iCollides + 1
                End If
            End If
            If sType = "WALL" Then
                If PointInQuad(iX, iY, mLO(iLoop).V(1).X, mLO(iLoop).V(1).Y, mLO(iLoop).V(2).X, mLO(iLoop).V(2).Y, mLO(iLoop).V(4).X, mLO(iLoop).V(4).Y, mLO(iLoop).V(3).X, mLO(iLoop).V(3).Y) Then
                    iCollide(iCollides) = iLoop
                    iCollides = iCollides + 1
                End If
            End If
            If sType = "LADDER" Then
                If PointInQuad(iX, iY, mLO(iLoop).V(1).X - 6, mLO(iLoop).V(1).Y, mLO(iLoop).V(1).X + 6, mLO(iLoop).V(1).Y, mLO(iLoop).V(1).X + 6, mLO(iLoop).V(2).Y, mLO(iLoop).V(1).X - 6, mLO(iLoop).V(2).Y) Then
                    iCollide(iCollides) = iLoop
                    iCollides = iCollides + 1
                End If
            End If
            If sType = "VINE" Then
                If PointInQuad(iX, iY, mLO(iLoop).V(1).X - 2, mLO(iLoop).V(1).Y, mLO(iLoop).V(1).X + 2, mLO(iLoop).V(1).Y, mLO(iLoop).V(1).X + 2, mLO(iLoop).V(2).Y, mLO(iLoop).V(1).X - 2, mLO(iLoop).V(2).Y) Then
                    iCollide(iCollides) = iLoop
                    iCollides = iCollides + 1
                End If
            End If
            If sType = "ARBITRARY" Then
                If cbShowPictures.Checked Then
                    If PointInQuad(iX, iY, mLO(iLoop).V(1).X, mLO(iLoop).V(1).Y, mLO(iLoop).V(2).X, mLO(iLoop).V(2).Y, mLO(iLoop).V(4).X, mLO(iLoop).V(4).Y, mLO(iLoop).V(3).X, mLO(iLoop).V(3).Y) Then
                        iCollide(iCollides) = iLoop
                        iCollides = iCollides + 1
                    End If
                End If
            End If
            If sType = "DONUT" Then
                If PointInQuad(iX, iY, mLO(iLoop).V(1).X - 2, mLO(iLoop).V(1).Y + 2, mLO(iLoop).V(1).X + 2, mLO(iLoop).V(1).Y + 2, mLO(iLoop).V(1).X + 2, mLO(iLoop).V(1).Y - 2, mLO(iLoop).V(1).X - 2, mLO(iLoop).V(1).Y - 2) Then
                    iCollide(iCollides) = iLoop
                    iCollides = iCollides + 1
                End If
            End If
        Next

        If iCollides = 0 Then
            CollideObject = -1
        ElseIf iCollides = 1 Then
            CollideObject = iCollide(0)
        Else
            Dim bTakeNext As Boolean
            CollideObject = iCollide(0)
            For iLoop = 0 To iCollides - 1
                If bTakeNext Then
                    CollideObject = iCollide(iLoop)
                    bTakeNext = False
                ElseIf iCollide(iLoop) = miSelectedItem Then
                    bTakeNext = True
                End If
            Next
        End If

    End Function

    Private Function CollideSBox(ByVal iX As Single, ByVal iY As Single) As Long
        Dim iLoop As Long
        Dim iDist As Long
        CollideSBox = -1
        If miSelectedItem = -1 Then Exit Function
        For iDist = 0 To 2
            For iLoop = 0 To miSBoxes - 1
                If iX + iDist > miSBX(iLoop) And iX - iDist < miSBX(iLoop) And iY + iDist > miSBY(iLoop) And iY - iDist < miSBY(iLoop) Then
                    CollideSBox = iLoop
                    Exit Function
                End If
            Next
        Next
    End Function

    Private Sub picLevel_MouseDown(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles picLevel.MouseDown
        If e.Button <> MouseButtons.Left Then Exit Sub

        miSSBox = -1
        If msTool = "SELECT" Then
            Dim iTemp As Long
            iTemp = CollideSBox(ToRealX(e.X), ToRealY(e.Y))
            If iTemp <> -1 Then
                mbMouse = True
                mnMouseX = e.X
                mnMouseY = e.Y
                miSSBox = iTemp
                Exit Sub
            End If

            miSelectedItem = CollideObject(ToRealX(e.X), ToRealY(e.Y))
            RenderLevel(False)
        Else
            mbMouse = True
            mnMouseX = e.X
            mnMouseY = e.Y
        End If

    End Sub

    Private Sub DragObject(ByVal LO As LevelObject, ByVal iX As Long, ByVal iY As Long)
        Dim iDifX As Long
        Dim iDifY As Long

        iDifX = CLng(ToRealX(iX)) - CLng(ToRealX(mnMouseX))
        iDifY = CLng(ToRealY(iY)) - CLng(ToRealY(mnMouseY))

        If LO.Type = "PLATFORM" Then
            If miSSBox = 0 Then
                LO.V(1).X = LO.V(1).X + iDifX
                LO.V(3).X = LO.V(3).X + iDifX
                LO.V(1).Y = LO.V(1).Y + iDifY
                LO.V(3).Y = LO.V(3).Y + iDifY
            ElseIf miSSBox = 1 Then
                LO.V(2).X = LO.V(2).X + iDifX
                LO.V(4).X = LO.V(4).X + iDifX
                LO.V(2).Y = LO.V(2).Y + iDifY
                LO.V(4).Y = LO.V(4).Y + iDifY
            ElseIf miSSBox = 2 Then
                LO.V(3).X = LO.V(3).X + iDifX
                LO.V(3).Y = LO.V(3).Y + iDifY
            ElseIf miSSBox = 3 Then
                LO.V(4).X = LO.V(4).X + iDifX
                LO.V(4).Y = LO.V(4).Y + iDifY
            ElseIf miSSBox = 4 Then
                LO.V(1).X = LO.V(1).X + iDifX
                LO.V(1).Y = LO.V(1).Y + iDifY
                LO.V(2).X = LO.V(2).X + iDifX
                LO.V(2).Y = LO.V(2).Y + iDifY
                LO.V(3).X = LO.V(3).X + iDifX
                LO.V(3).Y = LO.V(3).Y + iDifY
                LO.V(4).X = LO.V(4).X + iDifX
                LO.V(4).Y = LO.V(4).Y + iDifY
            End If
        End If

        If LO.Type = "WALL" Then
            If miSSBox = 0 Then
                If LO.V(3).X = LO.V(1).X Then LO.V(3).X = LO.V(3).X + iDifX
                LO.V(1).X = LO.V(1).X + iDifX
                LO.V(1).Y = LO.V(1).Y + iDifY
            ElseIf miSSBox = 1 Then
                If LO.V(4).X = LO.V(2).X Then LO.V(4).X = LO.V(4).X + iDifX
                LO.V(2).X = LO.V(2).X + iDifX
                LO.V(2).Y = LO.V(2).Y + iDifY
            ElseIf miSSBox = 2 Then
                LO.V(3).X = LO.V(3).X + iDifX
                LO.V(3).Y = LO.V(3).Y + iDifY
            ElseIf miSSBox = 3 Then
                LO.V(4).X = LO.V(4).X + iDifX
                LO.V(4).Y = LO.V(4).Y + iDifY
            ElseIf miSSBox = 4 Then
                LO.V(1).X = LO.V(1).X + iDifX
                LO.V(1).Y = LO.V(1).Y + iDifY
                LO.V(2).X = LO.V(2).X + iDifX
                LO.V(2).Y = LO.V(2).Y + iDifY
                LO.V(3).X = LO.V(3).X + iDifX
                LO.V(3).Y = LO.V(3).Y + iDifY
                LO.V(4).X = LO.V(4).X + iDifX
                LO.V(4).Y = LO.V(4).Y + iDifY
            End If
        End If

        If LO.Type = "LADDER" Then
            If miSSBox = 0 Then
                LO.V(1).Y = LO.V(1).Y + iDifY
            ElseIf miSSBox = 2 Then
                LO.V(1).X = LO.V(1).X + iDifX
                LO.V(1).Y = LO.V(1).Y + iDifY
                LO.V(2).Y = LO.V(2).Y + iDifY
            ElseIf miSSBox = 1 Then
                LO.V(2).Y = LO.V(2).Y + iDifY
            End If
        End If

        If LO.Type = "VINE" Then
            If miSSBox = 0 Then
                LO.V(1).Y = LO.V(1).Y + iDifY
            ElseIf miSSBox = 2 Then
                LO.V(1).X = LO.V(1).X + iDifX
                LO.V(1).Y = LO.V(1).Y + iDifY
                LO.V(2).Y = LO.V(2).Y + iDifY
            ElseIf miSSBox = 1 Then
                LO.V(2).Y = LO.V(2).Y + iDifY
            End If
        End If

        If LO.Type = "ARBITRARY" Then
            If miSSBox = 0 Then
                LO.V(1).X = LO.V(1).X + iDifX
                LO.V(1).Y = LO.V(1).Y + iDifY
            ElseIf miSSBox = 1 Then
                LO.V(2).X = LO.V(2).X + iDifX
                LO.V(2).Y = LO.V(2).Y + iDifY
            ElseIf miSSBox = 2 Then
                LO.V(3).X = LO.V(3).X + iDifX
                LO.V(3).Y = LO.V(3).Y + iDifY
            ElseIf miSSBox = 3 Then
                LO.V(4).X = LO.V(4).X + iDifX
                LO.V(4).Y = LO.V(4).Y + iDifY
            ElseIf miSSBox = 4 Then
                LO.V(1).X = LO.V(1).X + iDifX
                LO.V(1).Y = LO.V(1).Y + iDifY
                LO.V(2).X = LO.V(2).X + iDifX
                LO.V(2).Y = LO.V(2).Y + iDifY
                LO.V(3).X = LO.V(3).X + iDifX
                LO.V(3).Y = LO.V(3).Y + iDifY
                LO.V(4).X = LO.V(4).X + iDifX
                LO.V(4).Y = LO.V(4).Y + iDifY
            End If
        End If

        If LO.Type = "DONUT" Then
            If miSSBox = 0 Then
                LO.V(1).Y = LO.V(1).Y + iDifY
                LO.V(1).X = LO.V(1).X + iDifX
            End If
        End If

        UpdateHints(LO, False)

    End Sub

    Private Sub picLevel_MouseMove(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles picLevel.MouseMove
        Dim g As Graphics
        Dim LO As LevelObject = New LevelObject()
        Dim sTemp As String

        ReDim LO.V(8)

        If mbMouse Then
            g = picLevel.CreateGraphics
            g.DrawImage(miLevel, 0, 0)
            g.Dispose()

            If msTool = "SELECT" Then
                sTemp = mLO(miSelectedItem).ConvertToString
                LO.ConvertFromString(sTemp)
                DragObject(LO, e.X, e.Y)
                ProcessLO(LO, False, True, True)
            End If
            If msTool = "PLATFORM" Then
                DefaultPlatform(LO, ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                ProcessLO(LO, False, True, True)
            End If
            If msTool = "WALL" Then
                DefaultWall(LO, ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                ProcessLO(LO, False, True, True)
            End If
            If msTool = "LADDER" Then
                DefaultLadder(LO, ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                ProcessLO(LO, False, True, True)
            End If
            If msTool = "VINE" Then
                DefaultVine(LO, ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                ProcessLO(LO, False, True, True)
            End If
            If msTool = "ARBITRARY" Then
                DefaultArbitrary(LO, ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                ProcessLO(LO, False, True, True)
            End If
            If msTool = "DONUT" Then
                DefaultDonut(LO, ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                ProcessLO(LO, False, True, True)
            End If

        End If

    End Sub

    Private Sub picLevel_MouseUp(ByVal sender As Object, ByVal e As System.Windows.Forms.MouseEventArgs) Handles picLevel.MouseUp
        If mbMouse Then
            mbMouse = False
            If msTool = "SELECT" Then
                DragObject(mLO(miSelectedItem), e.X, e.Y)
            End If
            If msTool = "PLATFORM" And Math.Abs(mnMouseX - e.X) > 5 Then
                DefaultPlatform(mLO(mLOs), ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                miSelectedItem = mLOs
                mLOs = mLOs + 1
            End If
            If msTool = "WALL" And Math.Abs(mnMouseX - e.X) > 5 Then
                DefaultWall(mLO(mLOs), ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                miSelectedItem = mLOs
                mLOs = mLOs + 1
            End If
            If msTool = "LADDER" And mnMouseY < e.Y - 6 Then
                DefaultLadder(mLO(mLOs), ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                miSelectedItem = mLOs
                mLOs = mLOs + 1
            End If
            If msTool = "VINE" And mnMouseY < e.Y - 6 Then
                DefaultVine(mLO(mLOs), ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                miSelectedItem = mLOs
                mLOs = mLOs + 1
            End If
            If msTool = "ARBITRARY" And (mnMouseX <> e.X Or mnMouseY <> e.Y) Then
                DefaultArbitrary(mLO(mLOs), ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                miSelectedItem = mLOs
                mLOs = mLOs + 1
            End If
            If msTool = "DONUT" Then
                DefaultDonut(mLO(mLOs), ToRealX(mnMouseX), ToRealY(mnMouseY), ToRealX(e.X), ToRealY(e.Y))
                miSelectedItem = mLOs
                mLOs = mLOs + 1
            End If
            RenderLevel(False)
        End If
    End Sub

    Private Sub cmdDelete_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdDelete.Click
        DeleteSelectedItem()
    End Sub

    Private Sub DeleteSelectedItem()
        Dim sTemp As String
        If miSelectedItem <> -1 Then
            sTemp = mLO(mLOs - 1).ConvertToString
            mLO(miSelectedItem).ConvertFromString(sTemp)
            miSelectedItem = -1
            mLOs = mLOs - 1
            RenderLevel(False)
        End If
    End Sub

    Private Sub cmdEdit_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdEdit.Click
        Dim EA As EditArbitrary
        Dim EO As EditObject

        If miSelectedItem <> -1 Then
            If mLO(miSelectedItem).Type = "ARBITRARY" Then
                EA = New EditArbitrary()
                EA.MainForm = Me
                EA.Item = miSelectedItem
                EA.ShowDialog()
            Else
                EO = New EditObject()
                EO.MainForm = Me
                EO.Item = miSelectedItem
                EO.ShowDialog()
            End If
        End If
    End Sub

    Private Sub vsZ1_Scroll(ByVal sender As System.Object, ByVal e As System.Windows.Forms.ScrollEventArgs) Handles vsZ1.Scroll
        If miSelectedItem <> -1 Then
            If mLO(miSelectedItem).Type = "ARBITRARY" Then
                lblZ1.Text = vsZ1.Value
                mLO(miSelectedItem).V(1).Z = vsZ1.Value
            Else
                lblZ1.Text = vsZ1.Value
                mLO(miSelectedItem).Z1 = vsZ1.Value
            End If
        End If
    End Sub

    Private Sub vsZ2_Scroll(ByVal sender As System.Object, ByVal e As System.Windows.Forms.ScrollEventArgs) Handles vsZ2.Scroll
        If miSelectedItem <> -1 Then
            If mLO(miSelectedItem).Type = "ARBITRARY" Then
                lblZ2.Text = vsZ2.Value
                mLO(miSelectedItem).V(2).Z = vsZ2.Value
            Else
                lblZ2.Text = vsZ2.Value
                mLO(miSelectedItem).Z2 = vsZ2.Value
            End If
        End If
    End Sub

    Private Sub vsZ3_Scroll(ByVal sender As System.Object, ByVal e As System.Windows.Forms.ScrollEventArgs) Handles vsZ3.Scroll
        If miSelectedItem <> -1 Then
            If mLO(miSelectedItem).Type = "ARBITRARY" Then
                lblZ3.Text = vsZ3.Value
                mLO(miSelectedItem).V(3).Z = vsZ3.Value
            End If
        End If
    End Sub

    Private Sub vsZ4_Scroll(ByVal sender As System.Object, ByVal e As System.Windows.Forms.ScrollEventArgs) Handles vsZ4.Scroll
        If miSelectedItem <> -1 Then
            If mLO(miSelectedItem).Type = "ARBITRARY" Then
                lblZ4.Text = vsZ4.Value
                mLO(miSelectedItem).V(4).Z = vsZ4.Value
            End If
        End If
    End Sub

    Private iSaveZ1 As Single, iSaveZ2 As Single, iSaveZ3 As Single, iSaveZ4 As Single

    Private Sub JLForm_KeyUp(ByVal sender As Object, ByVal e As System.Windows.Forms.KeyEventArgs) Handles MyBase.KeyUp
        If e.KeyCode = Keys.Delete Then
            DeleteSelectedItem()
        End If

        If e.KeyCode = Keys.OemCloseBrackets Then
            Dim iTX As Single, iTY As Single
            If miSelectedItem <> -1 Then
                If mLO(miSelectedItem).Type = "WALL" Then
                    iTX = mLO(miSelectedItem).V(4).X
                    iTY = mLO(miSelectedItem).V(4).Y
                    mLO(miSelectedItem).V(4).X = mLO(miSelectedItem).V(3).X
                    mLO(miSelectedItem).V(4).Y = mLO(miSelectedItem).V(3).Y
                    mLO(miSelectedItem).V(3).X = mLO(miSelectedItem).V(1).X
                    mLO(miSelectedItem).V(3).Y = mLO(miSelectedItem).V(1).Y
                    mLO(miSelectedItem).V(1).X = mLO(miSelectedItem).V(2).X
                    mLO(miSelectedItem).V(1).Y = mLO(miSelectedItem).V(2).Y
                    mLO(miSelectedItem).V(2).X = iTX
                    mLO(miSelectedItem).V(2).Y = iTY
                    RenderLevel(False)
                End If
            End If
        End If

        If e.KeyCode = Keys.OemOpenBrackets Then
            Dim iTX As Single, iTY As Single
            If miSelectedItem <> -1 Then
                If mLO(miSelectedItem).Type = "WALL" Then
                    iTX = mLO(miSelectedItem).V(4).X
                    iTY = mLO(miSelectedItem).V(4).Y
                    mLO(miSelectedItem).V(4).X = mLO(miSelectedItem).V(2).X
                    mLO(miSelectedItem).V(4).Y = mLO(miSelectedItem).V(2).Y
                    mLO(miSelectedItem).V(2).X = mLO(miSelectedItem).V(1).X
                    mLO(miSelectedItem).V(2).Y = mLO(miSelectedItem).V(1).Y
                    mLO(miSelectedItem).V(1).X = mLO(miSelectedItem).V(3).X
                    mLO(miSelectedItem).V(1).Y = mLO(miSelectedItem).V(3).Y
                    mLO(miSelectedItem).V(3).X = iTX
                    mLO(miSelectedItem).V(3).Y = iTY
                    RenderLevel(False)
                End If
            End If
        End If
        If e.KeyCode = Keys.OemMinus Then
            If miSelectedItem <> -1 Then
                iSaveZ1 = vsZ1.Value
                iSaveZ2 = vsZ2.Value
                iSaveZ3 = vsZ3.Value
                iSaveZ4 = vsZ4.Value
            End If
        End If
        If e.KeyCode = Keys.Oemplus Then
            If miSelectedItem <> -1 Then
                Try
                    vsZ1.Value = iSaveZ1
                    vsZ2.Value = iSaveZ2
                    vsZ3.Value = iSaveZ3
                    vsZ4.Value = iSaveZ4

                    lblZ1.Text = vsZ1.Value
                    lblZ2.Text = vsZ2.Value

                    If mLO(miSelectedItem).Type = "ARBITRARY" Then
                        lblZ3.Text = vsZ3.Value
                        lblZ4.Text = vsZ4.Value
                        mLO(miSelectedItem).V(1).Z = vsZ1.Value
                        mLO(miSelectedItem).V(2).Z = vsZ2.Value
                        mLO(miSelectedItem).V(3).Z = vsZ3.Value
                        mLO(miSelectedItem).V(4).Z = vsZ4.Value
                    Else
                        mLO(miSelectedItem).Z1 = vsZ1.Value
                        mLO(miSelectedItem).Z2 = vsZ2.Value
                    End If

                Catch

                End Try
            End If
        End If
    End Sub

    Private Sub cbShowPictures_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cbShowPictures.CheckedChanged
        RenderLevel(False)
    End Sub

    Private Sub SettingsMenuItem_Click(sender As Object, e As EventArgs) Handles SettingsMenuItem.Click
        Dim settingsDialog As SettingsDialog = New SettingsDialog()
        settingsDialog.ShowDialog()
    End Sub
End Class