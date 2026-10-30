# Medidas de la Switch 2 según open-console-cad

Fuente: [tiansongyu/open-console-cad](https://github.com/tiansongyu/open-console-cad), `devices/switch2`
(licencia MIT, commit 3d5e782, 2026-10-29). Imágenes `occ_*.png` de ese repositorio.

**Fiabilidad:** el contorno general viene de las especificaciones oficiales de Nintendo
(272 × 116 × 13,9 mm). Las posiciones de botones, puertos y rejillas están **ajustadas a
partir de imágenes oficiales, no medidas en una consola real** (el propio autor lo indica:
`factory_match_verified: false`). Sirven como referencia; hay que confirmar en la consola.

Coordenadas en mm: x desde el centro (+ = derecha mirando la pantalla), y desde el centro
(+ = arriba), z = altura dentro del grosor medida desde la cara trasera (cara frontal ≈ 13,9).

## Borde superior (y = +58)

| Elemento | x centro | Tamaño (ancho × alto) | z |
|---|---|---|---|
| Encendido | −81 | 7,0 × 4,0 | 7,1 |
| Volumen | −66,4 | 15,8 × 3,8 | 7,1 |
| Sensor de brillo | −41,4 | Ø 3,3 | 7,1 |
| **Rejilla de salida 1** | **−12,2** | **15,0 × 4,7** | 7,1 |
| **Rejilla de salida 2** | **4,6** | **15,0 × 4,7** | 7,1 |
| **Rejilla de salida 3** | **21,4** | **15,0 × 4,7** | 7,1 |
| USB-C superior | 37,8 | 9,25 × 3,65 | 6,95 |
| Jack 3,5 mm | 50,2 | Ø 5,2 | 7,1 |
| Ranura de tarjeta (tapa) | 69,2 | 26 × 8,3 | 7,1 |
| Micrófono | 87,0 | 0,9 × 2,5 | 7,1 |

## Borde inferior (y = −58)

| Elemento | x centro | Tamaño | z |
|---|---|---|---|
| USB-C inferior | 0 | 9,25 × 3,65 | 6,95 |
| **Rejillas de entrada de aire** | **±40,8** | **41 × 5,2** | **4,9** |
| Agujeros de centrado del dock | ±16,3 | Ø 3,3 | 7,0 |

## Cara frontal

| Elemento | x | y |
|---|---|---|
| Stick izquierdo | −118 | +29 |
| Stick derecho | +118 | 0 |
| Cruceta (centro) | −118 | −1 |
| ABXY (centro) | +118 | +29,3 |
| − / + | ∓105,5 | +45,2 |
| Captura | −109,2 | −21,5 |
| HOME | +109,2 | −21,5 |
| C | +109,2 | −34,0 |

Stick: capuchón Ø 17,1, sobresale ~7,2 mm. Joy-Con 2: 37 mm de ancho visible, extremos
con radio ~29 mm. Tablet ~198 mm (el autor lo marca como aproximación de escala).
