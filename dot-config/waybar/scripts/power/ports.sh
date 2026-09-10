#!/usr/bin/env bash
# =============================================================================
# Ports: contracts the domain needs fulfilled. Adapters override these.
# Dependencies point inward: adapters depend on these ports, never the reverse.
#
# Contract:
#   gateway_get_active            -> prints the current profile name
#   gateway_set_profile <name>    -> exit 0 on success, non-zero on failure
#   gateway_notify <summary> <body> [urgency]
#   gateway_prompt <menu_text> <prompt> -> prints the chosen line (may be empty)
# =============================================================================

gateway_get_active() { :; }
gateway_set_profile() { :; }
gateway_notify() { :; }
gateway_prompt() { :; }