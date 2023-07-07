#!/bin/bash
#other considerations, trust XY? home XY? trust Z didnt move since power failure? home Z? where is it safe to home Z?
echo ${1} ${2} ${3} X${4} Y${5} E${6} EOFF${7} ZOFF${8}
SD_PATH=~/printer_data/gcodes
cat ${2} > /tmp/plrtmpA.$$
#shift by one, from match delete to beginning 
#purpose, get value for SET_KINEMATIC_POSITION Z to place at start of gcode
ZOFF=${8:=0}
if [ ${3} ]; then
  Z=${1}
  KZ=$(bc -l <<<"${Z}+${ZOFF}")
  echo "SET_KINEMATIC_POSITION Z=${KZ}" > ${SD_PATH}/plr.gcode
else
  cat /tmp/plrtmpA.$$ | sed -e '0,/Z'${1}'/ d' | grep -m 1 ' Z' | sed -ne 's/.* Z\([^ ]*\)/SET_KINEMATIC_POSITION Z=\1/p' > ${SD_PATH}/plr.gcode
fi
echo 'G91' >> ${SD_PATH}/plr.gcode
echo 'G1 Z5' >> ${SD_PATH}/plr.gcode
echo 'G90' >> ${SD_PATH}/plr.gcode
echo 'G28 X Y' >> ${SD_PATH}/plr.gcode
echo 'START_TEMPS' >> ${SD_PATH}/plr.gcode
#write temp commands
cat /tmp/plrtmpA.$$ | sed '/ Z'${1}'/q' | sed -ne '/\(M104\|M140\|M109\|M190\|M106\)/p' >> ${SD_PATH}/plr.gcode
#if material_bed_temperature set, write M140
cat /tmp/plrtmpA.$$ | sed -ne '/;End of Gcode/,$ p' | tr '\n' ' ' | sed -ne 's/ ;[^ ]* //gp' | sed -ne 's/\\\\n/;/gp' | tr ';' '\n' | grep material_bed_temperature | sed -ne 's/.* = /M140 S/p' | head -1 >> ${SD_PATH}/plr.gcode
#if material_print_temperature set, write M104
cat /tmp/plrtmpA.$$ | sed -ne '/;End of Gcode/,$ p' | tr '\n' ' ' | sed -ne 's/ ;[^ ]* //gp' | sed -ne 's/\\\\n/;/gp' | tr ';' '\n' | grep material_print_temperature | sed -ne 's/.* = /M104 S/p' | head -1 >> ${SD_PATH}/plr.gcode
#if material_bed_temperature set, write M190
cat /tmp/plrtmpA.$$ | sed -ne '/;End of Gcode/,$ p' | tr '\n' ' ' | sed -ne 's/ ;[^ ]* //gp' | sed -ne 's/\\\\n/;/gp' | tr ';' '\n' | grep material_bed_temperature | sed -ne 's/.* = /M190 S/p' | head -1 >> ${SD_PATH}/plr.gcode
#if material_print_temperature set, write M109
cat /tmp/plrtmpA.$$ | sed -ne '/;End of Gcode/,$ p' | tr '\n' ' ' | sed -ne 's/ ;[^ ]* //gp' | sed -ne 's/\\\\n/;/gp' | tr ';' '\n' | grep material_print_temperature | sed -ne 's/.* = /M109 S/p' | head -1 >> ${SD_PATH}/plr.gcode
# cat /tmp/plrtmpA.$$ | sed -e '1,/ Z'${1}'[^0-9]*$/ d' | sed -e '/ Z/q' | tac | grep -m 1 ' E' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p' >> ${SD_PATH}/plr.gcode
#tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -e '/ Z[0-9]/ q' | tac | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p' >> ${SD_PATH}/plr.gcode

