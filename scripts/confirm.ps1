#Requires -Version 5.1
<#
.SYNOPSIS
    Konsistente Benutzerabfrage f?r MINTutil
.DESCRIPTION
    Bietet eine einheitliche Ja/Nein-Abfrage mit verschiedenen Modi.
    Unterst?tzt Default-Werte, Timeouts und Farb-Hervorhebung.
.PARAMETER Message
    Die Frage, die dem Benutzer gestellt wird
.PARAMETER Default
    Standard-Antwort wenn Enter gedr?ckt wird (Yes/No)
.PARAMETER Timeout
    Timeout in Sekunden (0 = kein Timeout)
.PARAMETER Force
    ?berspringt Abfrage und gibt Default zur?ck
.EXAMPLE
    . .\confirm.ps1
    if (Get-UserConfirmation "M?chten Sie fortfahren?") { ... }
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Message = "M?chten Sie fortfahren?",
    
    [ValidateSet('Yes', 'No', 'None')]
    [string]$Default = 'None',
    
    [int]$Timeout = 0,
    
    [switch]$Force
)

function Get-UserConfirmation {
    <#
    .SYNOPSIS
        Fragt Benutzer nach Best?tigung
    .DESCRIPTION
        Zeigt eine Ja/Nein-Abfrage mit optionalem Default und Timeout.
        Gibt $true f?r Ja, $false f?r Nein zur?ck.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [ValidateSet('Yes', 'No', 'None')]
        [string]$Default = 'None',
        
        [int]$Timeout = 0,
        
        [switch]$Force
    )
    
    # Force-Modus
    if ($Force) {
        switch ($Default) {
            'Yes' { return $true }
            'No' { return $false }
            default { return $true } # Default wenn kein Default angegeben
        }
    }
    
    # Erstelle Prompt
    $prompt = $Message
    switch ($Default) {
        'Yes' { $prompt += " [J/n]" }
        'No' { $prompt += " [j/N]" }
        default { $prompt += " [j/n]" }
    }
    
    # Mit Timeout
    if ($Timeout -gt 0) {
        $prompt += " (Timeout: ${Timeout}s)"
        Write-Host $prompt -ForegroundColor Yellow -NoNewline
        
        $startTime = Get-Date
        $keypressed = $false
        $response = ""
        
        # Warte auf Eingabe oder Timeout
        while (((Get-Date) - $startTime).TotalSeconds -lt $Timeout) {
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                if ($key.Key -eq 'Enter') {
                    $keypressed = $true
                    break
                } elseif ($key.KeyChar) {
                    $response = $key.KeyChar
                    Write-Host $key.KeyChar -NoNewline
                }
            }
            Start-Sleep -Milliseconds 100
        }
        
        Write-Host "" # Neue Zeile
        
        # Timeout erreicht
        if (-not $keypressed -and [string]::IsNullOrWhiteSpace($response)) {
            Write-Host "   ?  Timeout - verwende Default" -ForegroundColor DarkGray
            switch ($Default) {
                'Yes' { return $true }
                'No' { return $false }
                default {
                    Write-Host "   ? Kein Default definiert - Abbruch" -ForegroundColor Red
                    return $false
                }
            }
        }
    } else {
        # Normale Abfrage ohne Timeout
        Write-Host $prompt -ForegroundColor Yellow -NoNewline
        $response = Read-Host
    }
    
    # Verarbeite Antwort
    if ([string]::IsNullOrWhiteSpace($response)) {
        # Enter gedr?ckt - verwende Default
        switch ($Default) {
            'Yes' { return $true }
            'No' { return $false }
            default {
                # Kein Default - frage erneut
                Write-Host "   ??  Bitte antworten Sie mit J oder N" -ForegroundColor Yellow
                return Get-UserConfirmation -Message $Message -Default $Default
            }
        }
    }
    
    # Pr?fe Antwort
    switch -Regex ($response.ToLower()) {
        '^(j|ja?|yes?|y)$' { return $true }
        '^(n|nein|no?)$' { return $false }
        default {
            Write-Host "   ??  Ung?ltige Eingabe. Bitte J oder N eingeben." -ForegroundColor Yellow
            return Get-UserConfirmation -Message $Message -Default $Default
        }
    }
}

function Show-Confirmation {
    <#
    .SYNOPSIS
        Zeigt eine formatierte Best?tigungs-Box
    .DESCRIPTION
        Zeigt eine hervorgehobene Best?tigungsabfrage mit Rahmen.
    #>
    param(
        [string]$Title = "Best?tigung erforderlich",
        [string]$Message,
        [string]$Default = 'None',
        [ConsoleColor]$Color = 'Yellow'
    )
    
    $width = 60
    $border = "?" * $width
    
    Write-Host ""
    Write-Host "?$border?" -ForegroundColor $Color
    Write-Host "? $($Title.PadRight($width - 2)) ?" -ForegroundColor $Color
    Write-Host "?$border?" -ForegroundColor $Color
    
    # Wrappen des Textes
    $words = $Message -split ' '
    $line = "? "
    foreach ($word in $words) {
        if (($line + $word).Length -gt $width - 2) {
            Write-Host "$($line.PadRight($width + 1))?" -ForegroundColor $Color
            $line = "? $word "
        } else {
            $line += "$word "
        }
    }
    if ($line.Length -gt 2) {
        Write-Host "$($line.PadRight($width + 1))?" -ForegroundColor $Color
    }
    
    Write-Host "?$border?" -ForegroundColor $Color
    Write-Host ""
    
    return Get-UserConfirmation -Message "Fortfahren?" -Default $Default
}

function Test-UserConfirmation {
    <#
    .SYNOPSIS
        Testet die Best?tigungsfunktionen
    #>
    Write-Host "Test der Best?tigungsfunktionen" -ForegroundColor Cyan
    Write-Host "=" * 40 -ForegroundColor DarkGray
    
    # Test 1: Normale Abfrage
    Write-Host "`nTest 1: Normale Abfrage"
    $result = Get-UserConfirmation "Dies ist ein Test. Fortfahren?"
    Write-Host "Ergebnis: $result"
    
    # Test 2: Mit Default Yes
    Write-Host "`nTest 2: Mit Default Yes"
    $result = Get-UserConfirmation "Test mit Default Yes" -Default Yes
    Write-Host "Ergebnis: $result"
    
    # Test 3: Mit Timeout
    Write-Host "`nTest 3: Mit 5 Sekunden Timeout"
    $result = Get-UserConfirmation "Test mit Timeout" -Default Yes -Timeout 5
    Write-Host "Ergebnis: $result"
    
    # Test 4: Confirmation Box
    Write-Host "`nTest 4: Best?tigungs-Box"
    $result = Show-Confirmation -Title "Wichtige Aktion" -Message "Diese Aktion kann nicht r?ckg?ngig gemacht werden. Sind Sie sicher, dass Sie fortfahren m?chten?" -Default No
    Write-Host "Ergebnis: $result"
}

# Wenn direkt ausgef?hrt (nicht dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    # Wenn Parameter ?bergeben wurden, f?hre direkt aus
    if ($PSBoundParameters.Count -gt 0) {
        Get-UserConfirmation @PSBoundParameters
    } else {
        # Ansonsten zeige Test
        Test-UserConfirmation
    }
}

# Exportiere Funktionen f?r dot-sourcing
Export-ModuleMember -Function Get-UserConfirmation, Show-Confirmation