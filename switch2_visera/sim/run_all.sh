#!/bin/sh
# Ejecuta todos los casos de carga en PLA y PETG. Resultados en sim/out/*/result.json
cd "$(dirname "$0")/.."
for c in screen_point stick_point backpack_crush; do for m in pla petg; do
  python3 sim/fea.py $c $m --size 1.2 > sim/out/log_${c}_${m}.txt 2>&1
done; done
for m in pla petg; do python3 sim/fea.py snap_fit $m --size 0.6 > sim/out/log_snap_fit_${m}.txt 2>&1; done
echo DONE > sim/out/ALL_DONE
