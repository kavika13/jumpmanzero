Public Class EditObject
    Inherits System.Windows.Forms.Form

    Public MainForm As JLForm
    Public Item As Long
    Private iInit As Boolean

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
    Friend WithEvents cbDrawT As System.Windows.Forms.CheckBox
    Friend WithEvents cbDrawB As System.Windows.Forms.CheckBox
    Friend WithEvents cbDrawL As System.Windows.Forms.CheckBox
    Friend WithEvents cbDrawR As System.Windows.Forms.CheckBox
    Friend WithEvents cbDrawF As System.Windows.Forms.CheckBox
    Friend WithEvents cbDrawX As System.Windows.Forms.CheckBox
    Friend WithEvents cmdOK As System.Windows.Forms.Button
    Friend WithEvents cmdCancel As System.Windows.Forms.Button
    Friend WithEvents txtTexture As System.Windows.Forms.TextBox
    Friend WithEvents lblTexture As System.Windows.Forms.Label
    Friend WithEvents lblNumber As System.Windows.Forms.Label
    Friend WithEvents txtNumber As System.Windows.Forms.TextBox
    Friend WithEvents Label1 As System.Windows.Forms.Label
    Friend WithEvents txtExtra As System.Windows.Forms.TextBox
    <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
        Me.cbDrawT = New System.Windows.Forms.CheckBox()
        Me.cbDrawB = New System.Windows.Forms.CheckBox()
        Me.cbDrawL = New System.Windows.Forms.CheckBox()
        Me.cbDrawR = New System.Windows.Forms.CheckBox()
        Me.cbDrawF = New System.Windows.Forms.CheckBox()
        Me.cbDrawX = New System.Windows.Forms.CheckBox()
        Me.cmdOK = New System.Windows.Forms.Button()
        Me.cmdCancel = New System.Windows.Forms.Button()
        Me.txtTexture = New System.Windows.Forms.TextBox()
        Me.lblTexture = New System.Windows.Forms.Label()
        Me.lblNumber = New System.Windows.Forms.Label()
        Me.txtNumber = New System.Windows.Forms.TextBox()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.txtExtra = New System.Windows.Forms.TextBox()
        Me.SuspendLayout()
        '
        'cbDrawT
        '
        Me.cbDrawT.Location = New System.Drawing.Point(8, 8)
        Me.cbDrawT.Name = "cbDrawT"
        Me.cbDrawT.Size = New System.Drawing.Size(88, 16)
        Me.cbDrawT.TabIndex = 0
        Me.cbDrawT.Text = "Draw Top"
        '
        'cbDrawB
        '
        Me.cbDrawB.Location = New System.Drawing.Point(8, 24)
        Me.cbDrawB.Name = "cbDrawB"
        Me.cbDrawB.Size = New System.Drawing.Size(88, 16)
        Me.cbDrawB.TabIndex = 1
        Me.cbDrawB.Text = "Draw Bottom"
        '
        'cbDrawL
        '
        Me.cbDrawL.Location = New System.Drawing.Point(8, 40)
        Me.cbDrawL.Name = "cbDrawL"
        Me.cbDrawL.Size = New System.Drawing.Size(88, 16)
        Me.cbDrawL.TabIndex = 2
        Me.cbDrawL.Text = "Draw Left"
        '
        'cbDrawR
        '
        Me.cbDrawR.Location = New System.Drawing.Point(8, 56)
        Me.cbDrawR.Name = "cbDrawR"
        Me.cbDrawR.Size = New System.Drawing.Size(88, 16)
        Me.cbDrawR.TabIndex = 3
        Me.cbDrawR.Text = "Draw Right"
        '
        'cbDrawF
        '
        Me.cbDrawF.Location = New System.Drawing.Point(8, 72)
        Me.cbDrawF.Name = "cbDrawF"
        Me.cbDrawF.Size = New System.Drawing.Size(88, 16)
        Me.cbDrawF.TabIndex = 10
        Me.cbDrawF.Text = "Draw Front"
        '
        'cbDrawX
        '
        Me.cbDrawX.Location = New System.Drawing.Point(8, 88)
        Me.cbDrawX.Name = "cbDrawX"
        Me.cbDrawX.Size = New System.Drawing.Size(88, 16)
        Me.cbDrawX.TabIndex = 11
        Me.cbDrawX.Text = "Draw Back"
        '
        'cmdOK
        '
        Me.cmdOK.Location = New System.Drawing.Point(112, 88)
        Me.cmdOK.Name = "cmdOK"
        Me.cmdOK.Size = New System.Drawing.Size(72, 24)
        Me.cmdOK.TabIndex = 12
        Me.cmdOK.Text = "OK"
        '
        'cmdCancel
        '
        Me.cmdCancel.Location = New System.Drawing.Point(192, 88)
        Me.cmdCancel.Name = "cmdCancel"
        Me.cmdCancel.Size = New System.Drawing.Size(72, 24)
        Me.cmdCancel.TabIndex = 13
        Me.cmdCancel.Text = "Cancel"
        '
        'txtTexture
        '
        Me.txtTexture.Location = New System.Drawing.Point(192, 8)
        Me.txtTexture.Name = "txtTexture"
        Me.txtTexture.Size = New System.Drawing.Size(72, 20)
        Me.txtTexture.TabIndex = 14
        Me.txtTexture.Text = ""
        '
        'lblTexture
        '
        Me.lblTexture.Location = New System.Drawing.Point(144, 8)
        Me.lblTexture.Name = "lblTexture"
        Me.lblTexture.Size = New System.Drawing.Size(48, 16)
        Me.lblTexture.TabIndex = 15
        Me.lblTexture.Text = "Texture:"
        '
        'lblNumber
        '
        Me.lblNumber.Location = New System.Drawing.Point(144, 32)
        Me.lblNumber.Name = "lblNumber"
        Me.lblNumber.Size = New System.Drawing.Size(48, 16)
        Me.lblNumber.TabIndex = 17
        Me.lblNumber.Text = "Number:"
        '
        'txtNumber
        '
        Me.txtNumber.Location = New System.Drawing.Point(192, 32)
        Me.txtNumber.Name = "txtNumber"
        Me.txtNumber.Size = New System.Drawing.Size(72, 20)
        Me.txtNumber.TabIndex = 16
        Me.txtNumber.Text = ""
        '
        'Label1
        '
        Me.Label1.Location = New System.Drawing.Point(152, 56)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(40, 16)
        Me.Label1.TabIndex = 19
        Me.Label1.Text = "Extra:"
        '
        'txtExtra
        '
        Me.txtExtra.Location = New System.Drawing.Point(192, 56)
        Me.txtExtra.Name = "txtExtra"
        Me.txtExtra.Size = New System.Drawing.Size(72, 20)
        Me.txtExtra.TabIndex = 18
        Me.txtExtra.Text = ""
        '
        'EditObject
        '
        Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
        Me.ClientSize = New System.Drawing.Size(272, 117)
        Me.Controls.AddRange(New System.Windows.Forms.Control() {Me.Label1, Me.txtExtra, Me.lblNumber, Me.txtNumber, Me.lblTexture, Me.txtTexture, Me.cmdCancel, Me.cmdOK, Me.cbDrawX, Me.cbDrawF, Me.cbDrawR, Me.cbDrawL, Me.cbDrawB, Me.cbDrawT})
        Me.MaximizeBox = False
        Me.MinimizeBox = False
        Me.Name = "EditObject"
        Me.Text = "Edit Object"
        Me.ResumeLayout(False)

    End Sub

