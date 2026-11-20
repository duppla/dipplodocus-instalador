# Primer pedacito, público, del instalador de Dipplo para Windows. Se pega UNA línea en PowerShell:
#   irm https://raw.githubusercontent.com/duppla/dipplodocus-instalador/<commit>/dipplo.ps1 | iex
# (sin correo: la cuenta sale de Google; si llega DIPPLO_CUENTA de una línea vieja, se ignora.) Trae Git y gh con winget si faltan, entra a GitHub,
# acepta la invitación a duppla si está pendiente y sigue con el instalador de verdad, que es privado (duppla-plugins).
# Aquí no hay llaves ni datos. Nunca hace exit: cerraría la ventana y la persona no vería el error.
& {
  $VERSION = '496b78ab87a25d1e9bc975f69ac3c20b8d1bada1'  # commit del instalador privado en duppla-plugins: solo corre lo probado
  [Console]::OutputEncoding = [Text.Encoding]::UTF8  # lo que devuelve gh (el instalador, con tildes) llega bien
  function Para($m) { Write-Host "`n  x $m" -ForegroundColor Red; Write-Host '  Mándale un pantallazo de esto a quien te mandó la línea.'; throw 'dipplo' }
  function Refrescar { $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') }
  function Otra([scriptblock]$b) { foreach ($s in 0, 5, 15) { Start-Sleep $s; $r = & $b; if ($LASTEXITCODE -eq 0) { return $r } } }  # GitHub a veces se corta
  # $dirs: dónde deja el programa su comando si winget no lo puso en el PATH de esta ventana
  function Instalar($cmd, $id, $dirs = @()) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { return }
    Write-Host "  · Instalando $id (si Windows pregunta si permites cambios, dale Sí)" -ForegroundColor DarkGray
    $s = @(winget install --id $id -e --source winget --silent --accept-package-agreements --accept-source-agreements 2>&1 | ForEach-Object { "$_" })
    $c = $LASTEXITCODE
    Refrescar  # si ya estaba instalado winget sale con código ≠ 0: lo que cuenta es que el comando aparezca
    foreach ($d in $dirs) { if (-not (Get-Command $cmd -ErrorAction SilentlyContinue) -and (Test-Path $d)) { $env:Path += ";$d" } }
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
      $log = Join-Path $env:USERPROFILE '.dipplo-instalar.log'
      Set-Content $log "winget install $id (código $c)`n$($s -join "`n")"
      Write-Host ($s | Select-Object -Last 6 | Out-String) -ForegroundColor DarkGray
      Para "No se pudo instalar $id (winget salió con código $c; detalle en $log). Cierra PowerShell, ábrelo de nuevo y vuelve a pegar la línea."
    }
  }
  try {
    $global:DIPPLO_INICIO = Get-Date
    Write-Host "`nInstalando Dipplo" -ForegroundColor Green -NoNewline; Write-Host '. La primera vez tarda unos 15 minutos.'
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Para 'Falta winget: instala «App Installer» desde la Microsoft Store y vuelve a pegar la línea.' }
    Instalar git Git.Git "$env:ProgramFiles\Git\cmd", "$env:LOCALAPPDATA\Programs\Git\cmd"
    Instalar gh GitHub.cli "$env:ProgramFiles\GitHub CLI", "$env:LOCALAPPDATA\Programs\GitHub CLI"
    gh auth status -h github.com 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
      Write-Host 'Entra a GitHub con tu cuenta de Duppla: copia el código de 8 letras y pégalo en el navegador.' -ForegroundColor Magenta
      gh auth login -h github.com -p https -w
      if ($LASTEXITCODE -ne 0) { Para 'No se pudo entrar a GitHub.' }
    }
    $YO = gh api user --jq .login 2>$null
    if ((gh api user/memberships/orgs/duppla --jq .state 2>$null) -eq 'pending') {
      gh api -X PATCH user/memberships/orgs/duppla -f state=active 2>$null | Out-Null
      if ($LASTEXITCODE -eq 0) { Write-Host 'Aceptada tu invitación a Duppla en GitHub.' }
      else { Para 'Tienes una invitación de Duppla en GitHub sin aceptar y no pude aceptarla sola: ábrela en https://github.com/orgs/duppla/invitation, dale Join y vuelve a pegar la línea.' }
    }
    Otra { gh api repos/duppla/duppla-plugins 2>$null | Out-Null } | Out-Null
    if ($LASTEXITCODE -ne 0) { Para "Tu GitHub ($YO) todavía no tiene acceso a Duppla. Si ese no es tu usuario de Duppla, escribe: gh auth login" }
    $inst = Otra { gh api -H 'Accept: application/vnd.github.raw' "repos/duppla/duppla-plugins/contents/plugins/duppla-dipplo/instalador/instalar.ps1?ref=$VERSION" 2>$null }
    if ($LASTEXITCODE -ne 0 -or -not $inst) { Para 'No se pudo bajar el instalador de Dipplo. Revisa el internet o la VPN y vuelve a pegar la línea.' }
    $env:DIPPLO_VERSION = $VERSION  # mismo commit para el plugin y las herramientas
    & ([scriptblock]::Create(($inst -join "`n")))
  } catch {
    if ("$_" -ne 'dipplo') { Write-Host "`n$_" -ForegroundColor Red; Write-Host 'Mándale un pantallazo de esto a Felipe.' }
  }
}
