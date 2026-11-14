# Report to Gutenprint (SourceForge → gimp-print → Support Requests / Patches)

**Title:** HiTi P630C (USB 0d16:0513) works as P_HITI_630 — please enable the placeholder

**Body (copy‑paste):**

```
Hello Solomon,

The HiTi P630C placeholder in backend_hiti.c
  //	{ 0x0d16, XXXXX, P_HITI_630, NULL, "hiti-p630c"}, // placeholder
can be enabled: the printer enumerates as USB 0d16:0513.

lsusb:
  ID 0d16:0513 Hi-Touch Imaging Technologies Co., Ltd USB Photo Printer

Backend -i output:
  INFO: Printer ID: HiTi:Usb Photo Printer:HiTi P630C
  INFO: Printer Version: 1.02.0.N
  INFO: Calibration:  H: 7 V: 6
  INFO: Status Summary: 1920 1844x1240 300x300
  INFO: Media: 6x8 (04 / 1700)
  INFO: Paper: 6 inch (01)
  WARNING: Printer firmware 1.02.0.N out of date (vs v9.05.2.3), please update.

With the attached patch (USB ID in backend_hiti.c + "HiTi P630C" entry in
dyesub.xml, model 6504), and the P630 tables heatqcrp.bin / CCQPrp.bin from
HiTi's P630_Driver_v1.0.5.23 placed in backend_data, printing works correctly
in colour on 6x8 media:
  - w432h576 (6x8)
  - w288h432 (4x6)
  - w432h576-div2 (2x 4x6)

Without the tables the printer feeds blank paper (warnings
"Unable to find suitable heat table file (heatqcrp.bin)").

Tested: Gutenprint 5.3.6-2026-02-16T02-19-a019bf9c, backend 0.134G
(HiTi 0.97), CUPS 2.4.7, Ubuntu 24.04.3.

Thanks for your work on these backends!
```

Attach: `patches/0001-hiti-p630c-usb-id.patch`

## Regenerating a clean patch (recommended before sending)

The included patch was built from excerpts and applies with small fuzz.
To create an exact one on the machine that has the original source archive:

```bash
mkdir -p ~/gp-orig && tar xf ~/Downloads/gutenprint-5.3.6-*.tar.* -C ~/gp-orig
cd ~/Downloads
diff -u ~/gp-orig/gutenprint-5.3.6-*/src/cups/backend_hiti.c \
        gutenprint-5.3.6-*/src/cups/backend_hiti.c >  hiti-p630c.patch
diff -u ~/gp-orig/gutenprint-5.3.6-*/src/xml/printers/dyesub.xml \
        gutenprint-5.3.6-*/src/xml/printers/dyesub.xml >> hiti-p630c.patch
```

Do not include your printer's serial number in public reports.