echo ${3}
if [ ${3} ]; then
  ZPOS=${3}
  LF=`wc -l /tmp/plrtmpA.$$ | sed 's/\s.*$//'`
  LZ=`tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | wc -l`
  GL=`grep -Fn "X${4} Y${5} E${6}" /tmp/plrtmpA.$$ | cut --delimiter=":" --fields=1`
  if [ "${GL}" = "" ]; then
    echo 'No match XYE, trying XYZE'
    GL=`grep -Fn "X${4} Y${5} Z${1} E${6}" /tmp/plrtmpA.$$ | cut --delimiter=":" --fields=1`
  fi
  if [ "${GL}" = "" ]; then
    echo 'No match XYZE, trying XY'
    L=1
    GL=`grep -Fn "X${4} Y${5}" /tmp/plrtmpA.$$ | cut --delimiter=":" --fields=1 | sed -n ''${L}'p'`
    LN=`tac /tmp/plrtmpA.$$ | sed -e '/ Z0.58[^0-9]*$/q' | tac | tail -n+1 | wc -l`
    UPB=$(( LF - LN ))
#    while [ "${GL}" != "" && ( "${GL}" -gt "${UPB}" || "${GL}" -lt "${LZ}" ) ]
    while [ "${GL}" != "" ] && ( [ "${GL}" -gt "${UPB}" ] || [ "${GL}" -lt "${LZ}" ] )
    do
      ((L=L+1))
      GL=`grep -Fn "X${4} Y${5}" /tmp/plrtmpA.$$ | cut --delimiter=":" --fields=1 | sed -n ''${L}'p'`
    done
  fi
  if [ "${GL}" = "" ]; then
    echo 'No match XY'
    exit 1
  fi
  echo ${LF}
  echo ${LZ}
  echo ${GL}
  ZPOS=${GL}
  NP=$(( ZPOS - (LF - LZ) ))
  NPM=$(( NP - 1 ))
  echo ${NPM}
  BG_EX=`tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+${NPM} | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p'`
#empty??
  if [ ${7} ]; then
    echo 'G91' >> ${SD_PATH}/plr.gcode
    echo 'G1 E'${7}'' >> ${SD_PATH}/plr.gcode
    echo 'G90' >> ${SD_PATH}/plr.gcode
  fi
  echo ${BG_EX} >> ${SD_PATH}/plr.gcode
  echo 'G91' >> ${SD_PATH}/plr.gcode
  echo 'G1 Z-'${ZOFF}'' >> ${SD_PATH}/plr.gcode
  echo 'G1 Z-5' >> ${SD_PATH}/plr.gcode
  echo 'G90' >> ${SD_PATH}/plr.gcode
  tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+${NPM} >> ${SD_PATH}/plr.gcode
else
  #from end of file, at matched layer, find last G92 E, extruder position set
  BG_EX=`tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -e '/ Z[0-9]/ q' | tac | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p'`
  # If we failed to match an extrusion command (allowing us to correctly set the E axis) prior to the matched layer height, then simply set the E axis to the first E value present in the resemu>
  if [ "${BG_EX}" = "" ]; then
   BG_EX=`tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -ne '/ Z/,$ p' | sed -e '/ E[0-9]/ q' | sed -ne 's/.* E\([^ ]*\)/G92 E\1/p'`
  fi
  echo ${BG_EX} >> ${SD_PATH}/plr.gcode
  echo 'G91' >> ${SD_PATH}/plr.gcode
  echo 'G1 Z-5' >> ${SD_PATH}/plr.gcode
  echo 'G90' >> ${SD_PATH}/plr.gcode
  # cat /tmp/plrtmpA.$$ | sed -e '1,/Z'${1}'/ d' | sed -ne '/ Z/,$ p' >> ${SD_PATH}/plr.gcode
  tac /tmp/plrtmpA.$$ | sed -e '/ Z'${1}'[^0-9]*$/q' | tac | tail -n+2 | sed -ne '/ Z/,$ p' >> ${SD_PATH}/plr.gcode
fi
rm /tmp/plrtmpA.$$

