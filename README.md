# dipplodocus-instalador

Instaladores de las herramientas internas de Duppla, en una línea. Este repo es público a propósito y no tiene llaves ni datos: solo trae lo básico (Homebrew y gh en Mac; Git y gh con winget en Windows), entra a GitHub y sigue con el instalador privado de cada herramienta, que exige acceso a la organización.

Dipplo en Mac (en la Terminal):

```
bash <(curl -fsSL https://raw.githubusercontent.com/duppla/dipplodocus-instalador/main/dipplo)
```

Se pega tal cual, sin escribir nada: la cuenta de Duppla sale del login de Google. Esta línea no cambia nunca: `main` solo trae la última versión probada (el `VERSION` de `dipplo` fija el instalador privado a un commit probado). Para publicar una versión nueva se cambia ese `VERSION`, no la línea.

Dipplo en Windows (en PowerShell):

```
irm https://raw.githubusercontent.com/duppla/dipplodocus-instalador/main/dipplo.ps1 | iex
```

Sin cuenta, como la de Mac: sale del login de Google, y `main` solo trae la versión probada (el `VERSION` de `dipplo.ps1`). Antes de publicar, la prueba automática de duppla-plugins la corre en un Windows real (PowerShell 5.1 y 7). Dipplodocus manda la línea por DM con `dipplodocus/scripts/instalar_dipplo_por_dm.py`.
