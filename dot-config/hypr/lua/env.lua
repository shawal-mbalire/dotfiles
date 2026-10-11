-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/configuring/core/environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Single source for values the Quickshell config reads (infra/config/Config.qml).
local shell = {
	preferredSink = "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__Speaker__sink",
	backlight = "intel_backlight",
	colorTemperature = 16000,
}

hl.env("QS_PREFERRED_SINK", shell.preferredSink)
hl.env("QS_BACKLIGHT", shell.backlight)
hl.env("QS_COLOR_TEMPERATURE", tostring(shell.colorTemperature))

return shell
