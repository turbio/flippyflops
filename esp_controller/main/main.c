#include "cJSON.h"
#include "driver/uart.h"
#include "esp_http_client.h"
#include "esp_log.h"
#include "esp_system.h"
#include "esp_tls.h"
#include "esp_wifi.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
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

#define TAG "flippyflops"

#define ECHO_TEST_TXD (23)
#define ECHO_TEST_RXD (22)

#define ECHO_TEST_RTS (18)
#define ECHO_TEST_CTS (UART_PIN_NO_CHANGE)

#define BUF_SIZE (127)
#define ECHO_UART_PORT (2)

static uint8_t g_ssid[32] = "🐧";
static uint8_t g_pass[32] = "wewladddd";

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

void clear(display d, bool on) {
  for (int p = 0; p < 4; p++) {
    memset(d[p], on, sizeof(panel));
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

    clear(d, false);

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

    clear(d, false);

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

    clear(d, false);
    char buf[100];
    sprintf(buf, "%s  %d.%0*d", sym, cur / decp, dec, cur % decp);

    for (int i = 0; i < hlen; i++) {
      int from;
      int to;

      if (i == hlen - 1) {
        from = mapl(hi, lo, hist[i].open);
        to = mapl(hi, lo, cur);
      } else {
        from = mapl(hi, lo, hist[i].hi);
        to = mapl(hi, lo, hist[i].lo);
      }

      for (int v = MIN(from, to); v <= MAX(from, to); v++) {
        putdot(d, i, v, true);
      }
    }

    blitstr(d, 1, 0, buf, true, true);

    put_display(d);
  }
}

void init_wifi(void) {
  ESP_ERROR_CHECK(esp_netif_init());

  ESP_ERROR_CHECK(esp_event_loop_create_default());
  assert(esp_netif_create_default_wifi_sta());

  wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
  ESP_ERROR_CHECK(esp_wifi_init(&cfg));

  ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
  // ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config) );
  ESP_ERROR_CHECK(esp_wifi_start());
}

#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT BIT1
#define WIFI_MAXIMUM_RETRY 3

static EventGroupHandle_t s_wifi_event_group;

static void event_handler(void *arg, esp_event_base_t event_base,
                          int32_t event_id, void *event_data) {
  static int s_retry_num = 0;

  if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
    esp_wifi_connect();
  } else if (event_base == WIFI_EVENT &&
             event_id == WIFI_EVENT_STA_DISCONNECTED) {
    if (s_retry_num < WIFI_MAXIMUM_RETRY) {
      esp_wifi_connect();
      s_retry_num++;
    } else {
      xEventGroupSetBits(s_wifi_event_group, WIFI_FAIL_BIT);
    }
  } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
    s_retry_num = 0;
    xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
  }
}

bool wifi_connect(void) {
  s_wifi_event_group = xEventGroupCreate();

  esp_event_handler_instance_t instance_any_id;
  esp_event_handler_instance_t instance_got_ip;
  ESP_ERROR_CHECK(esp_event_handler_instance_register(
      WIFI_EVENT, ESP_EVENT_ANY_ID, &event_handler, NULL, &instance_any_id));
  ESP_ERROR_CHECK(esp_event_handler_instance_register(
      IP_EVENT, IP_EVENT_STA_GOT_IP, &event_handler, NULL, &instance_got_ip));

  wifi_config_t wifi_config = {
      .sta =
          {
              .pmf_cfg = {.capable = true, .required = false},
          },
  };

  memcpy(wifi_config.sta.ssid, g_ssid, 32);
  memcpy(wifi_config.sta.password, g_pass, 32);

  ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config));
  ESP_ERROR_CHECK(esp_wifi_connect());

  EventBits_t bits = xEventGroupWaitBits(s_wifi_event_group,
                                         WIFI_CONNECTED_BIT | WIFI_FAIL_BIT,
                                         pdFALSE, pdFALSE, portMAX_DELAY);

  ESP_ERROR_CHECK(esp_event_handler_instance_unregister(
      IP_EVENT, IP_EVENT_STA_GOT_IP, instance_got_ip));
  ESP_ERROR_CHECK(esp_event_handler_instance_unregister(
      WIFI_EVENT, ESP_EVENT_ANY_ID, instance_any_id));
  vEventGroupDelete(s_wifi_event_group);

  if (bits & WIFI_CONNECTED_BIT) {
    return true;
  } else if (bits & WIFI_FAIL_BIT) {
    return false;
  }

  return false;
}

