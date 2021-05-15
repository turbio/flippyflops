/* Uart Events Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/
#include "driver/uart.h"
#include "esp_log.h"
#include "esp_system.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"
#include "nvs_flash.h"
#include "sdkconfig.h"
#include <esp_sleep.h>
#include <float.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

// #define blit_pixel uint8_t
// #include "blit-fonts/blit16.h"

// #include "fonts/font.h"
// #include "fonts/acme_5_outlines_font.h"
// #include "fonts/formplex12_font.h"
#include "fonts/pzim3x5_font.h"

/**
 * This is a example which echos any data it receives on UART back to the sender
 * using RS485 interface in half duplex mode.
 */
#define TAG "flipdots"

#define ECHO_TEST_TXD (CONFIG_ECHO_UART_TXD)
#define ECHO_TEST_RXD (CONFIG_ECHO_UART_RXD)

#define ECHO_TEST_RTS (CONFIG_ECHO_UART_RTS)
#define ECHO_TEST_CTS (UART_PIN_NO_CHANGE)

#define BUF_SIZE (127)
#define ECHO_UART_PORT (CONFIG_ECHO_UART_PORT_NUM)

typedef uint8_t panel[28 * 7];
typedef panel display[4];

void send_cmd(const char *cmd, uint8_t length) {
  if (uart_write_bytes(ECHO_UART_PORT, cmd, length) != length) {
    ESP_LOGE(TAG, "uart write critial err u_u");
    abort();
  }
}

void panel2cmd(char *c, panel p) {
  for (int i = 0; i < 28; i++) {
    c[i] = (!!p[i + 28 * 0]) << 0 | (!!p[i + 28 * 1]) << 1 |
           (!!p[i + 28 * 2]) << 2 | (!!p[i + 28 * 3]) << 3 |
           (!!p[i + 28 * 4]) << 4 | (!!p[i + 28 * 5]) << 5 |
           (!!p[i + 28 * 6]) << 6;
  }
}

void put_display(const display d) {
  for (int i = 0; i < 4; i++) {
    char cmd[32] = {0x80, 0x84, i, [31] = 0x8F};
    panel2cmd(cmd + 3, d[i]);
    send_cmd(cmd, 32);
  }

  send_cmd("\x80\x82\x8F", 3);
}

#define X 1
#define O 0

void putdot(display d, int x, int y, bool on) {
  int panel = x / 28 + (y / 7) * 2;
  if (x >= 0 && x < 28 * 2 && y >= 0 && y < 7 * 2)
    d[panel][(x % 28) + 28 * (y % 7)] = on;
}

void blitstr(display d, int x, int y, const char *str, bool on, bool bg) {
  int width = sizeof(font[0]);
  int height = 5;

  while (*str) {
    for (int cx = 0; cx < width; cx++) {
      bool all0 = true;

      for (int cy = 0; cy < 5; cy++) {
        if (font[*str - 32][cx] & (1 << (cy + 1))) {
          all0 = false;
          putdot(d, x, y + cy, on);
        } else if (bg) {
          putdot(d, x, y + cy, !on);
        }
      }

      if (!all0)
        x++;
    }

    if (bg && *(str + 1))
      for (int cy = 0; cy < height; cy++) {
        putdot(d, x, y + cy, !on);
      }

    x++;
    str++;
  }
}

void clear(display d) {
  for (int p = 0; p < 4; p++) {
    memset(d[p], 0, sizeof(panel));
  }
}

panel checkers_a = {
    X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X,
    O, X, O, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X,
    O, X, O, X, O, X, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X,
    O, X, O, X, O, X, O, X, O, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X,
    O, X, O, X, O, X, O, X, O, X, O, X, X, O, X, O, X, O, X, O, X, O, X, O, X,
    O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, O, X, O, X, O, X, O, X, O, X,
    O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, X, O, X, O, X, O, X,
    O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O,
};

