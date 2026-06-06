Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Global Variables to preserve state ---
$action = $null
$perm = $null
$memberList = @()
$folderPaths = @()
$stepHistory = New-Object System.Collections.Stack

# --- Reusable Forms ---
function Show-ListBoxForm {
    param (
        [string]$Title,
        [string[]]$Options,
        [string]$Default = $null
    )

    $form = New-Object Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object Drawing.Size(400, 400)
    $form.StartPosition = "CenterScreen"

    $listBox = New-Object Windows.Forms.ListBox
    $listBox.Location = New-Object Drawing.Point(10, 10)
    $listBox.Size = New-Object Drawing.Size(360, 300)
    $listBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $listBox.SelectionMode = 'One'
    $listBox.Items.AddRange($Options)
    if ($Default -and $Options -contains $Default) {
        $listBox.SelectedItem = $Default
    }
    $form.Controls.Add($listBox)

    $listBox.Add_DoubleClick({
        if ($listBox.SelectedItem) {
            $form.Tag = $listBox.SelectedItem
            $form.Close()
        }
    })

    $okButton = New-Object Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object Drawing.Point(200, 320)
    $okButton.Size = New-Object Drawing.Size(75, 30)
    $okButton.Add_Click({
        if ($listBox.SelectedItem) {
            $form.Tag = $listBox.SelectedItem
            $form.Close()
        }
    })
    $form.Controls.Add($okButton)

    $backButton = New-Object Windows.Forms.Button
    $backButton.Text = "< Back"
    $backButton.Location = New-Object Drawing.Point(100, 320)
    $backButton.Size = New-Object Drawing.Size(75, 30)
    $backButton.Add_Click({
        $form.Tag = "__BACK__"
        $form.Close()
    })
    $form.Controls.Add($backButton)

    $exitButton = New-Object Windows.Forms.Button
    $exitButton.Text = "Exit"
    $exitButton.Location = New-Object Drawing.Point(10, 320)
    $exitButton.Size = New-Object Drawing.Size(75, 30)
    $exitButton.Add_Click({
        $form.Tag = "__EXIT__"
        $form.Close()
    })
    $form.Controls.Add($exitButton)

    $form.Topmost = $true
    [void]$form.ShowDialog()
    return $form.Tag
}

