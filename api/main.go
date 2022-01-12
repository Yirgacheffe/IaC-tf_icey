package main

import (
	"context"
	"encoding/json"
	"flag"
	"log"
	"net/http"
	"os"
	"os/signal"
	"time"
)

type Note struct {
	Title string `json:"title,omitempty"`
	Body  string `json:"body,omitempty"`
}

func Run(wait time.Duration, addr string) error {
	log.Println("start server...")

	// Http server and simple route to api
	mux := http.NewServeMux()
	mux.HandleFunc("/api/notes", func(w http.ResponseWriter, req *http.Request) {
		if req.URL.Path != "/api/notes" {
			http.NotFound(w, req)
			return
		}

		note := Note{
			Title: "Buy food.",
			Body:  "Buy apple, tomato, rice after covid PRN.",
		}

		j, err := json.Marshal(note)
		if err != nil {
			panic(err) // panic here as this handler is the only one
		}
		w.WriteHeader(http.StatusOK)
		w.Write(j)
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
		wait time.Duration
		addr string
	)

	flag.StringVar(&addr, "addr", ":8090", "HTTP network address")
	flag.DurationVar(&wait, "graceful-timeout", time.Second*15, "the duration for which the server gracefully wait for existing connections to finish - e.g. 15s or 1m")

	flag.Parse()

	err := Run(wait, addr)
	if err != nil {
		log.Fatal("error while start app", err)
	}
}
