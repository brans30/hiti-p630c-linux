#!/usr/bin/env bash
# =====================================================================
#  HiTi P630C - Linux driver installer (Ubuntu / Debian)
#  - Patches Gutenprint 5.3.6 to recognise USB ID 0d16:0513 (P630C)
#  - Builds and installs Gutenprint
#  - Installs HiTi heat/colour tables (.bin) needed for real printing
#  - Adds the printer to CUPS with 6x8 as default size
#
#  Usage:
#    sudo ./install.sh                      # auto-find everything in ~/Downloads
#    sudo ./install.sh /path/to/gutenprint-5.3.6-...      (folder or archive)
#    sudo HITI_ZIP=/path/to/P630_Driver_v1.0.5.23.zip ./install.sh
#
#  The HiTi heat/colour tables (*.bin) are HiTi property and are NOT
#  shipped here. They are extracted from the official HiTi Windows driver
#  (P630_Driver_v*.zip) that you download yourself from HiTi.
#  Options (env vars):
#    PAGESIZE=w288h432 sudo -E ./install.sh   # default size 4x6 instead of 6x8
#    SKIP_BUILD=1 sudo -E ./install.sh        # only install .bin + add printer
# =====================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$HERE/data"
PRINTER_NAME="${PRINTER_NAME:-HiTi_P630C}"
PAGESIZE="${PAGESIZE:-w432h576}"      # 6x8 ; 4x6 = w288h432
USB_PID="0x0513"

green(){ printf '\e[32m%s\e[0m\n' "$*"; }
yellow(){ printf '\e[33m%s\e[0m\n' "$*"; }
red(){ printf '\e[31m%s\e[0m\n' "$*" >&2; }
step(){ echo; green "==> $*"; }

if [[ $EUID -ne 0 ]]; then
  red "شغّل السكربت بصلاحيات root:  sudo ./install.sh"
  exit 1
fi

REAL_USER="${SUDO_USER:-root}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

# ---------------------------------------------------------------------
# 0) Get HiTi tables from the official Windows driver package
# ---------------------------------------------------------------------
have_tables(){ [[ -f "$DATA_DIR/CCQPrp.bin" && -f "$DATA_DIR/heatqcrp.bin" ]]; }
if ! have_tables; then
  ZIP="${HITI_ZIP:-}"
  if [[ -z "$ZIP" ]]; then
    for z in "$HERE"/P630_Driver*.zip "$REAL_HOME"/Downloads/P630_Driver*.zip; do
      [[ -f "$z" ]] && { ZIP="$z"; break; }
    done
  fi
  if [[ -z "$ZIP" || ! -f "$ZIP" ]]; then
    red "Missing HiTi tables. Download the official HiTi P630 Windows driver"
    red "(P630_Driver_v1.0.5.23.zip) and put it in ~/Downloads or next to this script,"
    red "or run:  sudo HITI_ZIP=/path/to/P630_Driver.zip ./install.sh"
    red "ملفات الحرارة غير موجودة: نزّل تعريف ويندوز الرسمي P630_Driver.zip وضعه في ~/Downloads"
    exit 1
  fi
  command -v unzip >/dev/null || apt-get install -y -qq unzip >/dev/null
  green "Extracting HiTi tables from: $ZIP"
  TMPX="$(mktemp -d)"
  unzip -q -o "$ZIP" '*/Common/*.bin' -d "$TMPX" 2>/dev/null || unzip -q -o "$ZIP" -d "$TMPX"
  mkdir -p "$DATA_DIR"
  find "$TMPX" -ipath '*/Common/*.bin' -exec cp {} "$DATA_DIR"/ \;
  rm -rf "$TMPX"
  have_tables || { red "heatqcrp.bin / CCQPrp.bin not found inside $ZIP"; exit 1; }
fi

