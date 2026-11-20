# Obtener dispositivos conectados mediante ADB.
$dispositivos = adb devices | Select-Object -Skip 1 |
    Where-Object { $_ -match "^\S+\s+device$" }

if (-not $dispositivos) {
    Write-Host "No se encontro ningun dispositivo conectado."
    Write-Host "Conecta el celular por USB o activa la depuracion inalambrica."
    exit 1
}

# Mostrar dispositivos disponibles.
Write-Host "Dispositivos detectados:"
Write-Host ""

$lista = @()

foreach ($dispositivo in $dispositivos) {
    $partes = $dispositivo -split "\s+"
    $id = $partes[0]

    $tipo = if ($id -match ":") {
        "Inalambrico"
    } else {
        "USB"
    }

    $lista += [PSCustomObject]@{
        ID = $id
        Conexion = $tipo
    }
}

for ($i = 0; $i -lt $lista.Count; $i++) {
    Write-Host "[$($i + 1)] $($lista[$i].ID) ($($lista[$i].Conexion))"
}

Write-Host ""

# Seleccionar dispositivo.
if ($lista.Count -eq 1) {
    $seleccion = 0
    Write-Host "Se utilizara el unico dispositivo disponible."
} else {
    $opcion = Read-Host "Selecciona el numero del dispositivo"

    if ($opcion -notmatch '^\d+$' -or
        [int]$opcion -lt 1 -or
        [int]$opcion -gt $lista.Count) {
        Write-Host "Seleccion no valida."
        exit 1
    }

    $seleccion = [int]$opcion - 1
}

$dispositivoID = $lista[$seleccion].ID

Write-Host ""
Write-Host "Dispositivo seleccionado: $dispositivoID"
Write-Host "Tipo de conexion: $($lista[$seleccion].Conexion)"

# Configurar ADB Reverse para enlazar el puerto 8000 del celular con la PC.
Write-Host ""
Write-Host "Configurando ADB Reverse para FastAPI..."

adb -s $dispositivoID reverse tcp:8000 tcp:8000

if ($LASTEXITCODE -ne 0) {
    Write-Host "No se pudo configurar ADB Reverse."
    exit 1
}

$url = "http://127.0.0.1:8000"

Write-Host "Conexion configurada correctamente."
Write-Host "API: $url"

# Entrar a la carpeta de la practica 10 y ejecutar Flutter.
Write-Host ""
Write-Host "Iniciando aplicacion de Flutter..."
Write-Host ""

Set-Location $PSScriptRoot

flutter run -d $dispositivoID
