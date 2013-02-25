Imports JumpmanLevelLib

Public Class EditResources
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
    Friend WithEvents lstResources As System.Windows.Forms.ListBox
    Friend WithEvents cmdAddBIN As System.Windows.Forms.Button
    Friend WithEvents AddMID As System.Windows.Forms.Button
    Friend WithEvents AddBMP As System.Windows.Forms.Button
    Friend WithEvents DoClose As System.Windows.Forms.Button
    Friend WithEvents EditResource As System.Windows.Forms.Button
    Friend WithEvents AddPNG As System.Windows.Forms.Button
    Friend WithEvents AddJPG As System.Windows.Forms.Button
    Friend WithEvents AddMSH As System.Windows.Forms.Button
    Friend WithEvents cmdDelete As System.Windows.Forms.Button
    Friend WithEvents cmdMoveUp As System.Windows.Forms.Button
    Friend WithEvents cmdMoveDown As System.Windows.Forms.Button
    Friend WithEvents cmdAddSound As System.Windows.Forms.Button
    Friend WithEvents cmdIntro As System.Windows.Forms.Button
    <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
        Me.lstResources = New System.Windows.Forms.ListBox()
        Me.cmdAddBIN = New System.Windows.Forms.Button()
        Me.DoClose = New System.Windows.Forms.Button()
        Me.EditResource = New System.Windows.Forms.Button()
        Me.AddMID = New System.Windows.Forms.Button()
        Me.AddBMP = New System.Windows.Forms.Button()
        Me.AddPNG = New System.Windows.Forms.Button()
        Me.AddJPG = New System.Windows.Forms.Button()
        Me.AddMSH = New System.Windows.Forms.Button()
        Me.cmdDelete = New System.Windows.Forms.Button()
        Me.cmdMoveUp = New System.Windows.Forms.Button()
        Me.cmdMoveDown = New System.Windows.Forms.Button()
        Me.cmdAddSound = New System.Windows.Forms.Button()
        Me.cmdIntro = New System.Windows.Forms.Button()
        Me.SuspendLayout()
        '
        'lstResources
        '
        Me.lstResources.Items.AddRange(New Object() {""})
        Me.lstResources.Location = New System.Drawing.Point(8, 8)
        Me.lstResources.Name = "lstResources"
        Me.lstResources.Size = New System.Drawing.Size(312, 381)
        Me.lstResources.TabIndex = 0
        '
        'cmdAddBIN
        '
        Me.cmdAddBIN.Location = New System.Drawing.Point(328, 8)
        Me.cmdAddBIN.Name = "cmdAddBIN"
        Me.cmdAddBIN.Size = New System.Drawing.Size(80, 20)
        Me.cmdAddBIN.TabIndex = 1
        Me.cmdAddBIN.Text = "Add Script"
        '
        'DoClose
        '
        Me.DoClose.Location = New System.Drawing.Point(328, 356)
        Me.DoClose.Name = "DoClose"
        Me.DoClose.Size = New System.Drawing.Size(80, 32)
        Me.DoClose.TabIndex = 3
        Me.DoClose.Text = "Close"
        '
        'EditResource
        '
        Me.EditResource.Location = New System.Drawing.Point(328, 188)
        Me.EditResource.Name = "EditResource"
        Me.EditResource.Size = New System.Drawing.Size(80, 20)
        Me.EditResource.TabIndex = 4
        Me.EditResource.Text = "Edit Options"
        '
        'AddMID
        '
        Me.AddMID.Location = New System.Drawing.Point(328, 32)
        Me.AddMID.Name = "AddMID"
        Me.AddMID.Size = New System.Drawing.Size(80, 20)
        Me.AddMID.TabIndex = 5
        Me.AddMID.Text = "Add Music"
        '
        'AddBMP
        '
        Me.AddBMP.Location = New System.Drawing.Point(328, 56)
        Me.AddBMP.Name = "AddBMP"
        Me.AddBMP.Size = New System.Drawing.Size(80, 20)
        Me.AddBMP.TabIndex = 6
        Me.AddBMP.Text = "Add BMP"
        '
        'AddPNG
        '
        Me.AddPNG.Location = New System.Drawing.Point(328, 80)
        Me.AddPNG.Name = "AddPNG"
        Me.AddPNG.Size = New System.Drawing.Size(80, 20)
        Me.AddPNG.TabIndex = 7
        Me.AddPNG.Text = "Add PNG"
        '
        'AddJPG
        '
        Me.AddJPG.Location = New System.Drawing.Point(328, 104)
        Me.AddJPG.Name = "AddJPG"
        Me.AddJPG.Size = New System.Drawing.Size(80, 20)
        Me.AddJPG.TabIndex = 8
        Me.AddJPG.Text = "Add JPG"
        '
        'AddMSH
        '
        Me.AddMSH.Location = New System.Drawing.Point(328, 128)
        Me.AddMSH.Name = "AddMSH"
        Me.AddMSH.Size = New System.Drawing.Size(80, 16)
        Me.AddMSH.TabIndex = 9
        Me.AddMSH.Text = "Add Mesh"
        '
        'cmdDelete
        '
        Me.cmdDelete.Location = New System.Drawing.Point(328, 212)
        Me.cmdDelete.Name = "cmdDelete"
        Me.cmdDelete.Size = New System.Drawing.Size(80, 20)
        Me.cmdDelete.TabIndex = 10
        Me.cmdDelete.Text = "Delete"
        '
        'cmdMoveUp
        '
        Me.cmdMoveUp.Location = New System.Drawing.Point(328, 248)
        Me.cmdMoveUp.Name = "cmdMoveUp"
        Me.cmdMoveUp.Size = New System.Drawing.Size(80, 20)
        Me.cmdMoveUp.TabIndex = 11
        Me.cmdMoveUp.Text = "Move Up"
        '
        'cmdMoveDown
        '
        Me.cmdMoveDown.Location = New System.Drawing.Point(328, 272)
        Me.cmdMoveDown.Name = "cmdMoveDown"
        Me.cmdMoveDown.Size = New System.Drawing.Size(80, 20)
        Me.cmdMoveDown.TabIndex = 12
        Me.cmdMoveDown.Text = "Move Down"
        '
        'cmdAddSound
        '
        Me.cmdAddSound.Location = New System.Drawing.Point(328, 148)
        Me.cmdAddSound.Name = "cmdAddSound"
        Me.cmdAddSound.Size = New System.Drawing.Size(80, 16)
        Me.cmdAddSound.TabIndex = 13
        Me.cmdAddSound.Text = "Add Sound"
        '
        'cmdIntro
        '
        Me.cmdIntro.Location = New System.Drawing.Point(328, 308)
        Me.cmdIntro.Name = "cmdIntro"
        Me.cmdIntro.Size = New System.Drawing.Size(80, 20)
        Me.cmdIntro.TabIndex = 14
        Me.cmdIntro.Text = "Intro Length"
        '
        'EditResources
        '
        Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
        Me.ClientSize = New System.Drawing.Size(416, 393)
        Me.Controls.AddRange(New System.Windows.Forms.Control() {Me.cmdIntro, Me.cmdAddSound, Me.cmdMoveDown, Me.cmdMoveUp, Me.cmdDelete, Me.AddMSH, Me.AddJPG, Me.AddPNG, Me.AddBMP, Me.AddMID, Me.EditResource, Me.DoClose, Me.cmdAddBIN, Me.lstResources})
        Me.KeyPreview = True
        Me.MaximizeBox = False
        Me.MinimizeBox = False
        Me.Name = "EditResources"
        Me.SizeGripStyle = System.Windows.Forms.SizeGripStyle.Hide
        Me.Text = "Edit Resources"
        Me.ResumeLayout(False)

    End Sub

