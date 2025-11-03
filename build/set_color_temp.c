// set_color_temp.c
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <stdint.h>
#include <string.h>

/*
 SDK-style struct seen in community docs / SDKs:
 typedef struct MI_DISP_ColorTemperature_s {
     uint16_t u16RedOffset;
     uint16_t u16GreenOffset;
     uint16_t u16BlueOffset;
     uint16_t u16RedColor;
     uint16_t u16GreenColor;
     uint16_t u16BlueColor;
 } MI_DISP_ColorTemperature_t;
*/

typedef struct {
    uint16_t u16RedOffset;
    uint16_t u16GreenOffset;
    uint16_t u16BlueOffset;
    uint16_t u16RedColor;
    uint16_t u16GreenColor;
    uint16_t u16BlueColor;
} MI_DISP_ColorTemperature_t;

/* Function pointer type: MI_S32 MI_DISP_DeviceSetColorTempeture(MI_DISP_DEV DispDev, MI_DISP_ColorTemperature_t *pstColorTempInfo); */
typedef int (*mi_disp_set_colortemp_fn)(int, MI_DISP_ColorTemperature_t*);

/* Usage: set_color_temp <device-lib-path> <redOffset> <greenOffset> <blueOffset> <redColor> <greenColor> <blueColor>
   If lib path is '-' it will try common locations (see code).
   Each value is 0-0xFFFF; typical defaults are 0x0080 (128) for offsets/colors in many SDK examples.
*/

int try_call(const char *libpath, int dev, MI_DISP_ColorTemperature_t *p)
{
    void *h = dlopen(libpath, RTLD_LAZY | RTLD_LOCAL);
    if (!h) {
        fprintf(stderr, "dlopen(%s) failed: %s\n", libpath, dlerror());
        return -1;
    }

    mi_disp_set_colortemp_fn fn = (mi_disp_set_colortemp_fn)dlsym(h, "MI_DISP_DeviceSetColorTempeture");
    if (!fn) {
        fprintf(stderr, "dlsym(MI_DISP_DeviceSetColorTempeture) failed: %s\n", dlerror());
        dlclose(h);
        return -2;
    }

    int rc = fn(dev, p);
    dlclose(h);
    return rc;
}

int main(int argc, char **argv)
{
    if (argc != 8 && argc != 2) {
        fprintf(stderr, "Usage:\n");
        fprintf(stderr, "  %s <lib-path|-> rOff gOff bOff rColor gColor bColor\n", argv[0]);
        fprintf(stderr, "Example: %s - 0x80 0x80 0x80 0x80 0x80 0x80\n", argv[0]);
        return 1;
    }

    const char *libpath = argv[1];
    unsigned long vals[6] = {0x80,0x80,0x80,0x80,0x80,0x80};

    if (argc == 8) {
        for (int i=0;i<6;i++) {
            vals[i] = strtoul(argv[2+i], NULL, 0);
        }
    }

    MI_DISP_ColorTemperature_t st;
    memset(&st, 0, sizeof(st));
    st.u16RedOffset   = (uint16_t)vals[0];
    st.u16GreenOffset = (uint16_t)vals[1];
    st.u16BlueOffset  = (uint16_t)vals[2];
    st.u16RedColor    = (uint16_t)vals[3];
    st.u16GreenColor  = (uint16_t)vals[4];
    st.u16BlueColor   = (uint16_t)vals[5];

    /* candidate library paths to try when user passes "-" */
    const char *candidates[] = {
        "/config/lib/libmi_disp.so",
        "/lib/libmi_disp.so",
        "/usr/lib/libmi_disp.so",
        "/customer/lib/libmi_disp.so"
        "/mnt/SDCARD/sprig/lib/libmi_disp.so"
        "./libmi_disp.so",
        NULL
    };

    int rc = -99;
    if (strcmp(libpath, "-") == 0) {
        for (const char **p = candidates; *p; ++p) {
            rc = try_call(*p, 0, &st);
            if (rc == 0) {
                printf("OK: called %s\n", *p);
                return 0;
            } else {
                /* try next */
            }
        }
        fprintf(stderr, "All library candidates failed, last rc=%d\n", rc);
        return 2;
    } else {
        rc = try_call(libpath, 0, &st);
        if (rc == 0) {
            printf("MI_DISP_DeviceSetColorTempeture returned 0 (success)\n");
            return 0;
        } else {
            fprintf(stderr, "MI_DISP_DeviceSetColorTempeture returned %d\n", rc);
            return 3;
        }
    }
}
