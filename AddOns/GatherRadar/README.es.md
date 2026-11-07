<h1 align="center">GatherRadar</h1>

<p align="center">
  <b>Rastreador de hierbas y menas para World of Warcraft: hierbas, minería, tesoros y bancos de peces en el minimapa y el mapa del mundo</b>
</p>

<p align="center">
<a href="https://github.com/Pirson-s-Addons/GatherRadar/releases/latest">
<img src="https://img.shields.io/github/v/release/Pirson-s-Addons/GatherRadar?style=for-the-badge&color=A78BFA">
</a>
<img src="https://img.shields.io/badge/WoW_Forever-1.60.1-C4B5FD?style=for-the-badge">
<a href="LICENSE">
<img src="https://img.shields.io/badge/License-MIT-E9D5FF?style=for-the-badge">
</a>
</p>

<p align="center">
<a href="README.md">🇬🇧 English</a>
</p>

---

## Qué hace

**GatherRadar** convierte Buscar hierbas, Buscar minerales, Buscar tesoros y Buscar peces en un radar de recolección de verdad. Cada nodo del minimapa lleva el **icono de lo que da** (Flor de paz, Mineral de cobre, un cofre...) con un aro que te dice tu probabilidad de subir habilidad. El minimapa solo muestra lo **detectado ahora** de las profesiones que tienes, y cada nodo que recoges o ves se **recuerda** en el **mapa del mundo**, para que planees tu ruta de un vistazo.

## Funciones

- **Iconos en el minimapa**: el icono real del objeto en cada hierba, filón, cofre y banco de peces, redondo y con un aro del color de la ventana de profesión (naranja, amarillo, verde, gris; rojo si aún no tienes habilidad).
- **Recuerda cada nodo**: los que recoges (posición exacta) y, si quieres, los que el escáner ve en el minimapa, para encontrarlos luego en el mapa del mundo.
- **Pines en el mapa del mundo** con todos los nodos guardados de la zona. Mayús + clic derecho en un pin lo borra.
- **Sin duplicados**: dos nodos del mismo tipo a menos de 15 yardas (tú eliges) son el mismo sitio y se queda solo uno.
- **Nodos conocidos incluidos**: con un clic importas las hierbas, menas y tesoros de WoW Forever (datos de Wowhead de GatherMate2_Data) y los bancos de peces que te faltan, de los tipos que elijas, sin necesitar otro addon. Los tuyos nunca se sustituyen.
- **Filtro de mapas**: un botón redondo en el mapa del mundo elige qué tipos (hierbas, menas, tesoros, bancos de peces) salen en el minimapa y en el mapa del mundo. La flecha también lo sigue.
- **Flecha al nodo más cercano** con su nombre y distancia, dando prioridad a lo que hay ahora en el minimapa.
- **Compartir con el grupo**: tus compañeros con GatherRadar ven los nodos que encuentras, y tú los suyos, en vivo.
- **Panel de sesión**: nodos recogidos y materiales conseguidos, con iconos, total y por hora.
- **Funciona en tu idioma**: hierbas, menas, tesoros y bancos de peces se reconocen por su nombre del juego en todos los idiomas oficiales; los nodos nuevos de Forever se aprenden al recoger.
- Opciones en el propio panel del juego **Opciones → AddOns**, 20 idiomas, sin librerías.

## Instalación

1. Descarga el zip de [CurseForge](https://www.curseforge.com/wow/addons/gather-radar) o de la [última versión](https://github.com/Pirson-s-Addons/GatherRadar/releases/latest).
2. Extrae la carpeta `GatherRadar` en `World of Warcraft/_classic_beta_/Interface/AddOns/`.
3. Reinicia WoW y activa el addon.

## Uso

- Activa **Buscar hierbas**, **Buscar minerales**, **Buscar tesoros** o **Buscar peces** en el menú de rastreo del minimapa. GatherRadar hace el resto.
- `/gr` abre las opciones. `/gr session` muestra el panel de sesión, `/gr arrow` la flecha, `/gr import` importa los nodos de Wowhead.
- **Opciones → AddOns → GatherRadar → General**: qué se ve y dónde, el radar y el tamaño de los iconos.
- **Opciones → AddOns → GatherRadar → Datos**: nodos guardados, duplicados, importar (eligiendo los tipos), borrar y olvidar todo.

## Notas

- Un addon no puede preguntar al juego dónde están los nodos: GatherRadar lee el minimapa con un ratón virtual, los mismos puntos que ves tú. Sin un rastreo activado GatherRadar no muestra nada en el minimapa; los nodos guardados siguen en el mapa del mundo.
- Los bancos de peces se guardan solo desde el minimapa (el botín de pesca sale del corcho, no del banco).
- Los nodos nuevos de WoW Forever (Cold Iron Deposit, Dreamroot...) se reconocen en inglés; en otros idiomas su nombre se aprende la primera vez que los recoges. Las hierbas con una palabra de más (Flor de paz marchita) cuentan como la hierba.

---

**Autor**: Pirson · [GitHub](https://github.com/Pirson-s-Addons) · [CurseForge](https://www.curseforge.com/members/pirson/projects) · Licencia MIT