#End Region

    Public MainForm As JLForm

    Private Sub EditResources_Activated(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Activated
        ResetList()
    End Sub

    Sub ResetList()
        lstResources.Items.Clear()

        Dim iLoop As Long
        Dim iData As Long
        Dim sName As String
        Dim iTexture As Long
        Dim iSounds As Long

        iTexture = 0
        iSounds = 0
        For iLoop = 0 To MainForm.mLRs - 1
            sName = ""
            sName = sName & MainForm.mLR(iLoop).FileName & " "
            iData = MainForm.mLR(iLoop).ResourceData
            If MainForm.mLR(iLoop).ResourceType = JMResourceType.BIN Then
                If iData = 0 Then
                    iData = 1
                    MainForm.mLR(iLoop).ResourceData = iData
                End If
                If iData = 1 Then sName = sName & " - Level Script"
                If iData = 2 Then sName = sName & " - Object Script"
            ElseIf MainForm.mLR(iLoop).ResourceType = JMResourceType.BMP Then
                If iData = 0 Then sName = sName & " - Texture " & iTexture & " (Opaque BMP)"
                If iData = 1 Then sName = sName & " - Texture " & iTexture & " (Transparent BMP)"
                iTexture = iTexture + 1
            ElseIf MainForm.mLR(iLoop).ResourceType = JMResourceType.JPG Then
                sName = sName & " - Texture " & iTexture & " (JPG)"
                iTexture = iTexture + 1
            ElseIf MainForm.mLR(iLoop).ResourceType = JMResourceType.WAV Then
                sName = sName & " - Sound " & iSounds & " (WAV)"
                iSounds = iSounds + 1
            ElseIf MainForm.mLR(iLoop).ResourceType = JMResourceType.MID Then
                If iData = 0 Then
                    iData = 1
                    MainForm.mLR(iLoop).ResourceData = iData
                End If
                If iData = 1 Then sName = sName & " - Background Music"
                If iData = 2 Then sName = sName & " - Death Music"
                If iData = 3 Then sName = sName & " - Level Clear Music"
            ElseIf MainForm.mLR(iLoop).ResourceType = JMResourceType.MSH Then
                sName = sName & " - mesh file (no options)"
            ElseIf MainForm.mLR(iLoop).ResourceType = JMResourceType.PNG Then
                sName = sName & " - Texture " & iTexture & " (PNG)"
                iTexture = iTexture + 1
            End If
            lstResources.Items.Add(sName)
        Next
    End Sub

    Private Sub DoClose_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles DoClose.Click
        Me.Close()
    End Sub

    Private Sub AddItem(ByVal sExt As String, ByVal sDescription As String)
        Dim ld As New LoadDialog()
        ld.Description = sDescription
        If sExt = "MID" Or sExt = "WAV" Then
            ld.Directory = My.Settings.SoundResourceDirectory
        Else
            ld.Directory = My.Settings.ContentResourceDirectory
        End If

        ld.Extensions = sExt
        ld.AllowMultiple = True

        ld.ShowDialog()

        Dim sFiles As String
        Dim iFile As Long
        Dim sFile As String
        sFiles = ld.ReturnFile

        Dim sParts() As String

        If Len(sFiles) > 0 Then
            sParts = Split(sFiles, "~")
            For iFile = 0 To UBound(sParts)
                sFile = sParts(iFile)
                sFile = Microsoft.VisualBasic.Left(sFile, Len(sFile) - 4)
                sFile = Microsoft.VisualBasic.Left(sFile, 30)
                If sExt = "MID" Then
                    MainForm.mLR(MainForm.mLRs).ResourceType = JMResourceType.MID
                ElseIf sExt = "MSH" Then
                    MainForm.mLR(MainForm.mLRs).ResourceType = JMResourceType.MSH
                ElseIf sExt = "PNG" Then
                    MainForm.mLR(MainForm.mLRs).ResourceType = JMResourceType.PNG
                ElseIf sExt = "JPG" Then
                    MainForm.mLR(MainForm.mLRs).ResourceType = JMResourceType.JPG
                ElseIf sExt = "BMP" Then
                    MainForm.mLR(MainForm.mLRs).ResourceType = JMResourceType.BMP
                ElseIf sExt = "BIN" Then
                    MainForm.mLR(MainForm.mLRs).ResourceType = JMResourceType.BIN
                ElseIf sExt = "WAV" Then
                    MainForm.mLR(MainForm.mLRs).ResourceType = JMResourceType.WAV
                End If
                MainForm.mLR(MainForm.mLRs).FileName = sFile
                MainForm.mLR(MainForm.mLRs).ResourceData = 0
                MainForm.mLRs = MainForm.mLRs + 1
            Next
            ResetList()
        End If
    End Sub

    Private Sub cmdAddBIN_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdAddBIN.Click
        AddItem("BIN", "Add Script")
    End Sub

    Private Sub AddMID_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles AddMID.Click
        AddItem("MID", "Add MIDI file")
    End Sub

    Private Sub AddBMP_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles AddBMP.Click
        AddItem("BMP", "Add BMP")
    End Sub

    Private Sub AddPNG_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles AddPNG.Click
        AddItem("PNG", "Add PNG")
    End Sub

    Private Sub AddJPG_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles AddJPG.Click
        AddItem("JPG", "Add JPG")
    End Sub

    Private Sub AddMSH_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles AddMSH.Click
        AddItem("MSH", "Add Mesh")
    End Sub

    Private Sub EditResource_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles EditResource.Click
        Dim iLr As Long
        Dim iType As JMResourceType

        iLr = lstResources.SelectedIndex
        If iLr < 0 Or iLr > MainForm.mLRs - 1 Then Exit Sub

        iType = MainForm.mLR(iLr).ResourceType

        Dim CI As New ChooseItem()
        CI.Description = "Choose Resource Type"
        CI.Selected = MainForm.mLR(iLr).ResourceData

        If iType = JMResourceType.BIN Then
            CI.Choices = "Level Script,Object Script"
            CI.Values = "1,2"
        ElseIf iType = JMResourceType.BMP Then
            CI.Choices = "Opaque,Transparent"
            CI.Values = "0,1"
        ElseIf iType = JMResourceType.PNG Then
            Exit Sub
        ElseIf iType = JMResourceType.MSH Then
            Exit Sub
        ElseIf iType = JMResourceType.JPG Then
            Exit Sub
        ElseIf iType = JMResourceType.WAV Then
            Exit Sub
        ElseIf iType = JMResourceType.MID Then
            CI.Choices = "Level Music,Death Music,Win Music"
            CI.Values = "1,2,3"
        End If

        CI.ShowDialog()
        MainForm.mLR(iLr).ResourceData = CI.Selected

        ResetList()

    End Sub

    Private Sub cmdDelete_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdDelete.Click
        DeleteSelectedItem()
    End Sub

    Private Sub cmdIntro_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdIntro.Click
        Dim iItem As Long
        Dim iVal As Long
        If lstResources.SelectedIndex < 0 Then Exit Sub
        iItem = lstResources.SelectedIndex
        If MainForm.mLR(iItem).ResourceType = JMResourceType.MID Then
            iVal = InputBox("Song intro length (in 1/100ths of a second):", , MainForm.mLR(iItem).ResourceData2)
            MainForm.mLR(iItem).ResourceData2 = iVal
        End If
    End Sub

    Sub DeleteSelectedItem()
        Dim iItem As Long
        If lstResources.SelectedIndex < 0 Then Exit Sub
        iItem = lstResources.SelectedIndex
        Dim iLoop As Long
        Dim sTemp As String
        For iLoop = lstResources.SelectedIndex To MainForm.mLRs - 2
            sTemp = MainForm.mLR(iLoop + 1).ConvertToString
            MainForm.mLR(iLoop).ConvertFromString(sTemp)
        Next
        MainForm.mLRs = MainForm.mLRs - 1
        ResetList()
        If iItem < lstResources.Items.Count Then
            lstResources.SelectedIndex = iItem
        ElseIf lstResources.Items.Count <> 0 Then
            lstResources.SelectedIndex = lstResources.Items.Count - 1
        End If
    End Sub

    Private Sub cmdMoveUp_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdMoveUp.Click
        If lstResources.SelectedIndex < 1 Then Exit Sub

        Dim iItem As Long
        Dim sTemp1 As String
        Dim sTemp2 As String

        iItem = lstResources.SelectedIndex
        sTemp1 = MainForm.mLR(iItem).ConvertToString
        sTemp2 = MainForm.mLR(iItem - 1).ConvertToString

        MainForm.mLR(iItem).ConvertFromString(sTemp2)
        MainForm.mLR(iItem - 1).ConvertFromString(sTemp1)

        ResetList()

        lstResources.SelectedIndex = iItem - 1
    End Sub

    Private Sub cmdMoveDown_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdMoveDown.Click
        If lstResources.SelectedIndex < 0 Then Exit Sub
        If lstResources.SelectedIndex > MainForm.mLRs - 2 Then Exit Sub

        Dim iItem As Long
        Dim sTemp1 As String
        Dim sTemp2 As String

        iItem = lstResources.SelectedIndex
        sTemp1 = MainForm.mLR(iItem).ConvertToString
        sTemp2 = MainForm.mLR(iItem + 1).ConvertToString

        MainForm.mLR(iItem).ConvertFromString(sTemp2)
        MainForm.mLR(iItem + 1).ConvertFromString(sTemp1)

        ResetList()
        lstResources.SelectedIndex = iItem + 1
    End Sub

    Private Sub EditResources_KeyUp(ByVal sender As Object, ByVal e As System.Windows.Forms.KeyEventArgs) Handles MyBase.KeyUp
        If e.KeyCode = Keys.Delete Then
            DeleteSelectedItem()
        End If
    End Sub

    Private Sub cmdAddSound_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdAddSound.Click
        AddItem("WAV", "Add Sound")
    End Sub

End Class
