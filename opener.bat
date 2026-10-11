<# :
@echo off
:: Configura el título de la consola de comandos de Windows
title Lanzador de Pestanas por Lote

:: Lanza una instancia limpia de PowerShell que lee e interpreta este mismo archivo codificado en UTF-8
powershell -NoProfile -ExecutionPolicy Bypass -Command "$code = [System.IO.File]::ReadAllText('%~f0', [System.Text.Encoding]::UTF8); Invoke-Expression $code"
exit /b
#>

# Limpia la pantalla de la consola de PowerShell
Clear-Host

# ---------------------------------------------------------
# 1. ENTRADA Y VALIDACIÓN DE LA URL
# ---------------------------------------------------------
$url = Read-Host "Introduce el enlace (ej. https://google.com)"
if ([string]::IsNullOrWhiteSpace($url)) {
    Write-Host "No se introdujo ninguna URL." -ForegroundColor Red
    Read-Host "Presione Intro para salir..."
    exit
}

# Agrega protocolo https:// por defecto si el usuario omitió http:// o https://
if (-not ($url.StartsWith("http://") -or $url.StartsWith("https://"))) {
    $url = "https://$url"
}

# ---------------------------------------------------------
# 2. ENTRADA Y VALIDACIÓN DE CANTIDAD DE PESTAÑAS
# ---------------------------------------------------------
$cantidadInput = Read-Host "¿Cuantas pestanas quieres abrir?"
$cantidad = 0
# Convierte la entrada a entero; si no es un número positivo, asigna 1 por defecto
if (-not [int]::TryParse($cantidadInput, [ref]$cantidad) -or $cantidad -le 0) {
    Write-Host "Cantidad no valida. Se abrira 1 pestana por defecto." -ForegroundColor Yellow
    $cantidad = 1
}

# ---------------------------------------------------------
# 3. SELECCIÓN DEL MODO DE APERTURA
# ---------------------------------------------------------
Write-Host ""
Write-Host "Modo de apertura:" -ForegroundColor Cyan
Write-Host "[1] Automatico (segun la ventana seleccionada)"
Write-Host "[2] Forzar modo Incognito / InPrivate"
Write-Host "[3] Forzar modo Normal"
$modoOpcion = Read-Host "Elige una opcion (1-3, por defecto 1)"

# ---------------------------------------------------------
# 4. DETECCIÓN DE VENTANAS ACTIVAS DE NAVEGADORES
# ---------------------------------------------------------
# Filtra procesos de los principales navegadores que tengan una ventana gráfica visible
$procesosNavegador = @(Get-Process | Where-Object { 
    ($_.ProcessName -in @("chrome", "msedge", "brave", "firefox", "opera")) -and ($_.MainWindowTitle -ne "") 
})

# ---------------------------------------------------------
# FUNCIÓN AUXILIAR: Obtener ruta del ejecutable en el disco
# ---------------------------------------------------------
function Obtener-RutaNavegador([string]$nombreNav) {
    $rutas = @(
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LocalAppData\Google\Chrome\Application\chrome.exe",
        "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
        "$env:ProgramFiles\Mozilla Firefox\firefox.exe"
    )

    # Retorna la primera ruta existente que coincida con el nombre del navegador
    foreach ($r in $rutas) {
        if ($r.ToLower().Contains($nombreNav.ToLower()) -and (Test-Path $r)) {
            return $r
        }
    }

    # Si no está en las rutas estándar, intenta resolverlo desde las variables de entorno PATH
    $cmd = Get-Command "$nombreNav.exe" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return "$nombreNav.exe"
}

