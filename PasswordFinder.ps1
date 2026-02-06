Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Password Finder Test (WPF)"
        Height="470"
        Width="860"
        WindowStartupLocation="CenterScreen"
        ResizeMode="CanResize">
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="190"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <TextBlock Grid.Row="0" Grid.Column="0" Margin="0,0,8,10" VerticalAlignment="Center" FontWeight="SemiBold">Passwort:</TextBlock>
        <PasswordBox x:Name="PasswordInput" Grid.Row="0" Grid.Column="1" Height="30" Margin="0,0,0,10"/>

        <TextBlock Grid.Row="1" Grid.Column="0" Margin="0,0,8,10" VerticalAlignment="Top" FontWeight="SemiBold">Zeichenkategorien:</TextBlock>
        <StackPanel Grid.Row="1" Grid.Column="1" Orientation="Horizontal" Margin="0,0,0,10">
            <CheckBox x:Name="LettersCheckbox" IsChecked="True" Margin="0,0,20,0">Buchstaben</CheckBox>
            <CheckBox x:Name="NumbersCheckbox" IsChecked="True" Margin="0,0,20,0">Zahlen</CheckBox>
            <CheckBox x:Name="SpecialCheckbox" IsChecked="True" Margin="0,0,20,0">Sonderzeichen</CheckBox>
            <CheckBox x:Name="AccentCheckbox" IsChecked="True">Sonderbuchstaben</CheckBox>
        </StackPanel>

        <StackPanel Grid.Row="2" Grid.Column="1" Orientation="Horizontal" Margin="0,0,0,14">
            <Button x:Name="StartButton" Width="130" Height="34" Margin="0,0,8,0">Start</Button>
            <Button x:Name="StopButton" Width="130" Height="34" IsEnabled="False">Abbrechen</Button>
        </StackPanel>

        <TextBlock Grid.Row="3" Grid.Column="0" Margin="0,0,8,10" VerticalAlignment="Center" FontWeight="SemiBold">Status:</TextBlock>
        <TextBlock x:Name="StatusText" Grid.Row="3" Grid.Column="1" Margin="0,0,0,10" VerticalAlignment="Center">Bereit</TextBlock>

        <TextBlock Grid.Row="4" Grid.Column="0" Margin="0,0,8,10" VerticalAlignment="Center" FontWeight="SemiBold">Zeit:</TextBlock>
        <TextBlock x:Name="ElapsedText" Grid.Row="4" Grid.Column="1" Margin="0,0,0,10" VerticalAlignment="Center">00:00.000</TextBlock>

        <TextBlock Grid.Row="5" Grid.Column="0" Margin="0,0,8,10" VerticalAlignment="Center" FontWeight="SemiBold">Versuche:</TextBlock>
        <TextBlock x:Name="AttemptsText" Grid.Row="5" Grid.Column="1" Margin="0,0,0,10" VerticalAlignment="Center">0</TextBlock>

        <GroupBox Grid.Row="6" Grid.Column="0" Grid.ColumnSpan="2" Header="Aktueller Versuch" Padding="10">
            <TextBox x:Name="CurrentAttemptText" IsReadOnly="True" Height="30" VerticalContentAlignment="Center"/>
        </GroupBox>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$passwordInput = $window.FindName('PasswordInput')
$lettersCheckbox = $window.FindName('LettersCheckbox')
$numbersCheckbox = $window.FindName('NumbersCheckbox')
$specialCheckbox = $window.FindName('SpecialCheckbox')
$accentCheckbox = $window.FindName('AccentCheckbox')
$startButton = $window.FindName('StartButton')
$stopButton = $window.FindName('StopButton')
$statusText = $window.FindName('StatusText')
$elapsedText = $window.FindName('ElapsedText')
$attemptsText = $window.FindName('AttemptsText')
$currentAttemptText = $window.FindName('CurrentAttemptText')

$script:startTime = $null
$script:attemptCount = 0L

function Format-Duration([TimeSpan]$duration) {
    '{0:D2}:{1:D2}.{2:D3}' -f [int]$duration.TotalMinutes, $duration.Seconds, $duration.Milliseconds
}

function Set-UiRunning([bool]$running) {
    $passwordInput.IsEnabled = -not $running
    $lettersCheckbox.IsEnabled = -not $running
    $numbersCheckbox.IsEnabled = -not $running
    $specialCheckbox.IsEnabled = -not $running
    $accentCheckbox.IsEnabled = -not $running
    $startButton.IsEnabled = -not $running
    $stopButton.IsEnabled = $running
}

