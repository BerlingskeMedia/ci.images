package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/urfave/cli"
)

var (
	version = "0.0.0"
	build   = "0"
)

func main() {
	app := cli.NewApp()
	app.Name = "ECS Void"
	app.Usage = "Creates HTTP service for ECS container healthcheck on specified URL and port"
	app.Action = run
	app.Version = fmt.Sprintf("%s+%s", version, build)
	app.Flags = []cli.Flag{
		cli.StringFlag{
			Name:   "port, p",
			Usage:  "TCP port for healthcheck service",
			Value:  "8080",
			EnvVar: "PLUGIN_PORT,ECS_PORT",
		},
		cli.StringFlag{
			Name:   "uri, u",
			Usage:  "URI for the healthcheck service",
			Value:  "healthcheck",
			EnvVar: "PLUGIN_URI,ECS_URI",
		},
	}
	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}

func run(c *cli.Context) error {
	hc := Healthcheck{
		Port: c.String("port"),
		Uri:  c.String("uri"),
	}
	return hc.Start()
}

type Healthcheck struct {
	Port string
	Uri  string
}

func (h *Healthcheck) Start() error {
	log.Printf("listening on port: %v\n", h.Port)
	log.Printf("HealthCheck URI: /%v\n", h.Uri)
	http.HandleFunc(fmt.Sprintf("/%s", h.Uri), h.HealthCheck)
	err := http.ListenAndServe(fmt.Sprintf(":%s", h.Port), logRequest(http.DefaultServeMux))
	if err != nil {
		log.Print(err)
	}
	return err
}

func (h *Healthcheck) HealthCheck(w http.ResponseWriter, r *http.Request) {

	if r.Method == http.MethodGet {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, "Container is up and running")
	} else {
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

func logRequest(handler http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s %s %s\n", r.RemoteAddr, r.Method, r.URL)
		handler.ServeHTTP(w, r)
	})
}
