Public Class LoadDialog
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
    Friend WithEvents lstFiles As System.Windows.Forms.ListBox
    Friend WithEvents cmdLoad As System.Windows.Forms.Button
    Friend WithEvents cmdCancel As System.Windows.Forms.Button
    <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
        Me.lstFiles = New System.Windows.Forms.ListBox()
        Me.cmdLoad = New System.Windows.Forms.Button()
        Me.cmdCancel = New System.Windows.Forms.Button()
        Me.SuspendLayout()
        '
        'lstFiles
        '
        Me.lstFiles.Location = New System.Drawing.Point(8, 16)
        Me.lstFiles.Name = "lstFiles"
        Me.lstFiles.Size = New System.Drawing.Size(280, 147)
        Me.lstFiles.TabIndex = 0
        '
        'cmdLoad
        '
        Me.cmdLoad.Location = New System.Drawing.Point(296, 16)
        Me.cmdLoad.Name = "cmdLoad"
        Me.cmdLoad.Size = New System.Drawing.Size(88, 32)
        Me.cmdLoad.TabIndex = 1
        Me.cmdLoad.Text = "Load"
        '
        'cmdCancel
        '
        Me.cmdCancel.Location = New System.Drawing.Point(296, 56)
        Me.cmdCancel.Name = "cmdCancel"
        Me.cmdCancel.Size = New System.Drawing.Size(88, 32)
        Me.cmdCancel.TabIndex = 2
        Me.cmdCancel.Text = "Cancel"
        '
        'LoadDialog
        '
        Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
        Me.ClientSize = New System.Drawing.Size(392, 173)
        Me.Controls.AddRange(New System.Windows.Forms.Control() {Me.cmdCancel, Me.cmdLoad, Me.lstFiles})
        Me.MaximizeBox = False
        Me.MinimizeBox = False
        Me.Name = "LoadDialog"
        Me.Text = "Load Level"
        Me.ResumeLayout(False)

    End Sub

#End Region

    Public Extensions As String
    Public Directory As String
    Public Description As String

    Public ReturnFile As String

    Public AllowMultiple As Boolean

    Private Sub LoadDialog_Activated(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Activated
        Me.Text = Description

        lstFiles.Items.Clear()

        Dim sExts() As String
        sExts = Split(Extensions, ",")

        Dim iLoop As Long
        For iLoop = 0 To UBound(sExts)
            AddToList(sExts(iLoop))
        Next

        If AllowMultiple Then lstFiles.SelectionMode = SelectionMode.MultiExtended
    End Sub

    Sub AddToList(ByVal sExt As String)
        Dim sDir As String
        sDir = Dir(Directory & "*." & sExt)
        While sDir <> ""
            lstFiles.Items.Add(sDir)
            sDir = Dir()
        End While
    End Sub

    Private Sub cmdCancel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdCancel.Click
        ReturnFile = ""
        Me.Close()
    End Sub

    Private Sub cmdLoad_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdLoad.Click
        Dim iLoop As Long
        Dim sAll As String = Nothing

        For iLoop = 0 To lstFiles.SelectedIndices.Count - 1
            sAll = sAll & lstFiles.Items(lstFiles.SelectedIndices.Item(iLoop)) & "~"
        Next

        If Len(sAll) > 0 Then
            sAll = Microsoft.VisualBasic.Left(sAll, Len(sAll) - 1)
        End If

        ReturnFile = sAll
        Me.Close()
    End Sub

    Private Sub lstFiles_DoubleClick(ByVal sender As Object, ByVal e As System.EventArgs) Handles lstFiles.DoubleClick
        If lstFiles.SelectedIndex = -1 Then Exit Sub
        ReturnFile = lstFiles.SelectedItem
        Me.Close()
    End Sub

End Class
