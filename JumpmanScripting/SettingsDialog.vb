Imports System.IO
Imports System.Configuration

Public Class SettingsDialog
    Public Sub New()
        InitializeComponent()
        CancelButton = CancelButton1
        LoadSettings()
    End Sub

    Private Sub SourceDirectoryBrowseButton_Click(sender As Object, e As EventArgs) Handles SourceDirectoryBrowseButton.Click
        BrowseForDirectory(SourceDirectoryTextBox)
    End Sub

    Private Sub OutputDirectoryBrowseButton_Click(sender As Object, e As EventArgs) Handles OutputDirectoryBrowseButton.Click
        BrowseForDirectory(OutputDirectoryTextBox)
    End Sub

    Private Sub CancelButton1_Click(sender As Object, e As EventArgs) Handles CancelButton1.Click
        LoadSettings()
        Close()
    End Sub

    Private Sub SaveButton_Click(sender As Object, e As EventArgs) Handles SaveButton.Click
        If SaveSettings() Then
            LoadSettings()
            Close()
        End If
    End Sub

    Private Sub ResetButton_Click(sender As Object, e As EventArgs) Handles ResetButton.Click
        If MessageBox.Show("This will wipe out your custom settings. Are you sure?", "Reset To Default", MessageBoxButtons.YesNo) = Windows.Forms.DialogResult.Yes Then
            RestoreDefaultSettings()
            LoadSettings()
        End If
    End Sub

    Private Sub LoadSettings()
        Try
            My.Settings.Reload()
            SourceDirectoryTextBox.Text = My.Settings.SourceDirectory
            OutputDirectoryTextBox.Text = My.Settings.OutputDirectory
        Catch ex As Exception
            If MessageBox.Show("The settings config file was corrupt. Would you like to wipe it out and reload default settings?", "Settings Corrupt", MessageBoxButtons.YesNo) = Windows.Forms.DialogResult.Yes Then
                RestoreDefaultSettings()
                LoadSettings()
            End If
        End Try
    End Sub

    Private Function SaveSettings() As Boolean
        Dim sourceDirectory As String = Path.GetFullPath(SourceDirectoryTextBox.Text)
        Dim outputDirectory As String = Path.GetFullPath(OutputDirectoryTextBox.Text)

        Dim success As Boolean = True

        success = success And EnsureDirectoryExists("Source Directory", sourceDirectory)
        success = success And EnsureDirectoryExists("Output Directory", outputDirectory)

        If success Then
            My.Settings.SourceDirectory = sourceDirectory
            My.Settings.OutputDirectory = outputDirectory
            My.Settings.Save()
        End If

        Return success
    End Function

    Private Sub RestoreDefaultSettings()
        ClearExeConfiguration(ConfigurationUserLevel.PerUserRoamingAndLocal)
        ClearExeConfiguration(ConfigurationUserLevel.PerUserRoaming)
    End Sub

    Private Function EnsureDirectoryExists(directoryDescription As String, fullDirectoryPath As String) As Boolean
        EnsureDirectoryExists = True

        If Not Directory.Exists(fullDirectoryPath) Then
            Try
                Directory.CreateDirectory(fullDirectoryPath)
            Catch ex As Exception
                EnsureDirectoryExists = False
                Dim errorMessage As String = String.Format("{0} does not exist, and we were unable to create it: {1}",
                    directoryDescription,
                    fullDirectoryPath)
                MessageBox.Show(errorMessage)
            End Try
        End If
    End Function

    Private Sub BrowseForDirectory(targetTextBox As TextBox)
        Dim previousDirectory As String = targetTextBox.Text

        FolderBrowserDialog.SelectedPath = If(Directory.Exists(previousDirectory), Path.GetFullPath(previousDirectory), Nothing)
        FolderBrowserDialog.ShowDialog()

        Dim selectedPath As String = FolderBrowserDialog.SelectedPath

        If Directory.Exists(selectedPath) Then
            targetTextBox.Text = selectedPath
        End If
    End Sub

    Private Sub ClearExeConfiguration(userLevel As ConfigurationUserLevel)
        Try
            Dim config As Configuration = ConfigurationManager.OpenExeConfiguration(userLevel)

            If File.Exists(config.FilePath) Then
                File.Delete(config.FilePath)
            End If
        Catch ex As ConfigurationErrorsException
            If File.Exists(ex.Filename) Then
                File.Delete(ex.Filename)
            Else
                Throw
            End If
        End Try
    End Sub
End Class