function Show-MultiLineInputBox {
    param (
        [string]$Title,
        [string]$InitialText = ""
    )
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Width = 600
    $form.Height = 400
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.Topmost = $true

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Multiline = $true
    $textbox.ScrollBars = 'Vertical'
    $textbox.Text = $InitialText
    $textbox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textbox.SetBounds(10, 10, 560, 300)
    $form.Controls.Add($textbox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Size = New-Object System.Drawing.Size(90, 30)
    $okButton.Location = New-Object System.Drawing.Point(370, 320)
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okButton)

    $backButton = New-Object System.Windows.Forms.Button
    $backButton.Text = "< Back"
    $backButton.Size = New-Object System.Drawing.Size(90, 30)
    $backButton.Location = New-Object System.Drawing.Point(270, 320)
    $backButton.Add_Click({
        $textbox.Text = "__BACK__"
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $form.Controls.Add($backButton)

    $form.AcceptButton = $okButton
    $form.CancelButton = $okButton

    if ($form.ShowDialog() -eq 'OK') {
        return $textbox.Text -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    } else {
        return $null
    }
}

function Go-Step($stepName) {
    switch ($stepName) {
        "action" {
            $choice = Show-ListBoxForm -Title "Choose Action" -Options @("Add Permissions", "Remove Permissions", "Exit")
            if ($choice -eq "__BACK__") {
                if ($stepHistory.Count -gt 0) { Go-Step $stepHistory.Pop() }
                return
            }
            if ($choice -eq "__EXIT__" -or !$choice) { exit }
            $stepHistory.Push("action")
            $script:action = $choice
            if ($action -eq "Remove Permissions") { $script:perm = $null }
            Go-Step "perm"
        }
        "perm" {
            if ($action -ne "Add Permissions") {
                Go-Step "users"
                return
            }
            $choice = Show-ListBoxForm -Title "Choose Permission" -Options @("FullControl", "Modify", "ReadAndExecute") -Default $perm
            if ($choice -eq "__BACK__") {
                if ($stepHistory.Count -gt 0) { Go-Step $stepHistory.Pop() }
                return
            }
            if ($choice -eq "__EXIT__" -or !$choice) { exit }
            $stepHistory.Push("perm")
            $script:perm = $choice
            Go-Step "users"
        }
        "users" {
            $initial = if ($memberList) { $memberList -join "`r`n" } else { "" }
            $inputs = Show-MultiLineInputBox -Title "Enter users/groups/emails/display names" -InitialText $initial
            if ($inputs -contains "__BACK__") {
                if ($stepHistory.Count -gt 0) { Go-Step $stepHistory.Pop() }
                return
            }
            if (-not $inputs) { exit }
            $stepHistory.Push("users")
            $script:memberList = $inputs
            Go-Step "paths"
        }
        "paths" {
            $initial = if ($folderPaths) { $folderPaths -join "`r`n" } else { "" }
            $inputs = Show-MultiLineInputBox -Title "Enter folder paths" -InitialText $initial
            if ($inputs -contains "__BACK__") {
                if ($stepHistory.Count -gt 0) { Go-Step $stepHistory.Pop() }
                return
            }
            if (-not $inputs) { exit }
            $script:folderPaths = $inputs | ForEach-Object {
                $_ -replace '^[\s"''`n`r]+', '' -replace '[\s"''`n`r]+$', '' -replace '[\\/]+$', ''
            } | Where-Object { $_ -ne "" }
            $stepHistory.Push("paths")
            Go-Step "confirm"
        }
        "confirm" {
            $confirm = Show-MultiLineInputBox -Title "Confirm cleaned folder paths" -InitialText ($folderPaths -join "`r`n")
            if ($confirm -contains "__BACK__") {
                if ($stepHistory.Count -gt 0) { Go-Step $stepHistory.Pop() }
                return
            }
            if (-not $confirm) { exit }
            $stepHistory.Push("confirm")
            Go-Step "process"
        }
        "process" {
            $domains = (Get-ADForest).Domains
            $results = @()
            $successCount = 0
            $failCount = 0

            foreach ($folder in $folderPaths) {
                if (-not (Test-Path $folder)) {
                    $results += "❌ Folder not found: $folder"
                    $failCount += $memberList.Count
                    continue
                }

                foreach ($input in $memberList) {
                    $resolvedAccount = $null
                    foreach ($domain in $domains) {
                        try {
                            $user = Get-ADUser -Filter { (SamAccountName -eq $input) -or (mail -eq $input) -or (DisplayName -eq $input) } -Server $domain -ErrorAction SilentlyContinue
                            if ($user) { $resolvedAccount = $user.SID; break }
                            $group = Get-ADGroup -Filter { (Name -eq $input) -or (DisplayName -eq $input) } -Server $domain -ErrorAction SilentlyContinue
                            if ($group) { $resolvedAccount = $group.SID; break }
                        } catch {}
                    }

                    if (-not $resolvedAccount) {
                        $results += "❌ '$input' not found for folder '$folder'"
                        $failCount++
                        continue
                    }

                    try {
                        $acl = Get-Acl -Path $folder
                        $identity = New-Object System.Security.Principal.NTAccount((New-Object System.Security.Principal.SecurityIdentifier($resolvedAccount)).Translate([System.Security.Principal.NTAccount]).Value)

                        if ($action -eq "Add Permissions") {
                            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, $perm, "ContainerInherit,ObjectInherit", "None", "Allow")
                            $acl.AddAccessRule($accessRule)
                            Set-Acl -Path $folder -AclObject $acl
                            $results += "✅ Added '$identity' to '$folder' with '$perm'"
                        } else {
                            $existingRules = $acl.Access | Where-Object { $_.IdentityReference -eq $identity }
                            if ($existingRules.Count -gt 0) {
                                foreach ($rule in $existingRules) {
                                    $acl.RemoveAccessRule($rule)
                                }
                                Set-Acl -Path $folder -AclObject $acl
                                $results += "✅ Removed '$identity' from '$folder'"
                            } else {
                                $results += "⚠️ No permissions for '$identity' on '$folder'"
                            }
                        }

                        $successCount++
                    } catch {
                        $results += "❌ Error on '$input' at '$folder': $_"
                        $failCount++
                    }
                }
            }

            $results += ""
            $results += "===== SUMMARY ====="
            $results += "Action: $action"
            if ($perm) { $results += "Permission: $perm" }
            $results += "Folders affected: $($folderPaths.Count)"
            $results += "Users processed: $($memberList.Count * $folderPaths.Count)"
            $results += "✅ Successes: $successCount"
            $results += "❌ Failures: $failCount"

            Show-MultiLineInputBox -Title "Execution Summary" -InitialText ($results -join "`r`n") | Out-Null

            # Ask to run again
            $restart = Show-ListBoxForm -Title "Run again?" -Options @("Yes", "No")
            if ($restart -ne "Yes") { exit }

            $script:action = $null
            $script:perm = $null
            $script:memberList = @()
            $script:folderPaths = @()
            $stepHistory.Clear()
            Go-Step "action"
        }
    }
}

# Start from the beginning
Go-Step "action" 