# ---------------------------------------------------------------------
# 1) Locate Gutenprint source
# ---------------------------------------------------------------------
find_source() {
  local arg="${1:-}"
  if [[ -n "$arg" ]]; then
    if [[ -d "$arg" ]]; then echo "$(cd "$arg" && pwd)"; return; fi
    if [[ -f "$arg" ]]; then
      local work="/usr/local/src/hiti-p630c"
      mkdir -p "$work"
      tar xf "$arg" -C "$work"
      find "$work" -maxdepth 1 -mindepth 1 -type d -name 'gutenprint*' | head -1
      return
    fi
    red "المسار غير موجود: $arg"; exit 1
  fi
  local d
  for d in "$HERE"/gutenprint-5.3* "$REAL_HOME"/Downloads/gutenprint-5.3*; do
    [[ -d "$d" && -f "$d/src/cups/backend_hiti.c" ]] && { echo "$d"; return; }
  done
  for d in "$HERE"/gutenprint-5.3*.tar.* "$REAL_HOME"/Downloads/gutenprint-5.3*.tar.*; do
    [[ -f "$d" ]] && { find_source "$d"; return; }
  done
  echo ""
}

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  SRC="$(find_source "${1:-}")"
  if [[ -z "$SRC" || ! -f "$SRC/src/cups/backend_hiti.c" ]]; then
    red "لم أجد مصدر Gutenprint 5.3.6."
    red "ضع مجلد أو ملف gutenprint-5.3.6-* بجانب السكربت أو في ~/Downloads، أو مرّر المسار:"
    red "  sudo ./install.sh /path/to/gutenprint-5.3.6-..."
    exit 1
  fi
  if ! grep -q "P_HITI_630" "$SRC/src/cups/backend_hiti.c"; then
    red "هذه النسخة من Gutenprint لا تدعم عائلة P630 (تحتاج 5.3.6 snapshot أو أحدث)."
    exit 1
  fi
  green "مصدر Gutenprint: $SRC"

  # -------------------------------------------------------------------
  # 2) Dependencies
  # -------------------------------------------------------------------
  step "تثبيت أدوات البناء"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq build-essential libcups2-dev libusb-1.0-0-dev \
      libtool autoconf automake autopoint gettext pkg-config cups \
      libexpat1-dev flex bison imagemagick >/dev/null

  # -------------------------------------------------------------------
  # 3) Patch (idempotent)
  # -------------------------------------------------------------------
  step "تعديل المصدر لإضافة P630C (USB 0d16:0513)"
  BK="$SRC/src/cups/backend_hiti.c"
  XML="$SRC/src/xml/printers/dyesub.xml"

  if grep -qE "0x0d16, *${USB_PID}, *P_HITI_630" "$BK"; then
    yellow "backend_hiti.c معدّل مسبقًا"
  elif grep -qE '^//.*"hiti-p630c"' "$BK"; then
    sed -i -E "s|^//[[:space:]]*\{ *0x0d16, *[^,]*, *P_HITI_630, *NULL, *\"hiti-p630c\"\}.*|\t{ 0x0d16, ${USB_PID}, P_HITI_630, NULL, \"hiti-p630c\"},|" "$BK"
  else
    sed -i -E "/\"hiti-p630a\"\}/a\\\t{ 0x0d16, ${USB_PID}, P_HITI_630, NULL, \"hiti-p630c\"}," "$BK"
  fi
  grep -qE "0x0d16, *${USB_PID}, *P_HITI_630" "$BK" || { red "فشل تعديل backend_hiti.c"; exit 1; }

  if grep -q 'driver="hiti-p630c"' "$XML"; then
    yellow "dyesub.xml معدّل مسبقًا"
  else
    sed -i '/driver="hiti-p630a"/a\      <printer translate="name" name="HiTi P630C" deviceid="MFG:HiTi;MDL:P630C;CLS:PRINTER;" driver="hiti-p630c" manufacturer="HiTi" model="6504" />' "$XML"
  fi
  grep -q 'driver="hiti-p630c"' "$XML" || { red "فشل تعديل dyesub.xml"; exit 1; }

  # -------------------------------------------------------------------
  # 4) Build & install
  # -------------------------------------------------------------------
  step "بناء Gutenprint (قد يستغرق عدة دقائق)"
  cd "$SRC"
  if [[ ! -x ./configure ]]; then
    ./autogen.sh >/dev/null 2>&1 || autoreconf -fi
  fi
  [[ -f Makefile ]] || ./configure --without-gimp2 >/tmp/hiti-configure.log 2>&1 \
      || { red "فشل configure — راجع /tmp/hiti-configure.log"; exit 1; }
  make -j"$(nproc)" >/tmp/hiti-make.log 2>&1 \
      || { red "فشل البناء — راجع /tmp/hiti-make.log"; exit 1; }
  make install >/tmp/hiti-install.log 2>&1 \
      || { red "فشل التثبيت — راجع /tmp/hiti-install.log"; exit 1; }
  ldconfig
  chown -R "$REAL_USER":"$REAL_USER" "$SRC" 2>/dev/null || true

  # prevent apt from overwriting the patched build
  if dpkg -s printer-driver-gutenprint >/dev/null 2>&1; then
    apt-mark hold printer-driver-gutenprint >/dev/null || true
  fi