panel checkers_b = {
    O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O,
    X, O, X, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O,
    X, O, X, O, X, O, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O,
    X, O, X, O, X, O, X, O, X, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O,
    X, O, X, O, X, O, X, O, X, O, X, O, O, X, O, X, O, X, O, X, O, X, O, X, O,
    X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, X, O, X, O, X, O, X, O, X, O,
    X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, O, X, O, X, O, X, O,
    X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X, O, X,
};

#define MICROSEC_IN_SEC 1000000

void num_clock(void) {
  display d;
  struct timeval tv = {
      .tv_sec = 0,
      .tv_usec = 0,
  };

  for (;;) {
    long n;
    if (scanf("%ld", &n) != EOF) {
      tv.tv_sec = n;
      settimeofday(&tv, NULL);
    }

    clear(d);

    time_t now;
    time(&now);
    struct tm ts;
    localtime_r(&now, &ts);

    char timestr[strlen("HH:MM") + 1];
    sprintf(timestr, "%02d:%02d", ts.tm_hour, ts.tm_min);
    blitstr(d, 1, 0, timestr, true, false);

    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
}

void word_clock(void) {
  display d;
  struct timeval tv = {
      .tv_sec = 0,
      .tv_usec = 0,
  };

  for (;;) {
    long n;
    if (scanf("%ld", &n) != EOF) {
      tv.tv_sec = n;
      settimeofday(&tv, NULL);
    }

    clear(d);

    time_t now;
    time(&now);
    struct tm ts;
    localtime_r(&now, &ts);

    // engl
    const char *num_english[] = {
        "one",   "two",   "three", "four", "five",   "six",
        "seven", "eight", "nine",  "ten",  "eleven", "twelve",
    };

    const char *angle_english[] = {
        "",     "five",        "ten",    "quarter", "twenty", "twenty five",
        "half", "twenty five", "twenty", "querter", "ten",    "five",
    };

    char s[100] = {0};
    if (ts.tm_min < 5) {
      blitstr(d, 2, 1, num_english[(ts.tm_hour - 1 + 12) % 12], true, false);
      blitstr(d, 2, 8, "o'clock", true, false);
    } else if (ts.tm_min < 35) {
      blitstr(d, 2, 1, angle_english[ts.tm_min / 5], true, false);
      sprintf(s, "%s %s", "past", num_english[(ts.tm_hour - 1 + 12) % 12]);
      blitstr(d, 2, 8, s, true, false);
    } else {
      blitstr(d, 2, 1, angle_english[ts.tm_min / 5], true, false);
      sprintf(s, "%s %s", "to", num_english[ts.tm_hour % 12]);
      blitstr(d, 2, 8, s, true, false);
    }

    put_display(d);

    vTaskDelay(1000 / portTICK_PERIOD_MS);
  }
}

#define MAX(x, y) (((x) > (y)) ? (x) : (y))
#define MIN(x, y) (((x) < (y)) ? (x) : (y))

int mapl(int hi, int lo, int v) {
  // return 14 - (int)(((float)((v) - (lo)) / (float)((hi) - (lo))) * 7.0) - 1;
  float zto1 = (float)(v - lo) / (float)(hi - lo);
  int to_hi = 5;
  int to_lo = 13;

  return (int)(zto1 * (float)(to_hi - to_lo)) + to_lo;
}

uint32_t uart_scan_int32(void) {
  char uartin[100] = {0};
  char *c = uartin;
  for (;;) {
    if (uart_read_bytes(UART_NUM_0, c, 1, portMAX_DELAY) != 1)
      continue;

    if (*c < '0' || *c > '9')
      break;

    c++;
  }

  *c = 0;

  return atol(uartin);
}

void uart_scan_word(char *out) {
  char *c = out;
  for (;;) {
    if (uart_read_bytes(UART_NUM_0, c, 1, portMAX_DELAY) != 1)
      continue;

    if (*c <= ' ')
      break;

    c++;
  };

  *c = 0;
}

void stonks(void) {
  display d;

  const uint32_t hlen = 28 * 2;

  struct ent {
    uint32_t open;
    uint32_t hi;
    uint32_t lo;
  };

  struct ent hist[28 * 2] = {0};

  bool first = true;

  // int hist[28 * 2] = {0};

  char sym[10];
  uart_scan_word(sym);

  uint32_t dec = uart_scan_int32();

  uint32_t decp = pow(10, dec);

  uint32_t cur;
  time_t at;

  for (;;) {
    cur = uart_scan_int32();

    if (first) {
      time(&at);
      first = false;
      hist[28 * 2 - 1].open = cur;
      hist[28 * 2 - 1].hi = cur;
      hist[28 * 2 - 1].lo = cur;
      for (int i = 0; i < 28 * 2; i++)
        hist[i].lo = hist[i].hi = hist[i].open = cur;
    } else {
      if (cur > hist[28 * 2 - 1].hi) {
        hist[28 * 2 - 1].hi = cur;
      }

      if (cur < hist[28 * 2 - 1].lo) {
        hist[28 * 2 - 1].lo = cur;
      }
    }

    time_t now;
    time(&now);
    if (now - at > 60) {
      at = now;
      for (int i = 0; i < 28 * 2 - 1; i++) {
        hist[i] = hist[i + 1];
      }

      hist[28 * 2 - 1] = (struct ent){
          .lo = cur,
          .hi = cur,
          .open = cur,
      };
    }

    uint32_t lo = INT32_MAX;
    uint32_t hi = 0;

    for (int i = 0; i < hlen; i++) {
      hi = MAX(hi, hist[i].hi);
      lo = MIN(lo, hist[i].lo);
    }

    hi = MAX(hi, cur);
    lo = MIN(lo, cur);

    clear(d);
    char buf[100];
    sprintf(buf, "%s  %d.%0*d", sym, cur / decp, dec, cur % decp);

    for (int i = 0; i < hlen; i++) {
      int from;
      int to;

      if (i == hlen - 1) {
        from = mapl(hi, lo, hist[i].open);
        to = mapl(hi, lo, cur);
      } else {
        // from = mapl(hi, lo, hist[i].open);
        // to = mapl(hi, lo, hist[i + 1].open);
        from = mapl(hi, lo, hist[i].hi);
        to = mapl(hi, lo, hist[i].lo);
      }

      // printf("- %d -> %d : %d -> %d (%d,%d)\n", hist[i].open, to_v, from, to,
      // lo, hi);

      for (int v = MIN(from, to); v <= MAX(from, to); v++) {
        putdot(d, i, v, true);
      }
    }

    blitstr(d, 1, 0, buf, true, true);

    put_display(d);
  }
}

void app_main(void) {
  uart_config_t uart_config = {
      .baud_rate = 57600,
      .data_bits = UART_DATA_8_BITS,
      .parity = UART_PARITY_DISABLE,
      .stop_bits = UART_STOP_BITS_1,
      .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
      .rx_flow_ctrl_thresh = 122,
      .source_clk = UART_SCLK_APB,
  };

  esp_log_level_set(TAG, ESP_LOG_INFO);
  ESP_ERROR_CHECK(
      uart_driver_install(ECHO_UART_PORT, BUF_SIZE * 2, 0, 0, NULL, 0));
  ESP_ERROR_CHECK(uart_param_config(ECHO_UART_PORT, &uart_config));
  ESP_ERROR_CHECK(uart_set_pin(ECHO_UART_PORT, ECHO_TEST_TXD, ECHO_TEST_RXD,
                               ECHO_TEST_RTS, ECHO_TEST_CTS));
  ESP_ERROR_CHECK(uart_set_mode(ECHO_UART_PORT, UART_MODE_RS485_HALF_DUPLEX));

  ESP_ERROR_CHECK(uart_driver_install(UART_NUM_0, 1024, 1024, 0, NULL, 0));

  setenv("TZ", "PDT7", 1);
  tzset();

  struct timeval tv = {
      .tv_sec = 1620028847,
      .tv_usec = 0,
  };
  settimeofday(&tv, NULL);

  // stonks();
  word_clock();
}
