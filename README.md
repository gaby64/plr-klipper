A simple print recovery system for Klipper

Klipper config:

To install, add these files somewhere that klipper can access them.  ~/. should be a fine choice, if you have no idea.
You must then add an [include] directive in order to add the contents of plr.cfg to your printer.cfg, or just paste it in if you don't like [include] directives.  
plr.sh must be marked executable.  Also, plr.cfg and plr.sh must be modified to reflect the location of your virtual sdcard in Klipper.

In addition, the Kiauh Gcode Shell Command extenstion must be added to Klipper.  You don't need to have Kiuah installed, but you must add gcode_shell_command.py to the contents of your klipper/klippy/extras directory (The extension can be downloaded here: https://github.com/th33xitus/kiauh/blob/master/resources/gcode_shell_command.py )

# Gaby_64:
Disk Flush script requires the user to have passwordless root privileges so that kliper gcode command can run it.

`sudo visudo`\
add the following below %sudo:\
`mks     ALL=(ALL) NOPASSWD:ALL`

```
[gcode_button pw_det]
pin: ^!PE15
press_gcode =
  {% if printer.virtual_sdcard.is_active or printer.print_stats.state == "printing" %}
    {action_respond_info("Power Loss while Printing!")}
    M104 S0
    M140 S0
    PAUSE INTERUPTONLY=1
    LOG_Z EOFF=2 ZOFF=10
    SAVE_VARIABLE VARIABLE=was_interrupted VALUE=True
    RUN_SHELL_COMMAND CMD=FLUSHDISK
    G91
    {% if printer.extruder.can_extrude|lower == 'true' %}
      G1 E-2 F1000
    {% else %}
      {action_respond_info("Power Loss Extruder not hot enough to retract")}
    {% endif %}
    G1 Z10 F900
    G90
    CANCEL_PRINT INTERUPTONLY=1
  {% else %}
    {action_respond_info("Power Loss!")}
  {% endif %}
release_gcode =
  {action_respond_info("Power Returned!")}
```
#

Finally, this must be added to the end of your start gcode (either macro or slicer):
SAVE_VARIABLE VARIABLE=was_interrupted VALUE=True

and this must be added to the beginning of your end gcode (either macro or slicer):
SAVE_VARIABLE VARIABLE=was_interrupted VALUE=False


Slicer config:
It is necessary to call the Klipper LOG_Z macro from your slicer at every layer change.  You don't need to get fancy and specify any parameters.  Klipper will figure out the current Z, once the macro is invoked. In Cura, you use the Insert At Layer Change post processor, select the Before option, and then type 'LOG_Z' (without the quotes) into the gcode to insert field.  The config for other slicers should be similar


Notes:  This tool tries to figure out the temperature of the print prior to failure, proceeding from least to most accurate.  It first adds a call to START_TEMPS (It is advised to add a macro called START_TEMPS that heats up your printer to sane values).  It then scans the gcode for all temperature gcodes up to the time the print failed, and adds them in that order.  Finally, in the case of Cura, it scans the end gcode for the Cura print settings, and adds the temperatures from the Cura print settings. 

I do believe the main reason Kevin has not offered a native implementation of Power Loss Recovery is in large part due to conerns regarding SD card life, since Klipper is often run from an SD card on an RPI.  If this is a concern for you, it is recommended to mount the virtual sd card directory on a separate, disposable SD card to save wear on the main card used for the Klipper distribution, and then to configure the Klipper saved variables section to use the virtual sd card directory


Operation:

If a power loss occurrs, raise the print head and clean/cut off any blobs that may have rsulted from the failure.  Wait for the hotend to cool, clean the nozzle tip, and then place the nozzle tip on the highest point of the print.  Use a light touch - the gantry should still be able to move across the print, but scrape slightly.  Then navigate to the gcode file in the SD Card menu, and select the file.  Then back out of the SD Card menu and re-enter it (no idea how to refresh the menu otherwise).  The menu should now contain a "Recover Failed" option to recover the failed print.  Select the option.  The printer should home axes, wait to heat up, and then resume the print.

More savvy users can take advantage of the RESUME_INTERRUPTED macro, and specify the GCODE_FILE parameter with the filename (along with fully qualified path) to achieve the same thing.  The most advanced users can use this macro to resume prints that failed due to filament runout, heat creep, etc.  Measure the height of the failure, and then use the RESUME_INTERRUPTED macro, also specifying the parameter Z_HEIGHT to reflect the measured height.

