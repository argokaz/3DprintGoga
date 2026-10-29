# Visera frontal ultraligera — Nintendo Switch 2

Tapa frontal que protege la pantalla y evita que los joysticks se aplasten en la mochila.
Una "capucha" cubre cada Joy-Con 2 completo, así la posición exacta del stick no importa.
Toda la presión se apoya en el borde exterior y en el marco de la tablet, nunca en sticks ni pantalla.

![vista](img/full.png)

## Archivos

| STL | Uso | Peso PETG |
|---|---|---|
| `stl/test_clip.stl` | Probar holgura y clips (imprímelo primero) | ~6 g |
| `stl/test_hood.stl` | Probar altura de capucha sobre el stick | ~14 g |
| `stl/full.stl` | Visera entera (cama ≥ 280 mm) | ~52 g |
| `stl/left.stl` + `stl/right.stl` | Visera en dos mitades (cama ≥ 140 × 120 mm); unir con pegamento + 3 × M2×8 | ~30 g c/u |

Regenerar: `openscad -o stl/full.stl -D 'part="full"' switch2_visera.scad`
(`part` = `full | left | right | test_clip | test_hood`, `screen_style` = `solid | honeycomb | open`).

## Impresión

- Boca abajo (cara exterior plana sobre la cama), **sin soportes**.
- PETG recomendado (los clips flexionan sin romperse); PLA vale pero es más frágil.
- 0,2 mm de capa, 3 perímetros (las paredes son de 1,2 mm → salen macizas).

## Medidas usadas

| Medida | Valor | Fuente | Confianza |
|---|---|---|---|
| Consola con Joy-Con 2 | 272 × 116 × 13,9 | Nintendo oficial | Alta |
| Grosor máx. punta stick → ZL/ZR | 30,7 | Nintendo oficial | Alta |
| Tablet sin Joy-Con (ancho) | 200–201 | couple-game.net, escaneo dbrand | Media-alta |
| Ancho visible Joy-Con 2 | ~35,5 | (272 − 201) / 2 | Media |
| Diámetro capuchón stick | 17,2–17,5 | Bitbuilt, GamesRadar | Media-alta |
| Altura del stick sobre la cara | 6,3–7,2 (se usa 7,2) | dbrand; 30,7 − 14,4 − 9,1 | Media |
| ZL/ZR sobresalen por detrás | 9,1 | dbrand | Media |
| Pantalla activa | ~174,9 × 98,4 | 7,9″ 16:9 | Alta |
| Marco lateral pantalla–borde tablet | ~13 (lados), ~8,8 (arriba/abajo) | Estimado | Baja-media |
| Centros de los sticks | izq. ~35 mm desde arriba, der. ~70 mm; ~17–18 mm del borde exterior | Estimación, **no publicado** | Baja |
| Botones | ABXY y cruceta sobresalen ~1,6 mm (por debajo del stick) | dbrand | Media |
| Borde superior (izq → der) | Power, volumen, ventilación, USB-C (a la dcha. del centro), jack 3,5, ranura de juego | Diagrama Nintendo | Orden sí, posiciones no |
| Borde inferior | Altavoz, USB-C central, altavoz | Diagrama Nintendo / iFixit | Media-alta |
| Radio de esquinas | no publicado (se usa 11) | — | Medir |

Como las capuchas cubren todo el Joy-Con, la posición de sticks y botones no afecta al encaje.
Lo que sí conviene medir con calibre: `corner_r` y que los clips (`top_clips`, `bottom_clips`, en mm desde el centro)
no tapen la ranura de juego, el jack ni los altavoces de tu consola.

Fuentes: [Nintendo specs](https://www.nintendo.com/en-gb/Hardware/Nintendo-Switch-2/Nintendo-Switch-2-Specifications-2785627.html),
[Joy-Con 2](https://www.nintendo.com/my/hardware/switch2/accessories/joyCon.html),
[diagrama de la consola](https://en-americas-support.nintendo.com/app/answers/detail/a_id/68498),
[couple-game.net](https://couple-game.net/switch2-size/),
[dbrand vía Nintendo Life](https://www.nintendolife.com/news/2024/12/after-sharing-switch-2-images-dbrand-is-back-with-actual-measurements),
[Bitbuilt (stick)](https://bitbuilt.net/forums/threads/nintendo-switch-2-hall-effect-analog-stick-pinout-3d-model.7271/),
[GamesRadar](https://gamesradar.com/hardware/gaming-controllers/nintendo-switch-2-joy-cons-compared-how-do-the-new-controllers-stack-up-against-the-ones-we-know),
[modelo de referencia escaneado (MakerWorld)](https://makerworld.com/en/models/1490513-nintendo-switch-2-reference-model).