function Get-CharacterSet {
    $lower = 'abcdefghijklmnopqrstuvwxyz'
    $upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $digits = '0123456789'
    $special = '!"#$%&''()*+,-./:;<=>?@[\]^_`{|}~'
    $accent = 'äöüÄÖÜßàáâãåāçćčèéêëēìíîïīñńòóôõøōùúûüūýÿžźż'

    $builder = New-Object System.Text.StringBuilder
    if ($lettersCheckbox.IsChecked) {
        [void]$builder.Append($lower)
        [void]$builder.Append($upper)
    }
    if ($numbersCheckbox.IsChecked) {
        [void]$builder.Append($digits)
    }
    if ($specialCheckbox.IsChecked) {
        [void]$builder.Append($special)
    }
    if ($accentCheckbox.IsChecked) {
        [void]$builder.Append($accent)
    }

    $raw = $builder.ToString()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    $set = New-Object 'System.Collections.Generic.HashSet[char]'
    $chars = New-Object 'System.Collections.Generic.List[char]'
    foreach ($ch in $raw.ToCharArray()) {
        if ($set.Add($ch)) {
            [void]$chars.Add($ch)
        }
    }
    return $chars.ToArray()
}

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(50)
$timer.Add_Tick({
    if ($script:startTime) {
        $elapsedText.Text = Format-Duration ((Get-Date) - $script:startTime)
    }
    $attemptsText.Text = [string]$script:attemptCount
})

$worker = New-Object System.ComponentModel.BackgroundWorker
$worker.WorkerSupportsCancellation = $true

$worker.add_DoWork({
    param($sender, $e)

    $args = $e.Argument
    $targetValue = [string]$args.Target
    [char[]]$characters = $args.Characters

    $attempts = 0L
    $lastAttempt = ''
    $found = $false
    $aborted = $false

    for ($length = 1; $length -le $targetValue.Length; $length++) {
        $indices = New-Object int[] $length
        while ($true) {
            if ($sender.CancellationPending) {
                $aborted = $true
                break
            }

            $buffer = New-Object char[] $length
            for ($i = 0; $i -lt $length; $i++) {
                $buffer[$i] = $characters[$indices[$i]]
            }
            $candidate = -join $buffer
            $lastAttempt = $candidate
            $attempts++

            if (($attempts % 300) -eq 0) {
                $window.Dispatcher.BeginInvoke([action]{
                    $currentAttemptText.Text = $lastAttempt
                    $attemptsText.Text = [string]$attempts
                }) | Out-Null
            }

            if ($candidate -ceq $targetValue) {
                $found = $true
                break
            }

            $pos = $length - 1
            while ($pos -ge 0) {
                $indices[$pos]++
                if ($indices[$pos] -lt $characters.Length) {
                    break
                }
                $indices[$pos] = 0
                $pos--
            }

            if ($pos -lt 0) {
                break
            }
        }

        if ($found -or $aborted) {
            break
        }
    }

    $e.Result = @{
        Found = $found
        Aborted = $aborted
        LastAttempt = $lastAttempt
        Attempts = $attempts
    }
})

$worker.add_RunWorkerCompleted({
    param($sender, $e)

    $timer.Stop()
    if ($script:startTime) {
        $elapsedText.Text = Format-Duration ((Get-Date) - $script:startTime)
    }

    if ($e.Error) {
        $statusText.Text = 'Fehler aufgetreten'
        [System.Windows.MessageBox]::Show("Fehler: $($e.Error.Message)", 'Fehler', 'OK', 'Error') | Out-Null
        Set-UiRunning $false
        $script:startTime = $null
        return
    }

    $result = $e.Result
    $script:attemptCount = [long]$result.Attempts
    $attemptsText.Text = [string]$script:attemptCount
    $currentAttemptText.Text = [string]$result.LastAttempt

    if ($result.Aborted) {
        $statusText.Text = 'Abgebrochen'
    } elseif ($result.Found) {
        $statusText.Text = 'Passwort gefunden'
    } else {
        $statusText.Text = 'Nicht gefunden'
    }

    Set-UiRunning $false
    $script:startTime = $null
})

$startButton.Add_Click({
    if ($worker.IsBusy) {
        return
    }

    $target = $passwordInput.Password
    if ([string]::IsNullOrWhiteSpace($target)) {
        [System.Windows.MessageBox]::Show('Bitte zuerst ein Passwort eingeben.', 'Hinweis', 'OK', 'Information') | Out-Null
        return
    }

    [char[]]$charArray = Get-CharacterSet
    if ($charArray.Length -eq 0) {
        [System.Windows.MessageBox]::Show('Bitte mindestens eine Zeichenkategorie auswählen.', 'Hinweis', 'OK', 'Warning') | Out-Null
        return
    }

    foreach ($ch in $target.ToCharArray()) {
        if ($charArray -notcontains $ch) {
            [System.Windows.MessageBox]::Show('Das Passwort enthält Zeichen, die nicht in den gewählten Kategorien enthalten sind.', 'Zeichen nicht enthalten', 'OK', 'Warning') | Out-Null
            return
        }
    }

    $script:startTime = Get-Date
    $script:attemptCount = 0L

    $statusText.Text = 'Läuft ...'
    $elapsedText.Text = '00:00.000'
    $attemptsText.Text = '0'
    $currentAttemptText.Text = ''

    Set-UiRunning $true
    $timer.Start()

    $worker.RunWorkerAsync(@{
        Target = $target
        Characters = $charArray
    })
})

$stopButton.Add_Click({
    if ($worker.IsBusy) {
        $worker.CancelAsync()
    }
})

$window.ShowDialog() | Out-Null