fi

# ---------------------------------------------------------------------
# 5) Heat / colour tables
# ---------------------------------------------------------------------
step "تثبيت جداول الحرارة والألوان"
TARGETS=(/usr/local/share/gutenprint/backend_data /usr/share/gutenprint/backend_data)
BACKEND_BIN=""
for b in /usr/lib/cups/backend/gutenprint53+usb /usr/local/lib/cups/backend/gutenprint53+usb; do
  [[ -x "$b" ]] && { BACKEND_BIN="$b"; break; }
done
if [[ -n "$BACKEND_BIN" ]]; then
  P="$(strings "$BACKEND_BIN" 2>/dev/null | grep -m1 -E '/backend_data$' || true)"
  [[ -n "$P" ]] && TARGETS+=("$P")
fi
for t in $(printf '%s\n' "${TARGETS[@]}" | sort -u); do
  mkdir -p "$t"
  install -m 644 "$DATA_DIR"/*.bin "$t"/
  echo "  -> $t"
done

# ---------------------------------------------------------------------
# 6) Restart CUPS & add printer
# ---------------------------------------------------------------------
step "إعادة تشغيل CUPS"
command -v cups-genppdupdate >/dev/null && cups-genppdupdate >/dev/null 2>&1 || true
systemctl restart cups
sleep 3

[[ -n "$BACKEND_BIN" ]] || { red "لم أجد gutenprint53+usb backend"; exit 1; }

step "البحث عن الطابعة على USB"
URI="$("$BACKEND_BIN" 2>/dev/null | awk '/hiti-p630c/ {print $2; exit}')"
MODEL="$(lpinfo -m 2>/dev/null | awk '/hiti-p630c\/expert/ {print $1; exit}')"

if [[ -z "$MODEL" ]]; then
  red "تعريف HiTi P630C غير ظاهر في CUPS (lpinfo -m). هل نجح البناء؟"
  exit 1
fi

if [[ -z "$URI" ]]; then
  yellow "الطابعة غير موصولة أو مطفأة. تم تثبيت التعريف فقط."
  yellow "بعد توصيلها شغّل:  sudo SKIP_BUILD=1 ./install.sh"
  exit 0
fi
green "تم العثور على: $URI"

lpadmin -p "$PRINTER_NAME" -E -v "$URI" -m "$MODEL" \
        -o PageSize-default="$PAGESIZE" -o printer-is-shared=false
lpadmin -d "$PRINTER_NAME"
sudo -u "$REAL_USER" lpoptions -d "$PRINTER_NAME" >/dev/null 2>&1 || true

# ---------------------------------------------------------------------
# 7) Optional test print
# ---------------------------------------------------------------------
echo
read -r -p "طباعة صفحة اختبار الآن؟ [y/N] " ans || ans=n
if [[ "$ans" =~ ^[Yy]$ ]]; then
  IMG=/tmp/hiti_p630c_test.jpg
  if command -v convert >/dev/null; then
    convert -size 1800x2400 gradient:red-blue -gravity center -pointsize 140 \
      -fill white -annotate 0 "HiTi P630C\nLinux OK" -units PixelsPerInch \
      -density 300 "$IMG"
    lp -d "$PRINTER_NAME" -o PageSize="$PAGESIZE" "$IMG"
  else
    yellow "ImageMagick غير مثبت، تخطّيت صفحة الاختبار"
  fi
fi

echo
green "تم التثبيت بنجاح. الطابعة: $PRINTER_NAME  (المقاس الافتراضي: $PAGESIZE)"
echo "لتغيير المقاس إلى 4x6:  sudo lpadmin -p $PRINTER_NAME -o PageSize-default=w288h432"
