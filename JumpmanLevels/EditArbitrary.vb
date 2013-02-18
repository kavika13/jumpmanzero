Public Class EditArbitrary
    Inherits System.Windows.Forms.Form

    Public MainForm As JLForm
    Public Item As Long

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
    Friend WithEvents txtX1 As System.Windows.Forms.TextBox
    Friend WithEvents Label1 As System.Windows.Forms.Label
    Friend WithEvents Label2 As System.Windows.Forms.Label
    Friend WithEvents Label3 As System.Windows.Forms.Label
    Friend WithEvents Label4 As System.Windows.Forms.Label
    Friend WithEvents Label5 As System.Windows.Forms.Label
    Friend WithEvents Label6 As System.Windows.Forms.Label
    Friend WithEvents Label7 As System.Windows.Forms.Label
    Friend WithEvents Label8 As System.Windows.Forms.Label
    Friend WithEvents Label9 As System.Windows.Forms.Label
    Friend WithEvents Label10 As System.Windows.Forms.Label
    Friend WithEvents Label11 As System.Windows.Forms.Label
    Friend WithEvents Label12 As System.Windows.Forms.Label
    Friend WithEvents Label13 As System.Windows.Forms.Label
    Friend WithEvents Label14 As System.Windows.Forms.Label
    Friend WithEvents Label15 As System.Windows.Forms.Label
    Friend WithEvents Label16 As System.Windows.Forms.Label
    Friend WithEvents Label17 As System.Windows.Forms.Label
    Friend WithEvents Label18 As System.Windows.Forms.Label
    Friend WithEvents Label19 As System.Windows.Forms.Label
    Friend WithEvents Label20 As System.Windows.Forms.Label
    Friend WithEvents cmdOK As System.Windows.Forms.Button
    Friend WithEvents cmdCancel As System.Windows.Forms.Button
    Friend WithEvents txtY1 As System.Windows.Forms.TextBox
    Friend WithEvents txtZ1 As System.Windows.Forms.TextBox
    Friend WithEvents txtU1 As System.Windows.Forms.TextBox
    Friend WithEvents txtV1 As System.Windows.Forms.TextBox
    Friend WithEvents txtV2 As System.Windows.Forms.TextBox
    Friend WithEvents txtU2 As System.Windows.Forms.TextBox
    Friend WithEvents txtZ2 As System.Windows.Forms.TextBox
    Friend WithEvents txtY2 As System.Windows.Forms.TextBox
    Friend WithEvents txtX2 As System.Windows.Forms.TextBox
    Friend WithEvents txtV3 As System.Windows.Forms.TextBox
    Friend WithEvents txtU3 As System.Windows.Forms.TextBox
    Friend WithEvents txtZ3 As System.Windows.Forms.TextBox
    Friend WithEvents txtY3 As System.Windows.Forms.TextBox
    Friend WithEvents txtX3 As System.Windows.Forms.TextBox
    Friend WithEvents txtV4 As System.Windows.Forms.TextBox
    Friend WithEvents txtU4 As System.Windows.Forms.TextBox
    Friend WithEvents txtZ4 As System.Windows.Forms.TextBox
    Friend WithEvents txtY4 As System.Windows.Forms.TextBox
    Friend WithEvents txtX4 As System.Windows.Forms.TextBox
    Friend WithEvents Label21 As System.Windows.Forms.Label
    Friend WithEvents txtTexture As System.Windows.Forms.TextBox
    Friend WithEvents txtNumber As System.Windows.Forms.TextBox
    Friend WithEvents Label22 As System.Windows.Forms.Label
    <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
        Me.txtX1 = New System.Windows.Forms.TextBox()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.Label2 = New System.Windows.Forms.Label()
        Me.txtY1 = New System.Windows.Forms.TextBox()
        Me.Label3 = New System.Windows.Forms.Label()
        Me.txtZ1 = New System.Windows.Forms.TextBox()
        Me.Label4 = New System.Windows.Forms.Label()
        Me.txtU1 = New System.Windows.Forms.TextBox()
        Me.Label5 = New System.Windows.Forms.Label()
        Me.txtV1 = New System.Windows.Forms.TextBox()
        Me.Label6 = New System.Windows.Forms.Label()
        Me.txtV2 = New System.Windows.Forms.TextBox()
        Me.Label7 = New System.Windows.Forms.Label()
        Me.txtU2 = New System.Windows.Forms.TextBox()
        Me.Label8 = New System.Windows.Forms.Label()
        Me.txtZ2 = New System.Windows.Forms.TextBox()
        Me.Label9 = New System.Windows.Forms.Label()
        Me.txtY2 = New System.Windows.Forms.TextBox()
        Me.Label10 = New System.Windows.Forms.Label()
        Me.txtX2 = New System.Windows.Forms.TextBox()
        Me.Label11 = New System.Windows.Forms.Label()
        Me.txtV3 = New System.Windows.Forms.TextBox()
        Me.Label12 = New System.Windows.Forms.Label()
        Me.txtU3 = New System.Windows.Forms.TextBox()
        Me.Label13 = New System.Windows.Forms.Label()
        Me.txtZ3 = New System.Windows.Forms.TextBox()
        Me.Label14 = New System.Windows.Forms.Label()
        Me.txtY3 = New System.Windows.Forms.TextBox()
        Me.Label15 = New System.Windows.Forms.Label()
        Me.txtX3 = New System.Windows.Forms.TextBox()
        Me.Label16 = New System.Windows.Forms.Label()
        Me.txtV4 = New System.Windows.Forms.TextBox()
        Me.Label17 = New System.Windows.Forms.Label()
        Me.txtU4 = New System.Windows.Forms.TextBox()
        Me.Label18 = New System.Windows.Forms.Label()
        Me.txtZ4 = New System.Windows.Forms.TextBox()
        Me.Label19 = New System.Windows.Forms.Label()
        Me.txtY4 = New System.Windows.Forms.TextBox()
        Me.Label20 = New System.Windows.Forms.Label()
        Me.txtX4 = New System.Windows.Forms.TextBox()
        Me.cmdOK = New System.Windows.Forms.Button()
        Me.cmdCancel = New System.Windows.Forms.Button()
        Me.Label21 = New System.Windows.Forms.Label()
        Me.txtTexture = New System.Windows.Forms.TextBox()
        Me.txtNumber = New System.Windows.Forms.TextBox()
        Me.Label22 = New System.Windows.Forms.Label()
        Me.SuspendLayout()
        '
        'txtX1
        '
        Me.txtX1.Location = New System.Drawing.Point(28, 4)
        Me.txtX1.Name = "txtX1"
        Me.txtX1.Size = New System.Drawing.Size(60, 20)
        Me.txtX1.TabIndex = 0
        Me.txtX1.Text = ""
        '
        'Label1
        '
        Me.Label1.AutoSize = True
        Me.Label1.Location = New System.Drawing.Point(4, 8)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(18, 13)
        Me.Label1.TabIndex = 1
        Me.Label1.Text = "X1"
        '
        'Label2
        '
        Me.Label2.AutoSize = True
        Me.Label2.Location = New System.Drawing.Point(4, 32)
        Me.Label2.Name = "Label2"
        Me.Label2.Size = New System.Drawing.Size(18, 13)
        Me.Label2.TabIndex = 3
        Me.Label2.Text = "Y1"
        '
        'txtY1
        '
        Me.txtY1.Location = New System.Drawing.Point(28, 28)
        Me.txtY1.Name = "txtY1"
        Me.txtY1.Size = New System.Drawing.Size(60, 20)
        Me.txtY1.TabIndex = 2
        Me.txtY1.Text = ""
        '
        'Label3
        '
        Me.Label3.AutoSize = True
        Me.Label3.Location = New System.Drawing.Point(4, 56)
        Me.Label3.Name = "Label3"
        Me.Label3.Size = New System.Drawing.Size(17, 13)
        Me.Label3.TabIndex = 5
        Me.Label3.Text = "Z1"
        '
        'txtZ1
        '
        Me.txtZ1.Location = New System.Drawing.Point(28, 52)
        Me.txtZ1.Name = "txtZ1"
        Me.txtZ1.Size = New System.Drawing.Size(60, 20)
        Me.txtZ1.TabIndex = 4
        Me.txtZ1.Text = ""
        '
        'Label4
        '
        Me.Label4.AutoSize = True
        Me.Label4.Location = New System.Drawing.Point(4, 80)
        Me.Label4.Name = "Label4"
        Me.Label4.Size = New System.Drawing.Size(19, 13)
        Me.Label4.TabIndex = 7
        Me.Label4.Text = "U1"
        '
        'txtU1
        '
        Me.txtU1.Location = New System.Drawing.Point(28, 76)
        Me.txtU1.Name = "txtU1"
        Me.txtU1.Size = New System.Drawing.Size(60, 20)
        Me.txtU1.TabIndex = 6
        Me.txtU1.Text = ""
        '
        'Label5
        '
        Me.Label5.AutoSize = True
        Me.Label5.Location = New System.Drawing.Point(4, 104)
        Me.Label5.Name = "Label5"
        Me.Label5.Size = New System.Drawing.Size(18, 13)
        Me.Label5.TabIndex = 9
        Me.Label5.Text = "V1"
        '
        'txtV1
        '
        Me.txtV1.Location = New System.Drawing.Point(28, 100)
        Me.txtV1.Name = "txtV1"
        Me.txtV1.Size = New System.Drawing.Size(60, 20)
        Me.txtV1.TabIndex = 8
        Me.txtV1.Text = ""
        '
        'Label6
        '
        Me.Label6.AutoSize = True
        Me.Label6.Location = New System.Drawing.Point(96, 104)
        Me.Label6.Name = "Label6"
        Me.Label6.Size = New System.Drawing.Size(18, 13)
        Me.Label6.TabIndex = 19
        Me.Label6.Text = "V2"
        '
        'txtV2
        '
        Me.txtV2.Location = New System.Drawing.Point(120, 100)
        Me.txtV2.Name = "txtV2"
        Me.txtV2.Size = New System.Drawing.Size(60, 20)
        Me.txtV2.TabIndex = 18
        Me.txtV2.Text = ""
        '
        'Label7
        '
        Me.Label7.AutoSize = True
        Me.Label7.Location = New System.Drawing.Point(96, 80)
        Me.Label7.Name = "Label7"
        Me.Label7.Size = New System.Drawing.Size(19, 13)
        Me.Label7.TabIndex = 17
        Me.Label7.Text = "U2"
        '
        'txtU2
        '
        Me.txtU2.Location = New System.Drawing.Point(120, 76)
        Me.txtU2.Name = "txtU2"
        Me.txtU2.Size = New System.Drawing.Size(60, 20)
        Me.txtU2.TabIndex = 16
        Me.txtU2.Text = ""
        '
        'Label8
        '
        Me.Label8.AutoSize = True
        Me.Label8.Location = New System.Drawing.Point(96, 56)
        Me.Label8.Name = "Label8"
        Me.Label8.Size = New System.Drawing.Size(17, 13)
        Me.Label8.TabIndex = 15
        Me.Label8.Text = "Z2"
        '
        'txtZ2
        '
        Me.txtZ2.Location = New System.Drawing.Point(120, 52)
        Me.txtZ2.Name = "txtZ2"
        Me.txtZ2.Size = New System.Drawing.Size(60, 20)
        Me.txtZ2.TabIndex = 14
        Me.txtZ2.Text = ""
        '
        'Label9
        '
        Me.Label9.AutoSize = True
        Me.Label9.Location = New System.Drawing.Point(96, 32)
        Me.Label9.Name = "Label9"
        Me.Label9.Size = New System.Drawing.Size(18, 13)
        Me.Label9.TabIndex = 13
        Me.Label9.Text = "Y2"
        '
        'txtY2
        '
        Me.txtY2.Location = New System.Drawing.Point(120, 28)
        Me.txtY2.Name = "txtY2"
        Me.txtY2.Size = New System.Drawing.Size(60, 20)
        Me.txtY2.TabIndex = 12
        Me.txtY2.Text = ""
        '
        'Label10
        '
        Me.Label10.AutoSize = True
        Me.Label10.Location = New System.Drawing.Point(96, 8)
        Me.Label10.Name = "Label10"
        Me.Label10.Size = New System.Drawing.Size(18, 13)
        Me.Label10.TabIndex = 11
        Me.Label10.Text = "X2"
        '
        'txtX2
        '
        Me.txtX2.Location = New System.Drawing.Point(120, 4)
        Me.txtX2.Name = "txtX2"
        Me.txtX2.Size = New System.Drawing.Size(60, 20)
        Me.txtX2.TabIndex = 10
        Me.txtX2.Text = ""
        '
        'Label11
        '
        Me.Label11.AutoSize = True
        Me.Label11.Location = New System.Drawing.Point(188, 104)
        Me.Label11.Name = "Label11"
        Me.Label11.Size = New System.Drawing.Size(18, 13)
        Me.Label11.TabIndex = 29
        Me.Label11.Text = "V3"
        '
        'txtV3
        '
        Me.txtV3.Location = New System.Drawing.Point(212, 100)
        Me.txtV3.Name = "txtV3"
        Me.txtV3.Size = New System.Drawing.Size(60, 20)
        Me.txtV3.TabIndex = 28
        Me.txtV3.Text = ""
        '
        'Label12
        '
        Me.Label12.AutoSize = True
        Me.Label12.Location = New System.Drawing.Point(188, 80)
        Me.Label12.Name = "Label12"
        Me.Label12.Size = New System.Drawing.Size(19, 13)
        Me.Label12.TabIndex = 27
        Me.Label12.Text = "U3"
        '
        'txtU3
        '
        Me.txtU3.Location = New System.Drawing.Point(212, 76)
        Me.txtU3.Name = "txtU3"
        Me.txtU3.Size = New System.Drawing.Size(60, 20)
        Me.txtU3.TabIndex = 26
        Me.txtU3.Text = ""
        '
        'Label13
        '
        Me.Label13.AutoSize = True
        Me.Label13.Location = New System.Drawing.Point(188, 56)
        Me.Label13.Name = "Label13"
        Me.Label13.Size = New System.Drawing.Size(17, 13)
        Me.Label13.TabIndex = 25
        Me.Label13.Text = "Z3"
        '
        'txtZ3
        '
        Me.txtZ3.Location = New System.Drawing.Point(212, 52)
        Me.txtZ3.Name = "txtZ3"
        Me.txtZ3.Size = New System.Drawing.Size(60, 20)
        Me.txtZ3.TabIndex = 24
        Me.txtZ3.Text = ""
        '
        'Label14
        '
        Me.Label14.AutoSize = True
        Me.Label14.Location = New System.Drawing.Point(188, 32)
        Me.Label14.Name = "Label14"
        Me.Label14.Size = New System.Drawing.Size(18, 13)
        Me.Label14.TabIndex = 23
        Me.Label14.Text = "Y3"
        '
        'txtY3
        '
        Me.txtY3.Location = New System.Drawing.Point(212, 28)
        Me.txtY3.Name = "txtY3"
        Me.txtY3.Size = New System.Drawing.Size(60, 20)
        Me.txtY3.TabIndex = 22
        Me.txtY3.Text = ""
        '
        'Label15
        '
        Me.Label15.AutoSize = True
        Me.Label15.Location = New System.Drawing.Point(188, 8)
        Me.Label15.Name = "Label15"
        Me.Label15.Size = New System.Drawing.Size(18, 13)
        Me.Label15.TabIndex = 21
        Me.Label15.Text = "X3"
        '
        'txtX3
        '
        Me.txtX3.Location = New System.Drawing.Point(212, 4)
        Me.txtX3.Name = "txtX3"
        Me.txtX3.Size = New System.Drawing.Size(60, 20)
        Me.txtX3.TabIndex = 20
        Me.txtX3.Text = ""
        '
        'Label16
        '
        Me.Label16.AutoSize = True
        Me.Label16.Location = New System.Drawing.Point(280, 104)
        Me.Label16.Name = "Label16"
        Me.Label16.Size = New System.Drawing.Size(18, 13)
        Me.Label16.TabIndex = 39
        Me.Label16.Text = "V4"
        '
        'txtV4
        '
        Me.txtV4.Location = New System.Drawing.Point(304, 100)
        Me.txtV4.Name = "txtV4"
        Me.txtV4.Size = New System.Drawing.Size(60, 20)
        Me.txtV4.TabIndex = 38
        Me.txtV4.Text = ""
        '
        'Label17
        '
        Me.Label17.AutoSize = True
        Me.Label17.Location = New System.Drawing.Point(280, 80)
        Me.Label17.Name = "Label17"
        Me.Label17.Size = New System.Drawing.Size(19, 13)
        Me.Label17.TabIndex = 37
        Me.Label17.Text = "U4"
        '
        'txtU4
        '
        Me.txtU4.Location = New System.Drawing.Point(304, 76)
        Me.txtU4.Name = "txtU4"
        Me.txtU4.Size = New System.Drawing.Size(60, 20)
        Me.txtU4.TabIndex = 36
        Me.txtU4.Text = ""
        '
        'Label18
        '
        Me.Label18.AutoSize = True
        Me.Label18.Location = New System.Drawing.Point(280, 56)
        Me.Label18.Name = "Label18"
        Me.Label18.Size = New System.Drawing.Size(17, 13)
        Me.Label18.TabIndex = 35
        Me.Label18.Text = "Z4"
        '
        'txtZ4
        '
        Me.txtZ4.Location = New System.Drawing.Point(304, 52)
        Me.txtZ4.Name = "txtZ4"
        Me.txtZ4.Size = New System.Drawing.Size(60, 20)
        Me.txtZ4.TabIndex = 34
        Me.txtZ4.Text = ""
        '
        'Label19
        '
        Me.Label19.AutoSize = True
        Me.Label19.Location = New System.Drawing.Point(280, 32)
        Me.Label19.Name = "Label19"
        Me.Label19.Size = New System.Drawing.Size(18, 13)
        Me.Label19.TabIndex = 33
        Me.Label19.Text = "Y4"
        '
        'txtY4
        '
        Me.txtY4.Location = New System.Drawing.Point(304, 28)
        Me.txtY4.Name = "txtY4"
        Me.txtY4.Size = New System.Drawing.Size(60, 20)
        Me.txtY4.TabIndex = 32
        Me.txtY4.Text = ""
        '
        'Label20
        '
        Me.Label20.AutoSize = True
        Me.Label20.Location = New System.Drawing.Point(280, 8)
        Me.Label20.Name = "Label20"
        Me.Label20.Size = New System.Drawing.Size(18, 13)
        Me.Label20.TabIndex = 31
        Me.Label20.Text = "X4"
        '
        'txtX4
        '
        Me.txtX4.Location = New System.Drawing.Point(304, 4)
        Me.txtX4.Name = "txtX4"
        Me.txtX4.Size = New System.Drawing.Size(60, 20)
        Me.txtX4.TabIndex = 30
        Me.txtX4.Text = ""
        '
        'cmdOK
        '
        Me.cmdOK.Location = New System.Drawing.Point(200, 128)
        Me.cmdOK.Name = "cmdOK"
        Me.cmdOK.Size = New System.Drawing.Size(80, 24)
        Me.cmdOK.TabIndex = 40
        Me.cmdOK.Text = "OK"
        '
        'cmdCancel
        '
        Me.cmdCancel.Location = New System.Drawing.Point(288, 128)
        Me.cmdCancel.Name = "cmdCancel"
        Me.cmdCancel.Size = New System.Drawing.Size(80, 24)
        Me.cmdCancel.TabIndex = 41
        Me.cmdCancel.Text = "Cancel"
        '
        'Label21
        '
        Me.Label21.Location = New System.Drawing.Point(0, 132)
        Me.Label21.Name = "Label21"
        Me.Label21.Size = New System.Drawing.Size(64, 16)
        Me.Label21.TabIndex = 42
        Me.Label21.Text = "Texture:"
        '
        'txtTexture
        '
        Me.txtTexture.Location = New System.Drawing.Point(48, 128)
        Me.txtTexture.Name = "txtTexture"
        Me.txtTexture.Size = New System.Drawing.Size(40, 20)
        Me.txtTexture.TabIndex = 43
        Me.txtTexture.Text = ""
        '
        'txtNumber
        '
        Me.txtNumber.Location = New System.Drawing.Point(144, 128)
        Me.txtNumber.Name = "txtNumber"
        Me.txtNumber.Size = New System.Drawing.Size(40, 20)
        Me.txtNumber.TabIndex = 45
        Me.txtNumber.Text = ""
        '
        'Label22
        '
        Me.Label22.Location = New System.Drawing.Point(96, 132)
        Me.Label22.Name = "Label22"
        Me.Label22.Size = New System.Drawing.Size(64, 16)
        Me.Label22.TabIndex = 44
        Me.Label22.Text = "Number:"
        '
        'EditArbitrary
        '
        Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
        Me.ClientSize = New System.Drawing.Size(372, 157)
        Me.Controls.AddRange(New System.Windows.Forms.Control() {Me.txtNumber, Me.Label22, Me.txtTexture, Me.Label21, Me.cmdCancel, Me.cmdOK, Me.Label16, Me.txtV4, Me.Label17, Me.txtU4, Me.Label18, Me.txtZ4, Me.Label19, Me.txtY4, Me.Label20, Me.txtX4, Me.Label11, Me.txtV3, Me.Label12, Me.txtU3, Me.Label13, Me.txtZ3, Me.Label14, Me.txtY3, Me.Label15, Me.txtX3, Me.Label6, Me.txtV2, Me.Label7, Me.txtU2, Me.Label8, Me.txtZ2, Me.Label9, Me.txtY2, Me.Label10, Me.txtX2, Me.Label5, Me.txtV1, Me.Label4, Me.txtU1, Me.Label3, Me.txtZ1, Me.Label2, Me.txtY1, Me.Label1, Me.txtX1})
        Me.MaximizeBox = False
        Me.MinimizeBox = False
        Me.Name = "EditArbitrary"
        Me.Text = "Edit Picture"
        Me.ResumeLayout(False)

    End Sub

