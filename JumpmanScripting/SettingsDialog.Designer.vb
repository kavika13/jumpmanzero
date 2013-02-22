<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class SettingsDialog
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
        Me.PathsGroupBox = New System.Windows.Forms.GroupBox()
        Me.OutputDirectoryLabel = New System.Windows.Forms.Label()
        Me.SourceDirectoryLabel = New System.Windows.Forms.Label()
        Me.OutputDirectoryTextBox = New System.Windows.Forms.TextBox()
        Me.SourceDirectoryTextBox = New System.Windows.Forms.TextBox()
        Me.OutputDirectoryBrowseButton = New System.Windows.Forms.Button()
        Me.SourceDirectoryBrowseButton = New System.Windows.Forms.Button()
        Me.SaveButton = New System.Windows.Forms.Button()
        Me.CancelButton1 = New System.Windows.Forms.Button()
        Me.ResetButton = New System.Windows.Forms.Button()
        Me.FolderBrowserDialog = New System.Windows.Forms.FolderBrowserDialog()
        Me.PathsGroupBox.SuspendLayout()
        Me.SuspendLayout()
        '
        'PathsGroupBox
        '
        Me.PathsGroupBox.Controls.Add(Me.OutputDirectoryLabel)
        Me.PathsGroupBox.Controls.Add(Me.SourceDirectoryLabel)
        Me.PathsGroupBox.Controls.Add(Me.OutputDirectoryTextBox)
        Me.PathsGroupBox.Controls.Add(Me.SourceDirectoryTextBox)
        Me.PathsGroupBox.Controls.Add(Me.OutputDirectoryBrowseButton)
        Me.PathsGroupBox.Controls.Add(Me.SourceDirectoryBrowseButton)
        Me.PathsGroupBox.Location = New System.Drawing.Point(12, 12)
        Me.PathsGroupBox.Name = "PathsGroupBox"
        Me.PathsGroupBox.Size = New System.Drawing.Size(585, 77)
        Me.PathsGroupBox.TabIndex = 0
        Me.PathsGroupBox.TabStop = False
        Me.PathsGroupBox.Text = "Paths"
        '
        'OutputDirectoryLabel
        '
        Me.OutputDirectoryLabel.AutoSize = True
        Me.OutputDirectoryLabel.Location = New System.Drawing.Point(6, 53)
        Me.OutputDirectoryLabel.Name = "OutputDirectoryLabel"
        Me.OutputDirectoryLabel.Size = New System.Drawing.Size(84, 13)
        Me.OutputDirectoryLabel.TabIndex = 5
        Me.OutputDirectoryLabel.Text = "Output Directory"
        '
        'SourceDirectoryLabel
        '
        Me.SourceDirectoryLabel.AutoSize = True
        Me.SourceDirectoryLabel.Location = New System.Drawing.Point(6, 24)
        Me.SourceDirectoryLabel.Name = "SourceDirectoryLabel"
        Me.SourceDirectoryLabel.Size = New System.Drawing.Size(86, 13)
        Me.SourceDirectoryLabel.TabIndex = 4
        Me.SourceDirectoryLabel.Text = "Source Directory"
        '
        'OutputDirectoryTextBox
        '
        Me.OutputDirectoryTextBox.Location = New System.Drawing.Point(98, 50)
        Me.OutputDirectoryTextBox.Name = "OutputDirectoryTextBox"
        Me.OutputDirectoryTextBox.Size = New System.Drawing.Size(400, 20)
        Me.OutputDirectoryTextBox.TabIndex = 3
        '
        'SourceDirectoryTextBox
        '
        Me.SourceDirectoryTextBox.Location = New System.Drawing.Point(98, 21)
        Me.SourceDirectoryTextBox.Name = "SourceDirectoryTextBox"
        Me.SourceDirectoryTextBox.Size = New System.Drawing.Size(400, 20)
        Me.SourceDirectoryTextBox.TabIndex = 2
        '
        'OutputDirectoryBrowseButton
        '
        Me.OutputDirectoryBrowseButton.Location = New System.Drawing.Point(504, 48)
        Me.OutputDirectoryBrowseButton.Name = "OutputDirectoryBrowseButton"
        Me.OutputDirectoryBrowseButton.Size = New System.Drawing.Size(75, 23)
        Me.OutputDirectoryBrowseButton.TabIndex = 1
        Me.OutputDirectoryBrowseButton.Text = "Browse..."
        Me.OutputDirectoryBrowseButton.UseVisualStyleBackColor = True
        '
        'SourceDirectoryBrowseButton
        '
        Me.SourceDirectoryBrowseButton.Location = New System.Drawing.Point(504, 19)
        Me.SourceDirectoryBrowseButton.Name = "SourceDirectoryBrowseButton"
        Me.SourceDirectoryBrowseButton.Size = New System.Drawing.Size(75, 23)
        Me.SourceDirectoryBrowseButton.TabIndex = 0
        Me.SourceDirectoryBrowseButton.Text = "Browse..."
        Me.SourceDirectoryBrowseButton.UseVisualStyleBackColor = True
        '
        'SaveButton
        '
        Me.SaveButton.Location = New System.Drawing.Point(516, 95)
        Me.SaveButton.Name = "SaveButton"
        Me.SaveButton.Size = New System.Drawing.Size(75, 23)
        Me.SaveButton.TabIndex = 6
        Me.SaveButton.Text = "Save"
        Me.SaveButton.UseVisualStyleBackColor = True
        '
        'CancelButton1
        '
        Me.CancelButton1.Location = New System.Drawing.Point(435, 95)
        Me.CancelButton1.Name = "CancelButton1"
        Me.CancelButton1.Size = New System.Drawing.Size(75, 23)
        Me.CancelButton1.TabIndex = 7
        Me.CancelButton1.Text = "Cancel"
        Me.CancelButton1.UseVisualStyleBackColor = True
        '
        'ResetButton
        '
        Me.ResetButton.Location = New System.Drawing.Point(21, 95)
        Me.ResetButton.Name = "ResetButton"
        Me.ResetButton.Size = New System.Drawing.Size(150, 23)
        Me.ResetButton.TabIndex = 8
        Me.ResetButton.Text = "Reset To Default Settings"
        Me.ResetButton.UseVisualStyleBackColor = True
        '
        'SettingsDialog
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(609, 130)
        Me.Controls.Add(Me.ResetButton)
        Me.Controls.Add(Me.CancelButton1)
        Me.Controls.Add(Me.SaveButton)
        Me.Controls.Add(Me.PathsGroupBox)
        Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog
        Me.MaximizeBox = False
        Me.MinimizeBox = False
        Me.Name = "SettingsDialog"
        Me.Text = "Settings"
        Me.PathsGroupBox.ResumeLayout(False)
        Me.PathsGroupBox.PerformLayout()
        Me.ResumeLayout(False)

    End Sub
    Friend WithEvents PathsGroupBox As System.Windows.Forms.GroupBox
    Friend WithEvents OutputDirectoryLabel As System.Windows.Forms.Label
    Friend WithEvents SourceDirectoryLabel As System.Windows.Forms.Label
    Friend WithEvents OutputDirectoryTextBox As System.Windows.Forms.TextBox
    Friend WithEvents SourceDirectoryTextBox As System.Windows.Forms.TextBox
    Friend WithEvents OutputDirectoryBrowseButton As System.Windows.Forms.Button
    Friend WithEvents SourceDirectoryBrowseButton As System.Windows.Forms.Button
    Friend WithEvents SaveButton As System.Windows.Forms.Button
    Friend WithEvents CancelButton1 As System.Windows.Forms.Button
    Friend WithEvents ResetButton As System.Windows.Forms.Button
    Friend WithEvents FolderBrowserDialog As System.Windows.Forms.FolderBrowserDialog
End Class
