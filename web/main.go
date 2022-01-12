package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"
)

func Run(wait time.Duration, addr, apiServer string) error {
	log.Println("running app...")

	// Http server and simple route
	mux := http.NewServeMux()
	mux.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		if req.URL.Path != "/" {
			http.NotFound(w, req)
			return
		}
		fmt.Fprintf(w, "Proudly served with Go and HTTP!\n")
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

func main() {
	var (
		wait      time.Duration
		addr      string
		apiServer string
	)

	flag.StringVar(&apiServer, "api-server", "http://localhost:8090/api", "api server endpoint which connected to")
	flag.StringVar(&addr, "addr", ":8090", "HTTP network address")
	flag.DurationVar(&wait, "graceful-timeout", time.Second*15, "the duration for which the server gracefully wait for existing connections to finish - e.g. 15s or 1m")

	flag.Parse()

	err := Run(wait, addr, apiServer)
	if err != nil {
		log.Fatal("error while start app", err)
	}
}
