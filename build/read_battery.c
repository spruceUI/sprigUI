#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>

#define SARADC_IOC_MAGIC 'a'
#define IOCTL_SAR_INIT _IO(SARADC_IOC_MAGIC, 0)
#define IOCTL_SAR_SET_CHANNEL_READ_VALUE _IO(SARADC_IOC_MAGIC, 1)

typedef struct {
    int channel_value;
    int adc_value;
} sar_adc_config_read;

int main(void) {
    int sar_fd = open("/dev/sar", O_WRONLY);
    if (sar_fd < 0) {
        perror("Failed to open /dev/sar");
        return 1;
    }

    if (ioctl(sar_fd, IOCTL_SAR_INIT, NULL) < 0) {
        perror("IOCTL_SAR_INIT failed");
        close(sar_fd);
        return 1;
    }

    sar_adc_config_read adc_cfg = {0, 0};
    if (ioctl(sar_fd, IOCTL_SAR_SET_CHANNEL_READ_VALUE, &adc_cfg) < 0) {
        perror("IOCTL_SAR_SET_CHANNEL_READ_VALUE failed");
        close(sar_fd);
        return 1;
    }

    int adc = adc_cfg.adc_value;
    int current_charge = 0;

    if (adc >= 528)
        current_charge = adc - 478;
    else if (adc >= 512)
        current_charge = (int)(adc * 2.125 - 1068);
    else if (adc >= 480)
        current_charge = (int)(adc * 0.51613 - 243.742);
    else
        current_charge = 0;

    if (current_charge < 0) current_charge = 0;
    if (current_charge > 100) current_charge = 100;

    printf("%d\n", current_charge);

    close(sar_fd);
    return 0;
}
