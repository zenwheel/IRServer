#include <SPI.h>
#include <Ethernet.h>
#include <WebServer.h>
#include <IRremote.h>

static uint8_t mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
static uint8_t ip[] = { 192, 168, 1, 10 };
#define PREFIX "/"
WebServer webserver(PREFIX, 80);
IRsend remote;

void rootCmd(WebServer &server, WebServer::ConnectionType type, char *path, bool)
{
  server.httpSuccess();
  if (type != WebServer::HEAD)
  {
    P(msg) = "<h1>use /send?freq=x&data=y to send data, where x is the carrier frequency in kHz and y is a comma delimited list of on/off/on/off... durations in microseconds</h1>\n";
    server.printP(msg);
  }
}

void sendIR(WebServer &server, WebServer::ConnectionType type, char *param, bool)
{
  int freq = 38;
  char *data = 0;
  
  char *p = param;
  while(p && *p) {
    char *opt = p;
    p = strchr(p, '&');
    if(p)
      *(p++) = 0;
    
    char *name = opt;
    char *val = strchr(opt, '=');
    if(val)
      *(val++) = 0;
    
    if(!strcmp(name, "freq")) {
      freq = atoi(val);
    } else if(!strcmp(name, "data")) {
      data = val;
    }
  }
  
  server.httpSuccess();
  if (type != WebServer::HEAD && data) {
    int length = 0;
    char *p = data;
    while(p && *p) {
      length++;
      p = strchr(p, ',');
      if(p) p++;
    }
    
    unsigned int buf[length];
    int i = 0;
    p = data;
    while(p && *p) {
      char *val = p;
      p = strchr(p, ',');
      if(p)
        *(p++) = 0;
        
      unsigned int vi = (unsigned int)strtoul(val, 0, 0);
      buf[i++] = vi;
    }
    remote.sendRaw(buf, length, freq);
    P(resp) = "OK\n";
    server.printP(resp);
  } else {
    P(resp) = "NOT OK\n";
    server.printP(resp);
  }
}

void setup()
{
  Ethernet.begin(mac, ip);

  webserver.setDefaultCommand(&rootCmd);

  webserver.addCommand("index.html", &rootCmd);
  webserver.addCommand("send", &sendIR);

  /* start the webserver */
  webserver.begin();
}

void loop()
{
  char buff[1024];
  int len = 1024;

  webserver.processConnection(buff, &len);
}
