#!/bin/bash

case "$(date +%u)" in
  1) weekday_vertical=$'星\n期\n一'; weekday_long="星期一" ;;
  2) weekday_vertical=$'星\n期\n二'; weekday_long="星期二" ;;
  3) weekday_vertical=$'星\n期\n三'; weekday_long="星期三" ;;
  4) weekday_vertical=$'星\n期\n四'; weekday_long="星期四" ;;
  5) weekday_vertical=$'星\n期\n五'; weekday_long="星期五" ;;
  6) weekday_vertical=$'星\n期\n六'; weekday_long="星期六" ;;
  7) weekday_vertical=$'星\n期\n日'; weekday_long="星期日" ;;
esac

printf -v text "%s\n%s\n%s" "$weekday_vertical" "$(date +%H)" "$(date +%M)"
tooltip="$(date +%Y年%m月%d日) $weekday_long $(date +%H:%M)"

jq -cn --arg text "$text" --arg tooltip "$tooltip" '{text:$text,tooltip:$tooltip}'