# ---------------------------------------------------------
# 5. CASO A: NO HAY VENTANAS ABIERTAS
# ---------------------------------------------------------
if ($procesosNavegador.Count -eq 0) {
    Write-Host ""
    Write-Host "No se detectaron ventanas abiertas. Iniciando nueva sesion..." -ForegroundColor Yellow

    # Prioriza Microsoft Edge (nativo en Windows) o Google Chrome
    $navRuta = Obtener-RutaNavegador "msedge"
    $navNombre = "msedge"
    if (-not (Test-Path $navRuta)) {
        $navRuta = Obtener-RutaNavegador "chrome"
        $navNombre = "chrome"
    }

    # Prepara los parámetros de línea de comandos si se solicitó modo privado
    $esPrivado = ($modoOpcion -eq "2")
    $argsList = @()

    if ($esPrivado) {
        $flag = switch ($navNombre) {
            "msedge"  { "-inprivate" }
            "firefox" { "-private-window" }
            default   { "--incognito" }
        }
        $argsList += $flag
    }

    # Pasa todas las URLs como argumentos del proceso para abrirlas en una sola ventana
    1..$cantidad | ForEach-Object { $argsList += $url }
    Start-Process -FilePath $navRuta -ArgumentList $argsList

#  ---------------------------------------------------------
#  6. CASO B: SE ENCONTRARON VENTANAS ACTIVAS
#  ---------------------------------------------------------
} else {
    Write-Host ""
    Write-Host "Ventanas activas encontradas:" -ForegroundColor Cyan
    for ($idx = 0; $idx -lt $procesosNavegador.Count; $idx++) {
        $p = $procesosNavegador[$idx]
        Write-Host "[$($idx + 1)] $($p.ProcessName.ToUpper()): $($p.MainWindowTitle)"
    }

    $selInput = Read-Host "`n¿En cual ventana quieres abrir las pestanas? (1-$($procesosNavegador.Count))"
    $selIndex = 0

    # Valida que la selección corresponda a un índice numérico válido de la lista
    if ([int]::TryParse($selInput, [ref]$selIndex) -and $selIndex -ge 1 -and$selIndex -le $procesosNavegador.Count) {$procElegido = $procesosNavegador[$selIndex - 1]
        $exeNombre =$procElegido.ProcessName.ToLower()
        $titulo =$procElegido.MainWindowTitle.ToLower()

        # Determina si la ventana elegida está actualmente en modo privado/incógnito analizando su título
        $ventanaEsPrivada = $titulo.Contains("inprivate") -or $titulo.Contains("incógnito") -or $titulo.Contains("incognito") -or $titulo.Contains("private browsing")

        # Establece el modo efectivo según la opción seleccionada por el usuario
        $deseaPrivado =$false
        if ($modoOpcion -eq "2") {
            $deseaPrivado =$true
        } elseif ($modoOpcion -eq "3") {
            $deseaPrivado =$false
        } else {
            $deseaPrivado =$ventanaEsPrivada
        }

        # Subcaso B1: El modo coincide -> Se inyectan pestañas en la ventana activa actual
        if ($deseaPrivado -eq$ventanaEsPrivada) {
            Write-Host "`nAbriendo $cantidad pestana(s) en la ventana seleccionada..." -ForegroundColor Green

            $wshell = New-Object -ComObject Wscript.Shell
            $wshell.AppActivate($procElegido.Id) | Out-Null
            Start-Sleep -Milliseconds 500

            try {
                Set-Clipboard -Value $url
            } catch {
                Add-Type -AssemblyName System.Windows.Forms
                [System.Windows.Forms.Clipboard]::SetText($url)
            }

            # Si la ventana ya tenía una pestaña en blanco inicial, la reutiliza
            $esNuevaPestana = $titulo.Contains("nueva pestaña") -or $titulo.Contains("new tab")

            for ($i = 1; $i -le $cantidad; $i++) {
                if ($i -eq 1 -and $esNuevaPestana) {
                    $wshell.SendKeys("^l")               # Enfocar la barra de direcciones (Ctrl+L)
                    Start-Sleep -Milliseconds 150
                    $wshell.SendKeys("^v")               # Pegar la URL (Ctrl+V)
                    Start-Sleep -Milliseconds 100
                    $wshell.SendKeys("{ENTER}")          # Cargar la página
                } else {
                    $wshell.SendKeys("^t")               # Abrir nueva pestaña (Ctrl+T)
                    Start-Sleep -Milliseconds 200
                    $wshell.SendKeys("^v")               # Pegar la URL (Ctrl+V)
                    Start-Sleep -Milliseconds 100
                    $wshell.SendKeys("{ENTER}")          # Cargar la página
                }
                Start-Sleep -Milliseconds 200
            }

        # Subcaso B2: El modo difiere -> Se genera una ventana independiente con el modo solicitado
        } else {
            Write-Host "`nAbriendo nueva ventana en el modo solicitado..." -ForegroundColor Green
            $rutaExe = Obtener-RutaNavegador$exeNombre

            $argsList = @()
            if ($deseaPrivado) {
                $flag = switch ($exeNombre) {
                    "msedge"  { "-inprivate" }
                    "firefox" { "-private-window" }
                    default   { "--incognito" }
                }
                $argsList +=$flag
            }
            1..$cantidad | ForEach-Object { $argsList +=$url }
            Start-Process -FilePath $rutaExe -ArgumentList$argsList
        }
    } else {
        Write-Host "Seleccion no valida." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Proceso completado exitosamente." -ForegroundColor Green
Read-Host "Presione Intro para salir..."