#End Region

    Private Sub EditObject_Activated(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Activated
        If iInit Then Exit Sub
        iInit = True
        cbDrawT.Checked = MainForm.mLO(Item).DrawT
        cbDrawB.Checked = MainForm.mLO(Item).DrawB
        cbDrawL.Checked = MainForm.mLO(Item).DrawL
        cbDrawR.Checked = MainForm.mLO(Item).DrawR
        cbDrawF.Checked = MainForm.mLO(Item).DrawF
        cbDrawX.Checked = MainForm.mLO(Item).DrawX
        txtTexture.Text = MainForm.mLO(Item).Texture
        txtNumber.Text = MainForm.mLO(Item).Number
        txtExtra.Text = MainForm.mLO(Item).Extra
    End Sub

    Private Sub cmdOK_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdOK.Click

        Try
            MainForm.mLO(Item).DrawT = cbDrawT.Checked
            MainForm.mLO(Item).DrawB = cbDrawB.Checked
            MainForm.mLO(Item).DrawL = cbDrawL.Checked
            MainForm.mLO(Item).DrawR = cbDrawR.Checked
            MainForm.mLO(Item).DrawF = cbDrawF.Checked
            MainForm.mLO(Item).DrawX = cbDrawX.Checked
            MainForm.mLO(Item).Texture = txtTexture.Text
            MainForm.mLO(Item).Number = txtNumber.Text
            MainForm.mLO(Item).Extra = txtExtra.Text
        Catch
            MsgBox("Error in input")
            Exit Sub
        End Try

        Me.Close()
    End Sub

    Private Sub cmdCancel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdCancel.Click
        Me.Close()
    End Sub

    Private Sub EditObject_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

    End Sub
End Class
