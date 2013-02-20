<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class ToolOptionsDialog
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Me.GroupBox1 = New System.Windows.Forms.GroupBox()
        Me.BrowseForAseImportDirectoryButton = New System.Windows.Forms.Button()
        Me.BrowseForOutputDirectoryButton = New System.Windows.Forms.Button()
        Me.BrowseForSourceDirectoryButton = New System.Windows.Forms.Button()
        Me.AseImportDirectoryLabel = New System.Windows.Forms.Label()
        Me.AseImportDirectoryTextBox = New System.Windows.Forms.TextBox()
        Me.OutputDirectoryLabel = New System.Windows.Forms.Label()
        Me.OutputDirectoryTextBox = New System.Windows.Forms.TextBox()
        Me.SourceFileDirectoryLabel = New System.Windows.Forms.Label()
        Me.SourceDirectoryTextBox = New System.Windows.Forms.TextBox()
        Me.SaveButton = New System.Windows.Forms.Button()
        Me.CancelButton1 = New System.Windows.Forms.Button()
        Me.FolderBrowserDialog = New System.Windows.Forms.FolderBrowserDialog()
        Me.ResetButton = New System.Windows.Forms.Button()
        Me.GroupBox1.SuspendLayout()
        Me.SuspendLayout()
        '
        'GroupBox1
        '
        Me.GroupBox1.Controls.Add(Me.BrowseForAseImportDirectoryButton)
        Me.GroupBox1.Controls.Add(Me.BrowseForOutputDirectoryButton)
        Me.GroupBox1.Controls.Add(Me.BrowseForSourceDirectoryButton)
        Me.GroupBox1.Controls.Add(Me.AseImportDirectoryLabel)
        Me.GroupBox1.Controls.Add(Me.AseImportDirectoryTextBox)
        Me.GroupBox1.Controls.Add(Me.OutputDirectoryLabel)
        Me.GroupBox1.Controls.Add(Me.OutputDirectoryTextBox)
        Me.GroupBox1.Controls.Add(Me.SourceFileDirectoryLabel)
        Me.GroupBox1.Controls.Add(Me.SourceDirectoryTextBox)
        Me.GroupBox1.Location = New System.Drawing.Point(12, 12)
        Me.GroupBox1.Name = "GroupBox1"
        Me.GroupBox1.Size = New System.Drawing.Size(604, 102)
        Me.GroupBox1.TabIndex = 0
        Me.GroupBox1.TabStop = False
        Me.GroupBox1.Text = "Paths"
        '
        'BrowseForAseImportDirectoryButton
        '
        Me.BrowseForAseImportDirectoryButton.Location = New System.Drawing.Point(523, 75)
        Me.BrowseForAseImportDirectoryButton.Name = "BrowseForAseImportDirectoryButton"
        Me.BrowseForAseImportDirectoryButton.Size = New System.Drawing.Size(75, 23)
        Me.BrowseForAseImportDirectoryButton.TabIndex = 8
        Me.BrowseForAseImportDirectoryButton.Text = "Browse..."
        Me.BrowseForAseImportDirectoryButton.UseVisualStyleBackColor = True
        '
        'BrowseForOutputDirectoryButton
        '
        Me.BrowseForOutputDirectoryButton.Location = New System.Drawing.Point(523, 46)
        Me.BrowseForOutputDirectoryButton.Name = "BrowseForOutputDirectoryButton"
        Me.BrowseForOutputDirectoryButton.Size = New System.Drawing.Size(75, 23)
        Me.BrowseForOutputDirectoryButton.TabIndex = 7
        Me.BrowseForOutputDirectoryButton.Text = "Browse..."
        Me.BrowseForOutputDirectoryButton.UseVisualStyleBackColor = True
        '
        'BrowseForSourceDirectoryButton
        '
        Me.BrowseForSourceDirectoryButton.Location = New System.Drawing.Point(523, 17)
        Me.BrowseForSourceDirectoryButton.Name = "BrowseForSourceDirectoryButton"
        Me.BrowseForSourceDirectoryButton.Size = New System.Drawing.Size(75, 23)
        Me.BrowseForSourceDirectoryButton.TabIndex = 6
        Me.BrowseForSourceDirectoryButton.Text = "Browse..."
        Me.BrowseForSourceDirectoryButton.UseVisualStyleBackColor = True
        '
        'AseImportDirectoryLabel
        '
        Me.AseImportDirectoryLabel.AutoSize = True
        Me.AseImportDirectoryLabel.Location = New System.Drawing.Point(6, 78)
        Me.AseImportDirectoryLabel.Name = "AseImportDirectoryLabel"
        Me.AseImportDirectoryLabel.Size = New System.Drawing.Size(105, 13)
        Me.AseImportDirectoryLabel.TabIndex = 5
        Me.AseImportDirectoryLabel.Text = "ASE Import Directory"
        '
        'AseImportDirectoryTextBox
        '
        Me.AseImportDirectoryTextBox.Location = New System.Drawing.Point(117, 77)
        Me.AseImportDirectoryTextBox.Name = "AseImportDirectoryTextBox"
        Me.AseImportDirectoryTextBox.Size = New System.Drawing.Size(400, 20)
        Me.AseImportDirectoryTextBox.TabIndex = 4
        '
        'OutputDirectoryLabel
        '
        Me.OutputDirectoryLabel.AutoSize = True
        Me.OutputDirectoryLabel.Location = New System.Drawing.Point(6, 51)
        Me.OutputDirectoryLabel.Name = "OutputDirectoryLabel"
        Me.OutputDirectoryLabel.Size = New System.Drawing.Size(84, 13)
        Me.OutputDirectoryLabel.TabIndex = 3
        Me.OutputDirectoryLabel.Text = "Output Directory"
        '
        'OutputDirectoryTextBox
        '
        Me.OutputDirectoryTextBox.Location = New System.Drawing.Point(117, 48)
        Me.OutputDirectoryTextBox.Name = "OutputDirectoryTextBox"
        Me.OutputDirectoryTextBox.Size = New System.Drawing.Size(400, 20)
        Me.OutputDirectoryTextBox.TabIndex = 2
        '
        'SourceFileDirectoryLabel
        '
        Me.SourceFileDirectoryLabel.AutoSize = True
        Me.SourceFileDirectoryLabel.Location = New System.Drawing.Point(6, 22)
        Me.SourceFileDirectoryLabel.Name = "SourceFileDirectoryLabel"
        Me.SourceFileDirectoryLabel.Size = New System.Drawing.Size(105, 13)
        Me.SourceFileDirectoryLabel.TabIndex = 1
        Me.SourceFileDirectoryLabel.Text = "Source File Directory"
        '
        'SourceDirectoryTextBox
        '
        Me.SourceDirectoryTextBox.Location = New System.Drawing.Point(117, 19)
        Me.SourceDirectoryTextBox.Name = "SourceDirectoryTextBox"
        Me.SourceDirectoryTextBox.Size = New System.Drawing.Size(400, 20)
        Me.SourceDirectoryTextBox.TabIndex = 0
        '
        'SaveButton
        '
        Me.SaveButton.Location = New System.Drawing.Point(541, 120)
        Me.SaveButton.Name = "SaveButton"
        Me.SaveButton.Size = New System.Drawing.Size(75, 23)
        Me.SaveButton.TabIndex = 1
        Me.SaveButton.Text = "Save"
        Me.SaveButton.UseVisualStyleBackColor = True
        '
        'CancelButton1
        '
        Me.CancelButton1.Location = New System.Drawing.Point(460, 120)
        Me.CancelButton1.Name = "CancelButton1"
        Me.CancelButton1.Size = New System.Drawing.Size(75, 23)
        Me.CancelButton1.TabIndex = 2
        Me.CancelButton1.Text = "Cancel"
        Me.CancelButton1.UseVisualStyleBackColor = True
        '
        'ResetButton
        '
        Me.ResetButton.Location = New System.Drawing.Point(27, 120)
        Me.ResetButton.Name = "ResetButton"
        Me.ResetButton.Size = New System.Drawing.Size(150, 23)
        Me.ResetButton.TabIndex = 3
        Me.ResetButton.Text = "Reset To Default Settings"
        Me.ResetButton.UseVisualStyleBackColor = True
        '
        'ToolOptionsDialog
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(628, 155)
        Me.Controls.Add(Me.ResetButton)
        Me.Controls.Add(Me.CancelButton1)
        Me.Controls.Add(Me.SaveButton)
        Me.Controls.Add(Me.GroupBox1)
        Me.Name = "ToolOptionsDialog"
        Me.Text = "Tool Options"
        Me.GroupBox1.ResumeLayout(False)
        Me.GroupBox1.PerformLayout()
        Me.ResumeLayout(False)

    End Sub
    Friend WithEvents GroupBox1 As System.Windows.Forms.GroupBox
    Friend WithEvents BrowseForAseImportDirectoryButton As System.Windows.Forms.Button
    Friend WithEvents BrowseForOutputDirectoryButton As System.Windows.Forms.Button
    Friend WithEvents BrowseForSourceDirectoryButton As System.Windows.Forms.Button
    Friend WithEvents AseImportDirectoryLabel As System.Windows.Forms.Label
    Friend WithEvents AseImportDirectoryTextBox As System.Windows.Forms.TextBox
    Friend WithEvents OutputDirectoryLabel As System.Windows.Forms.Label
    Friend WithEvents OutputDirectoryTextBox As System.Windows.Forms.TextBox
    Friend WithEvents SourceFileDirectoryLabel As System.Windows.Forms.Label
    Friend WithEvents SourceDirectoryTextBox As System.Windows.Forms.TextBox
    Friend WithEvents SaveButton As System.Windows.Forms.Button
    Friend WithEvents CancelButton1 As System.Windows.Forms.Button
    Friend WithEvents FolderBrowserDialog As System.Windows.Forms.FolderBrowserDialog
    Friend WithEvents ResetButton As System.Windows.Forms.Button
End Class
