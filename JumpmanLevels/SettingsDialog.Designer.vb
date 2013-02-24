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
        Me.GroupBox = New System.Windows.Forms.GroupBox()
        Me.LevelSourceDirectoryBrowseButton = New System.Windows.Forms.Button()
        Me.LevelSourceDirectoryTextBox = New System.Windows.Forms.TextBox()
        Me.LevelSourceDirectoryLabel = New System.Windows.Forms.Label()
        Me.LevelCompileOutputDirectoryBrowseButton = New System.Windows.Forms.Button()
        Me.LevelCompileOutputDirectoryTextBox = New System.Windows.Forms.TextBox()
        Me.LevelCompileOutputDirectoryLabel = New System.Windows.Forms.Label()
        Me.ContentResourceDirectoryBrowseButton = New System.Windows.Forms.Button()
        Me.ContentResourceDirectoryTextBox = New System.Windows.Forms.TextBox()
        Me.ContentResourceDirectoryLabel = New System.Windows.Forms.Label()
        Me.SoundResourceDirectoryBrowseButton = New System.Windows.Forms.Button()
        Me.SoundResourceDirectoryTextBox = New System.Windows.Forms.TextBox()
        Me.SoundResourceDirectoryLabel = New System.Windows.Forms.Label()
        Me.SaveButton = New System.Windows.Forms.Button()
        Me.CancelButton1 = New System.Windows.Forms.Button()
        Me.ResetButton = New System.Windows.Forms.Button()
        Me.FolderBrowserDialog = New System.Windows.Forms.FolderBrowserDialog()
        Me.GroupBox.SuspendLayout()
        Me.SuspendLayout()
        '
        'GroupBox
        '
        Me.GroupBox.Controls.Add(Me.LevelSourceDirectoryBrowseButton)
        Me.GroupBox.Controls.Add(Me.LevelSourceDirectoryTextBox)
        Me.GroupBox.Controls.Add(Me.LevelSourceDirectoryLabel)
        Me.GroupBox.Controls.Add(Me.LevelCompileOutputDirectoryBrowseButton)
        Me.GroupBox.Controls.Add(Me.LevelCompileOutputDirectoryTextBox)
        Me.GroupBox.Controls.Add(Me.LevelCompileOutputDirectoryLabel)
        Me.GroupBox.Controls.Add(Me.ContentResourceDirectoryBrowseButton)
        Me.GroupBox.Controls.Add(Me.ContentResourceDirectoryTextBox)
        Me.GroupBox.Controls.Add(Me.ContentResourceDirectoryLabel)
        Me.GroupBox.Controls.Add(Me.SoundResourceDirectoryBrowseButton)
        Me.GroupBox.Controls.Add(Me.SoundResourceDirectoryTextBox)
        Me.GroupBox.Controls.Add(Me.SoundResourceDirectoryLabel)
        Me.GroupBox.Location = New System.Drawing.Point(12, 12)
        Me.GroupBox.Name = "GroupBox"
        Me.GroupBox.Size = New System.Drawing.Size(656, 135)
        Me.GroupBox.TabIndex = 0
        Me.GroupBox.TabStop = False
        Me.GroupBox.Text = "Paths"
        '
        'LevelSourceDirectoryBrowseButton
        '
        Me.LevelSourceDirectoryBrowseButton.Location = New System.Drawing.Point(575, 77)
        Me.LevelSourceDirectoryBrowseButton.Name = "LevelSourceDirectoryBrowseButton"
        Me.LevelSourceDirectoryBrowseButton.Size = New System.Drawing.Size(75, 23)
        Me.LevelSourceDirectoryBrowseButton.TabIndex = 11
        Me.LevelSourceDirectoryBrowseButton.Text = "Browse..."
        Me.LevelSourceDirectoryBrowseButton.UseVisualStyleBackColor = True
        '
        'LevelSourceDirectoryTextBox
        '
        Me.LevelSourceDirectoryTextBox.Location = New System.Drawing.Point(169, 79)
        Me.LevelSourceDirectoryTextBox.Name = "LevelSourceDirectoryTextBox"
        Me.LevelSourceDirectoryTextBox.Size = New System.Drawing.Size(400, 20)
        Me.LevelSourceDirectoryTextBox.TabIndex = 10
        '
        'LevelSourceDirectoryLabel
        '
        Me.LevelSourceDirectoryLabel.AutoSize = True
        Me.LevelSourceDirectoryLabel.Location = New System.Drawing.Point(6, 82)
        Me.LevelSourceDirectoryLabel.Name = "LevelSourceDirectoryLabel"
        Me.LevelSourceDirectoryLabel.Size = New System.Drawing.Size(115, 13)
        Me.LevelSourceDirectoryLabel.TabIndex = 9
        Me.LevelSourceDirectoryLabel.Text = "Level Source Directory"
        '
        'LevelCompileOutputDirectoryBrowseButton
        '
        Me.LevelCompileOutputDirectoryBrowseButton.Location = New System.Drawing.Point(575, 106)
        Me.LevelCompileOutputDirectoryBrowseButton.Name = "LevelCompileOutputDirectoryBrowseButton"
        Me.LevelCompileOutputDirectoryBrowseButton.Size = New System.Drawing.Size(75, 23)
        Me.LevelCompileOutputDirectoryBrowseButton.TabIndex = 8
        Me.LevelCompileOutputDirectoryBrowseButton.Text = "Browse..."
        Me.LevelCompileOutputDirectoryBrowseButton.UseVisualStyleBackColor = True
        '
        'LevelCompileOutputDirectoryTextBox
        '
        Me.LevelCompileOutputDirectoryTextBox.Location = New System.Drawing.Point(169, 108)
        Me.LevelCompileOutputDirectoryTextBox.Name = "LevelCompileOutputDirectoryTextBox"
        Me.LevelCompileOutputDirectoryTextBox.Size = New System.Drawing.Size(400, 20)
        Me.LevelCompileOutputDirectoryTextBox.TabIndex = 7
        '
        'LevelCompileOutputDirectoryLabel
        '
        Me.LevelCompileOutputDirectoryLabel.AutoSize = True
        Me.LevelCompileOutputDirectoryLabel.Location = New System.Drawing.Point(6, 111)
        Me.LevelCompileOutputDirectoryLabel.Name = "LevelCompileOutputDirectoryLabel"
        Me.LevelCompileOutputDirectoryLabel.Size = New System.Drawing.Size(153, 13)
        Me.LevelCompileOutputDirectoryLabel.TabIndex = 6
        Me.LevelCompileOutputDirectoryLabel.Text = "Level Compile Output Directory"
        '
        'ContentResourceDirectoryBrowseButton
        '
        Me.ContentResourceDirectoryBrowseButton.Location = New System.Drawing.Point(575, 48)
        Me.ContentResourceDirectoryBrowseButton.Name = "ContentResourceDirectoryBrowseButton"
        Me.ContentResourceDirectoryBrowseButton.Size = New System.Drawing.Size(75, 23)
        Me.ContentResourceDirectoryBrowseButton.TabIndex = 5
        Me.ContentResourceDirectoryBrowseButton.Text = "Browse..."
        Me.ContentResourceDirectoryBrowseButton.UseVisualStyleBackColor = True
        '
        'ContentResourceDirectoryTextBox
        '
        Me.ContentResourceDirectoryTextBox.Location = New System.Drawing.Point(169, 50)
        Me.ContentResourceDirectoryTextBox.Name = "ContentResourceDirectoryTextBox"
        Me.ContentResourceDirectoryTextBox.Size = New System.Drawing.Size(400, 20)
        Me.ContentResourceDirectoryTextBox.TabIndex = 4
        '
        'ContentResourceDirectoryLabel
        '
        Me.ContentResourceDirectoryLabel.AutoSize = True
        Me.ContentResourceDirectoryLabel.Location = New System.Drawing.Point(6, 53)
        Me.ContentResourceDirectoryLabel.Name = "ContentResourceDirectoryLabel"
        Me.ContentResourceDirectoryLabel.Size = New System.Drawing.Size(138, 13)
        Me.ContentResourceDirectoryLabel.TabIndex = 3
        Me.ContentResourceDirectoryLabel.Text = "Content Resource Directory"
        '
        'SoundResourceDirectoryBrowseButton
        '
        Me.SoundResourceDirectoryBrowseButton.Location = New System.Drawing.Point(575, 19)
        Me.SoundResourceDirectoryBrowseButton.Name = "SoundResourceDirectoryBrowseButton"
        Me.SoundResourceDirectoryBrowseButton.Size = New System.Drawing.Size(75, 23)
        Me.SoundResourceDirectoryBrowseButton.TabIndex = 2
        Me.SoundResourceDirectoryBrowseButton.Text = "Browse..."
        Me.SoundResourceDirectoryBrowseButton.UseVisualStyleBackColor = True
        '
        'SoundResourceDirectoryTextBox
        '
        Me.SoundResourceDirectoryTextBox.Location = New System.Drawing.Point(169, 21)
        Me.SoundResourceDirectoryTextBox.Name = "SoundResourceDirectoryTextBox"
        Me.SoundResourceDirectoryTextBox.Size = New System.Drawing.Size(400, 20)
        Me.SoundResourceDirectoryTextBox.TabIndex = 1
        '
        'SoundResourceDirectoryLabel
        '
        Me.SoundResourceDirectoryLabel.AutoSize = True
        Me.SoundResourceDirectoryLabel.Location = New System.Drawing.Point(6, 24)
        Me.SoundResourceDirectoryLabel.Name = "SoundResourceDirectoryLabel"
        Me.SoundResourceDirectoryLabel.Size = New System.Drawing.Size(132, 13)
        Me.SoundResourceDirectoryLabel.TabIndex = 0
        Me.SoundResourceDirectoryLabel.Text = "Sound Resource Directory"
        '
        'SaveButton
        '
        Me.SaveButton.Location = New System.Drawing.Point(587, 153)
        Me.SaveButton.Name = "SaveButton"
        Me.SaveButton.Size = New System.Drawing.Size(75, 23)
        Me.SaveButton.TabIndex = 1
        Me.SaveButton.Text = "Save"
        Me.SaveButton.UseVisualStyleBackColor = True
        '
        'CancelButton1
        '
        Me.CancelButton1.Location = New System.Drawing.Point(506, 153)
        Me.CancelButton1.Name = "CancelButton1"
        Me.CancelButton1.Size = New System.Drawing.Size(75, 23)
        Me.CancelButton1.TabIndex = 2
        Me.CancelButton1.Text = "Cancel"
        Me.CancelButton1.UseVisualStyleBackColor = True
        '
        'ResetButton
        '
        Me.ResetButton.Location = New System.Drawing.Point(21, 153)
        Me.ResetButton.Name = "ResetButton"
        Me.ResetButton.Size = New System.Drawing.Size(150, 23)
        Me.ResetButton.TabIndex = 3
        Me.ResetButton.Text = "Reset To Default Settings"
        Me.ResetButton.UseVisualStyleBackColor = True
        '
        'SettingsDialog
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(680, 188)
        Me.Controls.Add(Me.ResetButton)
        Me.Controls.Add(Me.CancelButton1)
        Me.Controls.Add(Me.SaveButton)
        Me.Controls.Add(Me.GroupBox)
        Me.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog
        Me.MaximizeBox = False
        Me.MinimizeBox = False
        Me.Name = "SettingsDialog"
        Me.SizeGripStyle = System.Windows.Forms.SizeGripStyle.Hide
        Me.Text = "Settings"
        Me.GroupBox.ResumeLayout(False)
        Me.GroupBox.PerformLayout()
        Me.ResumeLayout(False)

    End Sub
    Friend WithEvents GroupBox As System.Windows.Forms.GroupBox
    Friend WithEvents SoundResourceDirectoryLabel As System.Windows.Forms.Label
    Friend WithEvents ContentResourceDirectoryBrowseButton As System.Windows.Forms.Button
    Friend WithEvents ContentResourceDirectoryTextBox As System.Windows.Forms.TextBox
    Friend WithEvents ContentResourceDirectoryLabel As System.Windows.Forms.Label
    Friend WithEvents SoundResourceDirectoryBrowseButton As System.Windows.Forms.Button
    Friend WithEvents SoundResourceDirectoryTextBox As System.Windows.Forms.TextBox
    Friend WithEvents LevelCompileOutputDirectoryBrowseButton As System.Windows.Forms.Button
    Friend WithEvents LevelCompileOutputDirectoryTextBox As System.Windows.Forms.TextBox
    Friend WithEvents LevelCompileOutputDirectoryLabel As System.Windows.Forms.Label
    Friend WithEvents LevelSourceDirectoryBrowseButton As System.Windows.Forms.Button
    Friend WithEvents LevelSourceDirectoryTextBox As System.Windows.Forms.TextBox
    Friend WithEvents LevelSourceDirectoryLabel As System.Windows.Forms.Label
    Friend WithEvents SaveButton As System.Windows.Forms.Button
    Friend WithEvents CancelButton1 As System.Windows.Forms.Button
    Friend WithEvents ResetButton As System.Windows.Forms.Button
    Friend WithEvents FolderBrowserDialog As System.Windows.Forms.FolderBrowserDialog
End Class
