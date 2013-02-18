
Public Class CodeForm
    Inherits System.Windows.Forms.Form

    Dim sCurrentFile As String

    Dim sLastFind As String

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
    Friend WithEvents txtOut As System.Windows.Forms.TextBox
    Friend WithEvents cmdCompile As System.Windows.Forms.Button
    Friend WithEvents cmdRun As System.Windows.Forms.Button
    Friend WithEvents txtCode As System.Windows.Forms.TextBox
    Friend WithEvents CodeFormMenu As System.Windows.Forms.MainMenu
    Friend WithEvents MenuItem1 As System.Windows.Forms.MenuItem
    Friend WithEvents menuLoad As System.Windows.Forms.MenuItem
    Friend WithEvents menuSave As System.Windows.Forms.MenuItem
    Friend WithEvents menuSaveAs As System.Windows.Forms.MenuItem
    Friend WithEvents txtErrors As System.Windows.Forms.TextBox
    Friend WithEvents MenuItem2 As System.Windows.Forms.MenuItem
    <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()
        Me.cmdCompile = New System.Windows.Forms.Button()
        Me.txtOut = New System.Windows.Forms.TextBox()
        Me.cmdRun = New System.Windows.Forms.Button()
        Me.txtCode = New System.Windows.Forms.TextBox()
        Me.CodeFormMenu = New System.Windows.Forms.MainMenu()
        Me.MenuItem1 = New System.Windows.Forms.MenuItem()
        Me.menuLoad = New System.Windows.Forms.MenuItem()
        Me.menuSave = New System.Windows.Forms.MenuItem()
        Me.menuSaveAs = New System.Windows.Forms.MenuItem()
        Me.txtErrors = New System.Windows.Forms.TextBox()
        Me.MenuItem2 = New System.Windows.Forms.MenuItem()
        Me.SuspendLayout()
        '
        'cmdCompile
        '
        Me.cmdCompile.Location = New System.Drawing.Point(16, 340)
        Me.cmdCompile.Name = "cmdCompile"
        Me.cmdCompile.Size = New System.Drawing.Size(72, 20)
        Me.cmdCompile.TabIndex = 4
        Me.cmdCompile.TabStop = False
        Me.cmdCompile.Text = "Compile"
        '
        'txtOut
        '
        Me.txtOut.Font = New System.Drawing.Font("Courier New", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.txtOut.Location = New System.Drawing.Point(416, 336)
        Me.txtOut.Multiline = True
        Me.txtOut.Name = "txtOut"
        Me.txtOut.Size = New System.Drawing.Size(404, 168)
        Me.txtOut.TabIndex = 5
        Me.txtOut.TabStop = False
        Me.txtOut.Text = ""
        '
        'cmdRun
        '
        Me.cmdRun.Location = New System.Drawing.Point(16, 364)
        Me.cmdRun.Name = "cmdRun"
        Me.cmdRun.Size = New System.Drawing.Size(72, 20)
        Me.cmdRun.TabIndex = 7
        Me.cmdRun.TabStop = False
        Me.cmdRun.Text = "Run"
        '
        'txtCode
        '
        Me.txtCode.AcceptsReturn = True
        Me.txtCode.AcceptsTab = True
        Me.txtCode.Font = New System.Drawing.Font("Courier New", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.txtCode.Location = New System.Drawing.Point(8, 8)
        Me.txtCode.Multiline = True
        Me.txtCode.Name = "txtCode"
        Me.txtCode.Size = New System.Drawing.Size(800, 320)
        Me.txtCode.TabIndex = 8
        Me.txtCode.TabStop = False
        Me.txtCode.Text = ""
        '
        'CodeFormMenu
        '
        Me.CodeFormMenu.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.MenuItem1})
        '
        'MenuItem1
        '
        Me.MenuItem1.Index = 0
        Me.MenuItem1.MenuItems.AddRange(New System.Windows.Forms.MenuItem() {Me.menuLoad, Me.menuSave, Me.menuSaveAs, Me.MenuItem2})
        Me.MenuItem1.Text = "File"
        '
        'menuLoad
        '
        Me.menuLoad.Index = 0
        Me.menuLoad.Text = "Load"
        '
        'menuSave
        '
        Me.menuSave.Index = 1
        Me.menuSave.Text = "Save"
        '
        'menuSaveAs
        '
        Me.menuSaveAs.Index = 2
        Me.menuSaveAs.Text = "Save as"
        '
        'txtErrors
        '
        Me.txtErrors.Font = New System.Drawing.Font("Courier New", 8.25!, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, CType(0, Byte))
        Me.txtErrors.Location = New System.Drawing.Point(96, 336)
        Me.txtErrors.Multiline = True
        Me.txtErrors.Name = "txtErrors"
        Me.txtErrors.Size = New System.Drawing.Size(312, 168)
        Me.txtErrors.TabIndex = 9
        Me.txtErrors.TabStop = False
        Me.txtErrors.Text = ""
        '
        'MenuItem2
        '
        Me.MenuItem2.Index = 3
        Me.MenuItem2.Text = "-"
        '
        'CodeForm
        '
        Me.AutoScaleBaseSize = New System.Drawing.Size(5, 13)
        Me.ClientSize = New System.Drawing.Size(824, 509)
        Me.Controls.AddRange(New System.Windows.Forms.Control() {Me.txtErrors, Me.txtCode, Me.cmdRun, Me.txtOut, Me.cmdCompile})
        Me.Menu = Me.CodeFormMenu
        Me.Name = "CodeForm"
        Me.Text = "Jumpman Scripting"
        Me.ResumeLayout(False)

    End Sub

