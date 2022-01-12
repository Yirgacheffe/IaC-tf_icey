package main

import (
	"context"
	"encoding/json"
	"flag"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"
)

type RespData struct {
	Message string `json:"message,omitempty"`
	ApiData string `json:"api_data,omitempty"`
}

func Run(wait time.Duration, addr, apiURL string) error {
	log.Println("start server...")

	// Http server and simple route
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		if req.URL.Path != "/" {
			http.NotFound(w, req)
			return
		}

		apiReq, err := http.NewRequest("GET", apiURL, nil)
		if err != nil {
			renderJson(w, 500, RespData{Message: "Api endpoint url error"})
			return
		}

		cli := &http.Client{Timeout: time.Second * 3}
		resp, err := cli.Do(apiReq)
		if err != nil {
			renderJson(w, 500, RespData{Message: "Api request error"})
			return
		}

		defer resp.Body.Close()
		data, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			renderJson(w, 500, RespData{Message: "Read api response error"})
			return
		}

		renderJson(w, 200, RespData{Message: "Awesome!", ApiData: string(data)})
	})

	srv := &http.Server{
		Addr:         addr,
		WriteTimeout: time.Second * 15,
		ReadTimeout:  time.Second * 15,
		IdleTimeout:  time.Second * 60,
		Handler:      mux,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil {
			log.Fatal(err)
		}
	}()

	c := make(chan os.Signal, 1)
	// SIGINT (Ctrl+C)
	// SIGKILL, SIGQUIT or SIGTERM (Ctrl+/) will not be caught.
	signal.Notify(c, os.Interrupt)

	// Block until receive signal
	<-c

	ctx, cancel := context.WithTimeout(context.Background(), wait)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Println(err)
	}

	log.Println("shutting down... wait a moment")
	os.Exit(0)
	return nil
}

func renderJson(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	err := json.NewEncoder(w).Encode(v)
	if err != nil {
		log.Println("Error happened while writing Content-Type header using status")
	}
}

func main() {
	var (
		wait   time.Duration
		addr   string
		apiURL string
	)

	flag.StringVar(&apiURL, "api-url", "http://localhost:8090/api/notes", "api server endpoint which connected to")
	flag.StringVar(&addr, "addr", ":8080", "HTTP network address")
	flag.DurationVar(&wait, "graceful-timeout", time.Second*15, "the duration for which the server gracefully wait for existing connections to finish - e.g. 15s or 1m")

	flag.Parse()

	err := Run(wait, addr, apiURL)
	if err != nil {
		log.Fatal("error while start app", err)
	}
}