#define CMD_BUFF 512

void errstamp(display d) {
  putdot(d, 56 - 1, 14 - 1, true);
  putdot(d, 56 - 2, 14 - 1, false);
  putdot(d, 56 - 3, 14 - 1, true);

  putdot(d, 56 - 1, 14 - 2, false);
  putdot(d, 56 - 2, 14 - 2, true);
  putdot(d, 56 - 3, 14 - 2, false);

  putdot(d, 56 - 1, 14 - 3, true);
  putdot(d, 56 - 2, 14 - 3, false);
  putdot(d, 56 - 3, 14 - 3, true);
}

void stream_http(const char *url) {
  static display d;

  esp_http_client_config_t config = {
      .url = url,
      .buffer_size = 0,
  };

  esp_http_client_handle_t client = esp_http_client_init(&config);
  esp_err_t err;

  printf("opening connection...\n");

  if ((err = esp_http_client_open(client, 0)) != ESP_OK) {
    ESP_LOGE(TAG, "Failed to open HTTP connection: %s", esp_err_to_name(err));
    return;
  }

  int content_length = esp_http_client_fetch_headers(client);
  int status = esp_http_client_get_status_code(client);

  if (status == 200) {
    char buff[CMD_BUFF];
    char *i = buff;

    clear(d, false);

    for (;;) {
      char c;
      int read_len = esp_http_client_read(client, &c, 1);

      if (read_len <= 0) {
        ESP_LOGE(TAG, "Error read data");

        errstamp(d);
        break;
      }

      if (c == '\n') {
        *i = 0;
        // printf("cmd: %s\n", buff);
        i = buff;

        cJSON *cmd = cJSON_Parse(buff);

        cJSON *t = NULL;
        if ((t = cJSON_GetObjectItemCaseSensitive(cmd, "c"))) {
          // printf("clear\n");
          clear(d, !!t->valueint);
        } else if ((t = cJSON_GetObjectItemCaseSensitive(cmd, "s"))) {
          // printf("putstr %s\n", t->valuestring);
          blitstr(d, cJSON_GetObjectItemCaseSensitive(cmd, "x")->valueint,
                  cJSON_GetObjectItemCaseSensitive(cmd, "y")->valueint,
                  t->valuestring, true, false);
        } else if ((t = cJSON_GetObjectItemCaseSensitive(cmd, "p"))) {
          // printf("putdot\n");
          putdot(d, cJSON_GetObjectItemCaseSensitive(cmd, "x")->valueint,
                 cJSON_GetObjectItemCaseSensitive(cmd, "y")->valueint,
                 !!t->valueint);
        } else if (cJSON_GetObjectItemCaseSensitive(cmd, "d")) {
          // printf("putdot\n");
          put_display(d);
        }

        cJSON_Delete(cmd);

      } else if (i - buff < CMD_BUFF - 1) {
        *i = c;
        i++;
      }
    }
  } else {
    printf("ohno status %d\n", status);
    errstamp(d);
  }

  put_display(d);

  esp_http_client_close(client);
  esp_http_client_cleanup(client);
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

  display d;
  clear(d, true);
  put_display(d);

  printf("init flash...\n");

  esp_err_t ret = nvs_flash_init();
  if (ret == ESP_ERR_NVS_NO_FREE_PAGES ||
      ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
    ESP_ERROR_CHECK(nvs_flash_erase());
    ret = nvs_flash_init();
  }
  ESP_ERROR_CHECK(ret);

  printf("init wifi...\n");
  init_wifi();

  printf("connecting to wifi...\n");

  clear(d, false);
  blitstr(d, 1, 1, "connecting...", true, false);
  put_display(d);

  if (!wifi_connect()) {
    clear(d, false);
    blitstr(d, 1, 1, "connection", true, false);
    blitstr(d, 1, 7, "error!", true, false);
    put_display(d);

    // TODO: idk, panic or something lol
    for (;;)
      vTaskDelay(1000 / portTICK_PERIOD_MS);
  }

  printf("connected!\n");

  clear(d, false);
  blitstr(d, 1, 1, "connected", true, false);
  put_display(d);

  for (;;)
    stream_http("https://dots.turb.io/stream");
}