#End Region

    Private Sub Form1_Activated(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Activated
        txtX1.Text = MainForm.mLO(Item).V(1).X
        txtY1.Text = MainForm.mLO(Item).V(1).Y
        txtZ1.Text = MainForm.mLO(Item).V(1).Z
        txtU1.Text = MainForm.mLO(Item).V(1).TX
        txtV1.Text = MainForm.mLO(Item).V(1).TY

        txtX2.Text = MainForm.mLO(Item).V(2).X
        txtY2.Text = MainForm.mLO(Item).V(2).Y
        txtZ2.Text = MainForm.mLO(Item).V(2).Z
        txtU2.Text = MainForm.mLO(Item).V(2).TX
        txtV2.Text = MainForm.mLO(Item).V(2).TY

        txtX3.Text = MainForm.mLO(Item).V(3).X
        txtY3.Text = MainForm.mLO(Item).V(3).Y
        txtZ3.Text = MainForm.mLO(Item).V(3).Z
        txtU3.Text = MainForm.mLO(Item).V(3).TX
        txtV3.Text = MainForm.mLO(Item).V(3).TY

        txtX4.Text = MainForm.mLO(Item).V(4).X
        txtY4.Text = MainForm.mLO(Item).V(4).Y
        txtZ4.Text = MainForm.mLO(Item).V(4).Z
        txtU4.Text = MainForm.mLO(Item).V(4).TX
        txtV4.Text = MainForm.mLO(Item).V(4).TY

        txtNumber.Text = MainForm.mLO(Item).Number

        txtTexture.Text = MainForm.mLO(Item).Texture
    End Sub

    Private Sub cmdOK_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdOK.Click
        Try
            MainForm.mLO(Item).V(1).X = txtX1.Text
            MainForm.mLO(Item).V(1).Y = txtY1.Text
            MainForm.mLO(Item).V(1).Z = txtZ1.Text
            MainForm.mLO(Item).V(1).TX = txtU1.Text
            MainForm.mLO(Item).V(1).TY = txtV1.Text

            MainForm.mLO(Item).V(2).X = txtX2.Text
            MainForm.mLO(Item).V(2).Y = txtY2.Text
            MainForm.mLO(Item).V(2).Z = txtZ2.Text
            MainForm.mLO(Item).V(2).TX = txtU2.Text
            MainForm.mLO(Item).V(2).TY = txtV2.Text

            MainForm.mLO(Item).V(3).X = txtX3.Text
            MainForm.mLO(Item).V(3).Y = txtY3.Text
            MainForm.mLO(Item).V(3).Z = txtZ3.Text
            MainForm.mLO(Item).V(3).TX = txtU3.Text
            MainForm.mLO(Item).V(3).TY = txtV3.Text

            MainForm.mLO(Item).V(4).X = txtX4.Text
            MainForm.mLO(Item).V(4).Y = txtY4.Text
            MainForm.mLO(Item).V(4).Z = txtZ4.Text
            MainForm.mLO(Item).V(4).TX = txtU4.Text
            MainForm.mLO(Item).V(4).TY = txtV4.Text

            MainForm.mLO(Item).Texture = txtTexture.Text
            MainForm.mLO(Item).Number = txtNumber.Text
        Catch
            MsgBox("Error in input!")
            Exit Sub
        End Try

        Me.Close()
    End Sub

    Private Sub cmdCancel_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdCancel.Click
        Me.Close()
    End Sub
End Class