#End Region

#Region "File Management"

    Private Sub SetCurrentFile(ByVal sFile As String)
        sCurrentFile = sFile
        Me.Text = "Jumpman Script Compiler - " & sCurrentFile & ".jms"
        txtCode.Text = LoadCode("c:\Jumpman\Source\" & sFile & ".jms")
    End Sub

    Private Sub CodeForm_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        SetCurrentFile("untitled")
        AddToHistory("")
    End Sub

    Private Sub SaveCode(ByVal sFile As String)
        FileOpen(1, sFile, OpenMode.Output)
        Dim sCode As String
        sCode = txtCode.Text
        Print(1, sCode)
        FileClose(1)
    End Sub

    Private Sub menuSaveAs_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles menuSaveAs.Click
        DoSaveAs()
    End Sub

    Private Sub cmdSaveAs_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)
        DoSaveAs()
    End Sub

    Private Sub DoSaveAs()
        Dim sNew As String
        sNew = InputBox("File Name:", "Save as..")
        If Len(sNew) > 0 Then
            sCurrentFile = sNew
            SaveCode("c:\Jumpman\Source\" & sCurrentFile & ".jms")
            Me.Text = "Jumpman Script Compiler - " & sCurrentFile & ".jms"
        End If
    End Sub

    Private Sub MenuSave_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles menuSave.Click
        DoSave()
    End Sub

    Private Sub cmdSave_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)
        DoSave()
    End Sub

    Private Sub DoSave()
        SaveCode("c:\Jumpman\Source\" & sCurrentFile & ".jms")
    End Sub

    Private Sub MenuLoad_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles menuLoad.Click
        DoLoad()
    End Sub

    Private Sub cmdLoad_Click(ByVal sender As System.Object, ByVal e As System.EventArgs)
        DoLoad()
    End Sub

    Private Sub DoLoad()

        Dim ld As New LoadDialog()
        ld.Description = "Load Script"
        ld.Directory = "c:\jumpman\source\"
        ld.Extensions = "JMS"

        ld.ShowDialog()

        Dim sFile As String

        sFile = ld.ReturnFile
        If Len(sFile) > 0 Then LoadFile(sFile)
    End Sub

#End Region

    Sub LoadFile(ByVal sFile As String)
        If InStr(sFile, ".") <> 0 Then
            sFile = Microsoft.VisualBasic.Left(sFile, InStr(sFile, ".") - 1)
        End If
        SetCurrentFile(sFile)
        AddToHistory(sFile)
    End Sub

    Sub AddToHistory(ByVal sFile As String)
        Dim sHist(5) As String
        Dim iHist As Long
        Dim iItems As Long
        Dim sItem As String

        If sFile <> "" Then
            sHist(0) = sFile
            iItems = 1
        End If

        For iHist = 0 To 4
            sItem = GetSetting("JMScripting", "History", "History" & iHist, "")
            If sFile <> sItem And iItems < 5 Then
                sHist(iItems) = sItem
                iItems = iItems + 1
            End If
        Next

        While CodeFormMenu.MenuItems(0).MenuItems.Count > 4
            CodeFormMenu.MenuItems(0).MenuItems.RemoveAt(4)
        End While

        For iHist = 0 To iItems - 1
            If sHist(iHist) <> "" Then
                CodeFormMenu.MenuItems(0).MenuItems.Add(sHist(iHist), New EventHandler(AddressOf DoSomething))
            End If
        Next

        For iHist = 0 To 4
            If sHist(iHist) <> "" Then
                SaveSetting("JMScripting", "History", "History" & iHist, sHist(iHist))
            End If
        Next
    End Sub

    Private Sub DoSomething(ByVal sender As System.Object, ByVal e As System.EventArgs)
        Dim oTest As MenuItem
        oTest = sender
        LoadFile(oTest.Text)
    End Sub

    Dim oScript As ScriptCompiler
    Dim rScript As New RunScript()

#Region "Compiling"
    Private Sub cmdCompile_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdCompile.Click
        DoSave()

        Dim sCode As String

        txtErrors.Text = "Compiling..."

        sCode = txtCode.Text

        oScript = New ScriptCompiler()
        oScript.Compile(sCode)

        txtErrors.Text = oScript.CompileSummary
        If txtErrors.Text = "" Then
            txtErrors.Text = "Compile finished - " & Format(Now, "hh:mm:ss")
        End If

        Dim sTemp As String
        Dim sBase As String

        sTemp = "c:\Jumpman\Data\" & sCurrentFile & ".BIN"
        oScript.WriteBinary(sTemp)

        sTemp = "c:\Jumpman\Source\REF" & sCurrentFile & ".JMS"
        oScript.WriteConstants(sTemp, sCurrentFile)

        rScript.SetScript(oScript)
        rScript.RunScript(0)
    End Sub

    Private Sub cmdRun_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles cmdRun.Click
        Dim dStart As Date
        Dim dEnd As Date

        dStart = Now
        rScript.RunScript(1)
        txtOut.Text = rScript.GetOutput
        dEnd = Now

    End Sub

#End Region

    Private Sub txtCode_KeyUp(ByVal sender As Object, ByVal e As System.Windows.Forms.KeyEventArgs) Handles txtCode.KeyUp
        If e.KeyCode = Keys.F3 Then
            FindString(sLastFind)
            e.Handled = True
        End If
    End Sub

    Private Sub txtCode_KeyPress(ByVal sender As Object, ByVal e As System.Windows.Forms.KeyPressEventArgs) Handles txtCode.KeyPress
        If Asc(e.KeyChar) = 6 Then
            Dim FF As New Find()
            FF.ShowDialog()
            If FF.FindString = "" Then Exit Sub
            sLastFind = FF.FindString
            FindString(sLastFind)
            e.Handled = True
        End If
    End Sub

    Private Sub FindString(ByVal sFind As String)
        Dim sText As String
        Dim iFind As Long

        sText = txtCode.Text
        iFind = InStr(txtCode.SelectionStart + 2, txtCode.Text, sFind, CompareMethod.Text)
        If iFind = 0 Then
            iFind = InStr(1, txtCode.Text, sFind, CompareMethod.Text)
        End If

        If iFind = 0 Then
            Beep()
            Exit Sub
        End If

        txtCode.SelectionStart = iFind - 1
        txtCode.SelectionLength = Len(sFind)
        txtCode.ScrollToCaret()

    End Sub

    Private Sub CodeForm_Activated(ByVal sender As Object, ByVal e As System.EventArgs) Handles MyBase.Activated
        txtCode.Focus()
    End Sub

End Class
