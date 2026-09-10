#!/bin/bash

if pgrep -x "gammastep" > /dev/null; then
    echo '{"text":"On","tooltip":"<span foreground=\"#f5c2e7\" font_weight=\"bold\">GAMMASTEP</span>\n<span foreground=\"#6c7086\">Status</span>  <span foreground=\"#cdd6f4\">Active</span>"}'
else
    echo '{"text":"Off","tooltip":"<span foreground=\"#f5c2e7\" font_weight=\"bold\">GAMMASTEP</span>\n<span foreground=\"#6c7086\">Status</span>  <span foreground=\"#cdd6f4\">Inactive</span>"}'
fi