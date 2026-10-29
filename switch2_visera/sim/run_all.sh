#!/bin/sh
# Casos de carga. Con cargas impuestas la tensión apenas depende del material y la
# deformación escala con 1/E, así que PETG se simula en la pantalla (el caso de
# deformación crítico) para confirmarlo; los clips (desplazamiento impuesto) en ambos.
cd "$(dirname "$0")/.."
run() { python3 sim/fea.py $1 $2 --size $3 > sim/out/log_$1_$2.txt 2>&1; }
run screen_point pla 1.2
run stick_point pla 1.2
run backpack_crush pla 1.8
run screen_point petg 1.2
run snap_fit pla 0.6
run snap_fit petg 0.6
echo DONE > sim/out/ALL_DONE
