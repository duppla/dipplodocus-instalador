# dipplodocus-instalador

Instaladores de las herramientas internas de Duppla, en una línea. Este repo es público a propósito y no tiene llaves ni datos: solo trae lo básico (Homebrew, gh), entra a GitHub y sigue con el instalador privado de cada herramienta, que exige acceso a la organización.

Dipplo:

```
bash <(curl -fsSL https://raw.githubusercontent.com/duppla/dipplodocus-instalador/<commit>/dipplo) <cuenta>@duppla.co
```

La línea apunta a un commit fijo, no a `main`: solo corre lo que ya se probó. Un cambio nuevo se publica actualizando el commit en el mensaje de Dipplodocus (`dipplodocus/scripts/instalar_dipplo_por_dm.py`).
