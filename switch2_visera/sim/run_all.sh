#!/bin/sh
# Casos de carga de la versión actual. stick_point usa el cuerpo CAD exacto
# (sim/body_occ.py); flap_2d, una franja del corte real de la solapa (sim/profile_occ.py).
cd "$(dirname "$0")/.."
run() { python3 sim/fea.py $1 $2 --size $3 > sim/out/log_$1_$2.txt 2>&1; }
mkdir -p sim/out
run flap_2d pla 0.4
run flap_2d petg 0.4
run stick_point pla 1.2
echo DONE > sim/out/ALL_DONE
