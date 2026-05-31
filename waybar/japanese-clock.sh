#!/bin/bash

case "$(date +%u)" in
  1) weekday_vertical=$'月\n曜\n日'; weekday_long="月曜日" ;;
  2) weekday_vertical=$'火\n曜\n日'; weekday_long="火曜日" ;;
  3) weekday_vertical=$'水\n曜\n日'; weekday_long="水曜日" ;;
  4) weekday_vertical=$'木\n曜\n日'; weekday_long="木曜日" ;;
  5) weekday_vertical=$'金\n曜\n日'; weekday_long="金曜日" ;;
  6) weekday_vertical=$'土\n曜\n日'; weekday_long="土曜日" ;;
  7) weekday_vertical=$'日\n曜\n日'; weekday_long="日曜日" ;;
esac

printf -v text "%s\n%s\n%s" "$weekday_vertical" "$(date +%H)" "$(date +%M)"
tooltip="$(date +%Y-%m-%d) $weekday_long $(date +%H:%M)"

jq -cn --arg text "$text" --arg tooltip "$tooltip" '{text:$text,tooltip:$tooltip}'
