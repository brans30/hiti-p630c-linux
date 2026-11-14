#!/usr/bin/env bash
# Remove the HiTi P630C queue, the HiTi tables, and release the apt hold.
# Gutenprint itself stays installed (run "sudo make uninstall" in the
# Gutenprint source folder if you also want to remove it).
set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root: sudo ./uninstall.sh"; exit 1; }
PRINTER_NAME="${PRINTER_NAME:-HiTi_P630C}"

lpadmin -x "$PRINTER_NAME" 2>/dev/null && echo "Removed printer $PRINTER_NAME"

TABLES=(CCPPrp.bin CCQPrp.bin CMPPrp.bin CMQPrp.bin MCPatn_1.bin MCPatn_2.bin
        MCPatn_3.bin heatpcrp.bin heatqcrp.bin heatqhrp.bin heattcrp.bin heatthrp.bin)
for d in /usr/local/share/gutenprint/backend_data /usr/share/gutenprint/backend_data; do
  for f in "${TABLES[@]}"; do rm -f "$d/$f"; done
done
echo "Removed HiTi tables"

apt-mark unhold printer-driver-gutenprint >/dev/null 2>&1 || true
systemctl restart cups
echo "Done."
