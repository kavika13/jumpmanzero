Public Class ChooseItem
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
    Friend WithEvents lstChoices As System.Windows.Forms.ListBox
    Friend WithEvents DoOK As System.Windows.Forms.Button
    Friend WithEvents DoCancel As System.Windows.Forms.Button
    <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
        Me.lstChoices = New System.Windows.Forms.ListBox()
        Me.DoOK = New System.Windows.Forms.Button()
        Me.DoCancel = New System.Windows.Forms.Button()
        Me.SuspendLayout()
        '
        'lstChoices
        '
        Me.lstChoices.Location = New System.Drawing.Point(8, 8)
        Me.lstChoices.Name = "lstChoices"
        Me.lstChoices.Size = New System.Drawing.Size(280, 121)
        Me.lstChoices.TabIndex = 0
        '
        'DoOK
        '
        Me.DoOK.Location = New System.Drawing.Point(304, 72)
        Me.DoOK.Name = "DoOK"
        Me.DoOK.Size = New System.Drawing.Size(80, 24)
        Me.DoOK.TabIndex = 1
        Me.DoOK.Text = "OK"
        '
        'DoCancel
        '
        Me.DoCancel.Location = New System.Drawing.Point(304, 104)
        Me.DoCancel.Name = "DoCancel"
        Me.DoCancel.Size = New System.Drawing.Size(80, 24)
        Me.DoCancel.TabIndex = 2
        Me.DoCancel.Text = "Cancel"
        '
        'ChooseItem
        '
        Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
        Me.ClientSize = New System.Drawing.Size(392, 141)
        Me.Controls.AddRange(New System.Windows.Forms.Control() {Me.DoCancel, Me.DoOK, Me.lstChoices})
        Me.MaximizeBox = False
        Me.MinimizeBox = False
        Me.Name = "ChooseItem"
        Me.Text = "ChooseItem"
        Me.ResumeLayout(False)

    End Sub

#End Region

    Public Choices As String
    Public Values As String
    Public Selected As String
    Public Description As String

    Private Sub ChooseItem_Activated(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Activated
        lstChoices.Items.Clear()
        Dim sParts() As String
        Dim iPart As Long

        Me.Text = Description

        sParts = Split(Choices, ",")
        For iPart = 0 To UBound(sParts)
            lstChoices.Items.Add(sParts(iPart))
        Next

        sParts = Split(Choices, ",")
        For iPart = 0 To UBound(sParts)
            If sParts(iPart) = Selected Then
                lstChoices.SelectedIndex = iPart
            End If
        Next
    End Sub

    Private Sub DoOK_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles DoOK.Click
        Dim sParts() As String
        sParts = Split(Values, ",")
        If lstChoices.SelectedIndex >= 0 And lstChoices.SelectedIndex <= UBound(sParts) Then
            Selected = sParts(lstChoices.SelectedIndex)
        End If
        Me.Close()
    End Sub

    Private Sub DoCancel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles DoCancel.Click
        Me.Close()
    End Sub
End Class
