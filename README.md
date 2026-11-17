# dipplodocus-instalador

Instaladores de las herramientas internas de Duppla, en una línea. Este repo es público a propósito y no tiene llaves ni datos: solo trae lo básico (Homebrew y gh en Mac; Git y gh con winget en Windows), entra a GitHub y sigue con el instalador privado de cada herramienta, que exige acceso a la organización.

Dipplo en Mac (en la Terminal):

```
bash <(curl -fsSL https://raw.githubusercontent.com/duppla/dipplodocus-instalador/<commit>/dipplo) <cuenta>@duppla.co
```

Dipplo en Windows (en PowerShell; `irm | iex` no recibe argumentos, por eso la cuenta va antes):

```
$env:DIPPLO_CUENTA='<cuenta>@duppla.co'; irm https://raw.githubusercontent.com/duppla/dipplodocus-instalador/<commit>/dipplo.ps1 | iex
```

## Herramientas base de Duppla (onboarding de ingenieros)

`duppla` (Mac, con Homebrew) y `duppla.ps1` (Windows, con Chocolatey) dejan el computador listo: git, gh, Node, uv, Python, jq, gcloud, Tailscale y Claude Code con el plugin `duppla-core`. También entran a Google, GitHub y Tailscale, configuran git y npm para los paquetes `@duppla/*` y al final revisan que todo funcione. Se pueden correr varias veces: solo hacen lo que falta.

Antes de correrlo, la persona necesita:

- Su correo `@duppla.co`. El script lo saca del login de Google; no va en la línea.
- Una cuenta de GitHub ya invitada a la organización `duppla`. Si la invitación está pendiente, el script la acepta.
- Ser administrador de su computador.

Mac (en la Terminal):

```
bash <(curl -fsSL https://raw.githubusercontent.com/duppla/dipplodocus-instalador/<commit>/duppla)
```

Windows (en PowerShell normal, no como administrador):

```
irm https://raw.githubusercontent.com/duppla/dipplodocus-instalador/<commit>/duppla.ps1 | iex
```

Para solo revisar el computador sin instalar nada: en Mac se agrega `doctor` al final de la línea; en Windows se antepone `$env:DUPPLA_DOCTOR=1; `.

Las líneas apuntan a un commit fijo, no a `main`: solo corre lo que ya se probó. Un cambio nuevo se publica actualizando el commit en el mensaje de Dipplodocus (`dipplodocus/scripts/instalar_dipplo_por_dm.py`).
