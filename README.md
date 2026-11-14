# HiTi P630C — Linux driver (CUPS + Gutenprint)

Makes the **HiTi P630C** dye‑sublimation photo printer (USB `0d16:0513`) print on Ubuntu/Debian.

Gutenprint already supports the HiTi **P630** family, but the P630C's USB ID was missing
(a commented‑out placeholder). This project:

1. Patches Gutenprint 5.3.6 to recognise `0d16:0513` as a P630 (`P_HITI_630`).
2. Builds and installs Gutenprint.
3. Extracts the HiTi heat/colour tables from the **official HiTi Windows driver** you download yourself
   (without them the printer feeds **blank white paper**).
4. Adds the printer to CUPS as the default, with the right page size.

> The `*.bin` tables are HiTi property and are **not** included in this repository.

## Tested

| Item | Value |
|---|---|
| Printer | HiTi P630C, firmware 1.02.0.N |
| OS | Ubuntu 24.04.3 LTS, CUPS 2.4.7 |
| Gutenprint | 5.3.6‑2026‑02‑16T02‑19‑a019bf9c (backend 0.134G, HiTi 0.97) |
| HiTi driver | P630_Driver_v1.0.5.23.zip |
| Media | 6x8 ribbon: 6x8, 4x6, 4x6‑div2 print correctly in colour |

## What you need

- **Gutenprint 5.3.6 snapshot (or newer) source** — from the Gutenprint project's *Files* page on SourceForge
  (stable 5.3.4 is too old: it has no P630 support).
- **HiTi P630 Windows driver** `P630_Driver_v1.0.5.23.zip` — from HiTi's download site.
- Internet access (build tools are installed with apt).

## Install

```bash
# put the Gutenprint source and P630_Driver_*.zip in ~/Downloads, then:
tar xzf hiti-p630c-linux.tar.gz        # or: git clone <this repo>
cd hiti-p630c-linux
sudo ./install.sh
```

Options:

```bash
sudo ./install.sh /path/to/gutenprint-5.3.6-...          # source folder or archive
sudo HITI_ZIP=/path/to/P630_Driver_v1.0.5.23.zip ./install.sh
sudo PAGESIZE=w288h432 ./install.sh                     # default 4x6 instead of 6x8
sudo SKIP_BUILD=1 ./install.sh                          # tables + printer only
```

Uninstall: `sudo ./uninstall.sh`

## Page sizes

| Size | CUPS name |
|---|---|
| 4x6 | `w288h432` |
| 2× 4x6 on one 6x8 sheet | `w432h576-div2` |
| 5x7 | `w360h504` |
| 6x8 | `w432h576` |
| 6x9 | `w432h648` |

The size must fit the loaded ribbon, otherwise the job is rejected (`Illegal job on 6-inch paper!`).

```bash
lp -d HiTi_P630C -o PageSize=w288h432 photo.jpg
sudo lpadmin -p HiTi_P630C -o PageSize-default=w288h432
```

## Troubleshooting

```bash
sudo grep -E "^[EW] |Unable to find|Illegal" /var/log/cups/error_log
BACKEND=hiti sudo -E /usr/lib/cups/backend/gutenprint53+usb -s   # printer status
```

| Message | Meaning / fix |
|---|---|
| `Unable to find suitable heat table file (heatqcrp.bin)` | Tables missing → blank prints. Re-run with `HITI_ZIP=…` |
| `Illegal job on 6-inch paper!` | Page size does not match the ribbon |
| `Printer firmware … out of date` | Warning only, printing works |
| Printer not detected | Check `lsusb | grep 0d16` and that the printer is on |

Cut position is calibrated **inside the printer** (HiTi `CalTolA.exe` tool on Windows); Linux reads those values automatically.

## Upstream

The Gutenprint change is in [`patches/0001-hiti-p630c-usb-id.patch`](patches/0001-hiti-p630c-usb-id.patch)
and has been / should be reported to Gutenprint so future releases support the P630C out of the box.
See [`docs/UPSTREAM_REPORT.md`](docs/UPSTREAM_REPORT.md).

## License

Scripts: MIT (see `LICENSE`). The patch modifies Gutenprint and is under Gutenprint's license (GPL‑2.0‑or‑later).
HiTi is a trademark of its owner; this project is not affiliated with HiTi.

---

# بالعربي

تعريف لطابعة **HiTi P630C** على أوبونتو. يضيف رقم الـ USB الخاص بالطابعة إلى Gutenprint، ويبنيه ويثبّته،
ثم يستخرج ملفات الحرارة والألوان من تعريف ويندوز الرسمي الذي تنزّله بنفسك من HiTi، ويضيف الطابعة إلى CUPS.

**التثبيت:** ضع مصدر Gutenprint 5.3.6 وملف `P630_Driver_v1.0.5.23.zip` في `~/Downloads`، ثم:

```bash
tar xzf hiti-p630c-linux.tar.gz
cd hiti-p630c-linux
sudo ./install.sh
```

- إذا خرجت الورقة بيضاء، فملفات الحرارة لم تُثبَّت.
- إذا ظهر `Illegal job`، فالمقاس لا يطابق الشريط المركّب.
- المقاس 4x6 هو `w288h432`، والمقاس 6x8 هو `w432h576`.
