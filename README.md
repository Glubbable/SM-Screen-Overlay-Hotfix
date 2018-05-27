# SM-Screen-Overlay-Hotfix
This is a (crappy) plugin to temp fix the incorrect clearing of r_screenoverlay until you (or plugin author) fixes the plugin that caused it.

Cvar: sm_enable_screenoverlay_fix
- Default Value 1.
- Value 0 Disables Plugin (Although you should just remove it if you don't need it anymore...)
- Value 1 Enables Plugin

Cvar: sm_screenoverlay_debug_level 
- Default Value 1.
- Value 0 disables debug logging.
- Value 1 prints single error line to SM Error Logs with Map Name.
- Value 2 prints single error line & enables console logging to print out Plugin List to SMs log folder.
