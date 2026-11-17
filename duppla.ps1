# Instalador base de Duppla para Windows. Se pega UNA línea en PowerShell normal (no "como administrador"):
#   irm https://raw.githubusercontent.com/duppla/dipplodocus-instalador/<commit>/duppla.ps1 | iex
# La cuenta @duppla.co no va en la línea: sale del login de Google (gcloud), como en dipplo-sesion.sh de la Mac mini.
# Para solo revisar el PC, sin instalar nada:
#   $env:DUPPLA_DOCTOR=1; irm https://raw.githubusercontent.com/duppla/dipplodocus-instalador/<commit>/duppla.ps1 | iex
# Aquí no hay llaves ni datos. Nunca hace exit: cerraría la ventana y la persona no vería el error. Por eso el número de
# pendientes del doctor queda en $LASTEXITCODE. No clona repos: cada quien clona los suyos desde Claude Code.
& {
  [Console]::OutputEncoding = [Text.Encoding]::UTF8
  function Para($m) { Write-Host "`n  x $m" -ForegroundColor Red; Write-Host '  Mándale un pantallazo de esto a Jhonattan.'; throw 'duppla' }
  function Ok($m) { Write-Host '  √ ' -ForegroundColor Green -NoNewline; Write-Host $m }
  function Nota($m) { Write-Host "  · $m" -ForegroundColor DarkGray }
  function Aviso($m) { Write-Host "  ! $m" -ForegroundColor Yellow }
  function Paso($m) { Write-Host "`n$m" -ForegroundColor Magenta }
  function Refrescar { $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') }
  function Otra([scriptblock]$b) { foreach ($s in 0, 5, 15) { Start-Sleep $s; $r = & $b; if ($LASTEXITCODE -eq 0) { return $r } } }  # GitHub a veces se corta
  # El código de salida se pone en 1 antes de probar: sin el programa, no vale el código de lo que corrió antes.
  function Arranca([scriptblock]$b) { $global:LASTEXITCODE = 1; try { & $b | Out-Null; $LASTEXITCODE -eq 0 } catch { $false } }
  # Por archivo, no con -c: PowerShell 5.1 daña las comillas que le pasa a un programa. Se busca el bash de Git porque
  # el "bash" del PATH de Windows suele ser el lanzador de WSL.
  function EnBash($s) {
    $b = "$env:ProgramFiles\Git\bin\bash.exe"
    if (-not (Test-Path $b)) { $b = Join-Path (Split-Path (Split-Path (Get-Command git).Source)) 'bin\bash.exe' }
    $t = [IO.Path]::GetTempFileName()
    [IO.File]::WriteAllText($t, $s)
    & $b $t
    $c = $LASTEXITCODE; Remove-Item $t -ErrorAction SilentlyContinue; $global:LASTEXITCODE = $c
  }

  # npm.cmd y no npm: npm.ps1 no corre con la política de scripts que Windows trae de fábrica.
  # El python de la Microsoft Store es un atajo que no corre nada: se prueba que arranque, no que exista.
  $NODE = { if ([int]((node -v) -replace '^v(\d+).*', '$1') -lt 25) { throw 'Node viejo' } }
  $NPM = { if ([int]((npm.cmd -v) -replace '^(\d+).*', '$1') -lt 11) { throw 'npm viejo' } }
  $PYTHON = { python -c 'import sys; sys.exit(sys.version_info < (3, 8))' 2>$null }
  $PAQUETES = [ordered]@{
    'git'        = { git --version }
    'gh'         = { gh --version }
    'nodejs-lts' = $NODE
    'uv'         = { uv --version }
    'python312'  = $PYTHON
    'jq'         = { jq --version }
    'tailscale'  = { tailscale version }
    'gcloudsdk'  = { gcloud.cmd --version }
  }
  # gcloud.cmd y no gcloud: el gcloud.ps1 del Cloud SDK nuevo tampoco corre con la política de scripts de fábrica.
  $GOOGLE = { "$(gcloud.cmd config get-value account 2>$null)".Trim().ToLower() }
  $CUENTA_GOOGLE = { if ((& $GOOGLE) -notmatch '^[a-z0-9._-]+@duppla\.co$') { throw 'Sin cuenta de Duppla' } }
  $NPM_DUPPLA = { npm.cmd view '@duppla/http-base' version --registry=https://npm.pkg.github.com 2>$null }
  $TAILNET = {
    $s = (tailscale status --json 2>$null | Out-String) | ConvertFrom-Json
    if ($s.BackendState -ne 'Running' -or $s.CurrentTailnet.Name -ne 'duppla.co') { throw 'Fuera del tailnet' }
  }
  $DUPPLA_CORE = { if ((claude plugin list --json 2>$null | Out-String) -notmatch 'duppla-core@duppla') { throw 'Sin duppla-core' } }
  function Faltan { $PAQUETES.Keys | Where-Object { -not (Arranca $PAQUETES[$_]) } }

  function Doctor {
    $chequeos = [ordered]@{
      'git'                               = $PAQUETES['git']
      'GitHub CLI'                        = $PAQUETES['gh']
      'Node 25 o más'                     = $NODE
      'npm 11 o más'                      = $NPM
      'uv'                                = $PAQUETES['uv']
      'jq'                                = $PAQUETES['jq']
      'python'                            = $PYTHON
      'gcloud'                            = $PAQUETES['gcloudsdk']
      'Cuenta de Google @duppla.co'       = $CUENTA_GOOGLE
      'python3 en PowerShell'             = { python3 -c 'pass' 2>$null }
      'python3 en Git Bash (hooks)'       = { EnBash 'python3 -c pass' 2>$null }
      'Sesión de GitHub con read:packages' = { if ((gh auth status -h github.com 2>&1 | Out-String) -notmatch 'read:packages') { throw 'Sin el permiso' } }
      'Git entra a GitHub con gh'         = { if ((git config --get-urlmatch credential.helper https://github.com) -notmatch 'gh(\.exe)?''? auth git-credential') { throw 'Otro helper' } }
      'Miembro activo de duppla'          = { if ((gh api user/memberships/orgs/duppla --jq .state 2>$null) -ne 'active') { throw 'No activo' } }
      'Acceso a duppla-plugins'           = { gh api repos/duppla/duppla-plugins 2>$null }
      'Paquetes @duppla/*'                = $NPM_DUPPLA
      'Correo de git @duppla.co'          = { if ((git config --global user.email) -notmatch '@duppla\.co$') { throw 'Otro correo' } }
      'Claude Code'                       = { claude --version }
      'Plugin duppla-core'                = $DUPPLA_CORE
      'Tailscale en el tailnet de duppla' = $TAILNET
    }
    $pendientes = 0
    Paso 'Revisión del PC'
    foreach ($nombre in $chequeos.Keys) {
      if (Arranca $chequeos[$nombre]) { Ok $nombre }
      else { Write-Host '  x ' -ForegroundColor Red -NoNewline; Write-Host $nombre; $pendientes++ }
    }
    $pendientes
  }

  try {
    Refrescar
    if ($env:DUPPLA_DOCTOR) {
      Remove-Item Env:DUPPLA_DOCTOR  # si no, pegar después la línea de instalar en esta ventana solo revisaría
      $global:LASTEXITCODE = Doctor
      return
    }

    Write-Host "`nInstalando las herramientas de Duppla." -ForegroundColor Magenta

    Paso '1/7 Programas'
    $faltan = @(Faltan)
    if ($faltan) {
      if (-not ((whoami /groups) -match 'S-1-5-32-544')) { Para 'Tu usuario no es administrador de este PC. Pídeselo a tech.' }
      Nota "Falta instalar: $($faltan -join ', '). Sale UN aviso de permisos: dale Sí y espera a que se cierre la otra ventana."
      # Solo esto corre elevado: gh, git, npm y Claude Code tienen que quedar en el perfil de quien pegó la línea.
      $bloque = @'
$ErrorActionPreference = 'Stop'
$choco = "$env:ProgramData\chocolatey\bin\choco.exe"  # puede estar instalado y fuera del PATH de esta ventana
if (-not (Test-Path $choco)) {
  Set-ExecutionPolicy Bypass -Scope Process -Force
  [Net.ServicePointManager]::SecurityProtocol = 3072
  iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}
& $choco upgrade -y --no-progress PAQUETES
exit $LASTEXITCODE
'@ -replace 'PAQUETES', ($faltan -join ' ')
      $f = Join-Path $env:TEMP 'duppla-choco.ps1'
      Set-Content $f $bloque -Encoding UTF8
      try {
        $p = Start-Process powershell -Verb RunAs -Wait -PassThru -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$f`""
      } catch { Para 'Cancelaste el permiso de administrador. Vuelve a pegar la línea y dale Sí.' }
      Remove-Item $f -ErrorAction SilentlyContinue
      # 1641 y 3010 son los códigos de "quedó, falta reiniciar".
      if ($p.ExitCode -notin 0, 1641, 3010) { Para "Chocolatey falló (código $($p.ExitCode)). El detalle está en C:\ProgramData\chocolatey\logs\chocolatey.log" }
      Refrescar
      $faltan = @(Faltan)
      if ($faltan) { Para "No quedó funcionando: $($faltan -join ', '). Reinicia el PC y vuelve a pegar la línea." }
      Nota 'Si se abrió una ventana de Tailscale, ciérrala con la X y sigue en esta: el login se hace aquí.'
    }
    # Al inicio del PATH del usuario, porque ahí también está el atajo python3 de la Store y tiene que quedar detrás.
    $BIN = Join-Path $HOME '.local\bin'
    New-Item -ItemType Directory -Force $BIN | Out-Null
    $up = [Environment]::GetEnvironmentVariable('Path', 'User')
    # Si ya estaba (el instalador de Claude Code la agrega al final), se mueve adelante: detrás de WindowsApps no sirve.
    $resto = @("$up" -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ne $BIN })
    $nuevo = (@($BIN) + $resto) -join ';'
    if ($nuevo -ne $up) { [Environment]::SetEnvironmentVariable('Path', $nuevo, 'User') }
    Refrescar
    # Los hooks de duppla-plugins llaman python3 y el instalador de python.org no lo trae. Sin este par de archivos (el
    # mismo truco de npm: uno sin extensión para Git Bash y un .cmd para Windows) los guards no corren y nadie se entera.
    if (-not (Arranca { python3 -c 'pass' 2>$null })) {
      [IO.File]::WriteAllText("$BIN\python3", "#!/bin/sh`nexec python `"`$@`"`n")
      [IO.File]::WriteAllText("$BIN\python3.cmd", "@python %*`r`n")
    }
    Ok 'Programas listos'

    Paso '2/7 Cuenta de Google'
    if (-not (Arranca $CUENTA_GOOGLE)) {
      Write-Host '  Se abre el navegador: entra con tu cuenta de Google de Duppla (@duppla.co).' -ForegroundColor Magenta
      gcloud.cmd auth login --brief --quiet
      if ($LASTEXITCODE -ne 0) { Para 'No se pudo entrar con Google.' }
    }
    $CUENTA = & $GOOGLE
    if ($CUENTA -notmatch '^[a-z0-9._-]+@duppla\.co$') { Para "Entraste con `"$CUENTA`", que no es de Duppla. Vuelve a pegar la línea y entra con tu correo @duppla.co." }
    Ok "Eres $CUENTA"

    Paso '3/7 GitHub'
    gh auth status -h github.com 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
      Write-Host '  Entra a GitHub con tu cuenta de Duppla: copia el código de 8 letras, dale Enter y pégalo en el navegador que se abre.' -ForegroundColor Magenta
      gh auth login -h github.com -p https -w -s read:packages
      if ($LASTEXITCODE -ne 0) { Para 'No se pudo entrar a GitHub.' }
    } elseif ((gh auth status -h github.com 2>&1 | Out-String) -notmatch 'read:packages') {
      Write-Host '  GitHub necesita un permiso más: copia el código de 8 letras, dale Enter y pégalo en el navegador que se abre.' -ForegroundColor Magenta
      gh auth refresh -h github.com -s read:packages
      if ($LASTEXITCODE -ne 0) { Para 'No se pudo dar el permiso read:packages en GitHub.' }
    }
    $YO = gh api user --jq .login 2>$null
    if ((gh api user/memberships/orgs/duppla --jq .state 2>$null) -eq 'pending') {
      gh api -X PATCH user/memberships/orgs/duppla -f state=active 2>$null | Out-Null
      if ($LASTEXITCODE -ne 0) { Para 'Tienes una invitación de Duppla en GitHub sin aceptar y no pude aceptarla sola: ábrela en https://github.com/orgs/duppla/invitation, dale Join y vuelve a pegar la línea.' }
    }
    Otra { gh api repos/duppla/duppla-plugins 2>$null | Out-Null } | Out-Null
    if ($LASTEXITCODE -ne 0) { Para "Tu GitHub ($YO) todavía no tiene acceso a Duppla. Si ese no es tu usuario de Duppla, escribe: gh auth login" }
    gh auth setup-git -h github.com 2>$null | Out-Null
    Ok "Entraste como $YO"

    Paso '4/7 Identidad de git'
    git config --global user.name "$(gh api user --jq '.name // .login' 2>$null)"
    git config --global user.email $CUENTA
    git config --global core.autocrlf input  # con CRLF, los hooks en bash de los repos no corren
    Ok "Tus commits quedan a nombre de $CUENTA"

    Paso '5/7 Paquetes @duppla/*'
    # El scope global sirve en repos que no traen su .npmrc; los que lo traen dicen lo mismo.
    npm.cmd config set '@duppla:registry' https://npm.pkg.github.com | Out-Null
    if (-not (Arranca $NPM_DUPPLA)) {
      # Se reescribe solo si falla: así, volver a pegar la línea arregla un token rotado.
      npm.cmd config set "//npm.pkg.github.com/:_authToken=$(gh auth token)" | Out-Null
    }
    if (Arranca $NPM_DUPPLA) { Ok 'npm ya puede bajar @duppla/*' } else { Aviso 'npm todavía no puede bajar @duppla/*.' }

    Paso '6/7 Tailscale'
    if (-not (Arranca $TAILNET)) {
      Write-Host "  Abre el enlace que sale aquí abajo y entra con $CUENTA." -ForegroundColor Magenta
      tailscale up
    }
    if (Arranca $TAILNET) { Ok 'Conectado al tailnet de Duppla' } else { Aviso 'No quedaste conectado al tailnet de Duppla: sin eso no se llega a Northflank.' }
    tailscale set --auto-update 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Aviso 'Tailscale no quedó con actualización automática.' }

    Paso '7/7 Claude Code'
    if (-not (Arranca { claude --version })) {
      # En otro PowerShell: si su instalador falla hace exit, y aquí cerraría la ventana.
      powershell -NoProfile -Command "& ([scriptblock]::Create((irm https://claude.ai/install.ps1))) stable" | Out-Null
      Refrescar
      if (-not (Arranca { claude --version })) { Para 'No se pudo instalar Claude Code.' }
    }
    claude plugin marketplace add duppla/duppla-plugins 2>$null | Out-Null  # si ya estaba, no hace nada
    Otra { claude plugin marketplace update duppla 2>$null | Out-Null } | Out-Null
    # Sin duppla-core no existe /duppla-core:setup, que es lo que se le dice a la persona al final.
    if (-not (Arranca $DUPPLA_CORE)) { Otra { claude plugin install duppla-core@duppla 2>$null | Out-Null } | Out-Null }
    if (Arranca $DUPPLA_CORE) { Ok 'Claude Code con duppla-core' } else { Aviso 'No pude instalar duppla-core desde el marketplace de Duppla.' }

    $pendientes = Doctor
    if ($pendientes -gt 0) {
      Write-Host "`nQuedaron $pendientes pendientes." -ForegroundColor Yellow -NoNewline; Write-Host ' Vuelve a pegar la línea; si siguen, mándale un pantallazo de esto a Jhonattan.'
    } else {
      Write-Host "`n√ Listo." -ForegroundColor Green -NoNewline; Write-Host ' Ahora:'
      Write-Host '  1. Cierra PowerShell y abre uno nuevo desde Inicio.'
      Write-Host '  2. Entra a la carpeta donde quieras trabajar, escribe ' -NoNewline; Write-Host 'claude' -ForegroundColor White -NoNewline; Write-Host ' y entra con tu cuenta de Claude.'
      Write-Host '  3. Escribe ' -NoNewline; Write-Host '/duppla-core:setup' -ForegroundColor White -NoNewline; Write-Host ' y después dile: ' -NoNewline; Write-Host 'clona el repo <nombre>' -ForegroundColor White
    }
    $global:LASTEXITCODE = $pendientes
  } catch {
    if ("$_" -ne 'duppla') { Write-Host "`n$_" -ForegroundColor Red; Write-Host 'Mándale un pantallazo de esto a Jhonattan.' }
    $global:LASTEXITCODE = 1
  }
}
