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

const (
	query = "SELECT ID, ADDRESS, NAME, AMOUNT, CREATED_AT, UPDATED_AT FROM ORDERS WHERE ID=?"
)

type Order struct {
	ID        int       `json:"id"`
	Address   string    `json:"address"`
	Name      string    `json:"name"`
	Amount    float32   `json:"amount"`
	CreatedAt time.Time `json:"created_at,omitempty"`
	UpdatedAt time.Time `json:"updated_at,omitempty"`
}

func Run(wait time.Duration, addr string, db *DB) error {
	log.Println("start server...")

	// Http server and simple route to api
	mux := http.NewServeMux()
	mux.HandleFunc("/api/notes", func(w http.ResponseWriter, req *http.Request) {
		if req.URL.Path != "/api/notes" {
			http.NotFound(w, req)
			return
		}

		// Prepare statement
		stmt, err := db.SQL.Prepare(query)
		if err != nil {
			http.Error(w, "404 not found", http.StatusNotFound)
			return
		}

		defer stmt.Close()

		// Do query and set value
		o := Order{}
		id := 1

		row := stmt.QueryRow(id)
		err = row.Scan(&o.ID, &o.Address, &o.Name, &o.Amount, &o.CreatedAt, &o.UpdatedAt)
		if err != nil {
			http.Error(w, "404 not found", http.StatusNotFound)
			return
		}

		j, err := json.Marshal(o)
		if err != nil {
			http.Error(w, "500 json marshal error", http.StatusInternalServerError)
			return
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

func getEnv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok {
		return v
	}
	return fallback
}

func main() {
	var (
		wait time.Duration
		addr string
	)

	flag.StringVar(&addr, "addr", ":8090", "HTTP network address")
	flag.DurationVar(&wait, "graceful-timeout", time.Second*15, "the duration for which the server gracefully wait for existing connections to finish - e.g. 15s or 1m")

	flag.Parse()

	// Database variables
	dbUser := getEnv("DB_USER", "admin")
	dbPass := getEnv("DB_PASS", "admin")
	dbHost := getEnv("DB_HOST", "127.0.0.1")
	dbPort := getEnv("DB_PORT", "3306")
	dbName := getEnv("DB_NAME", "icey_DB")

	db, err := ConnectSQL(dbHost, dbPort, dbUser, dbPass, dbName)
	if err != nil {
		log.Printf("No DB connections: %v\n", err)
		os.Exit(-1)
	}

	err = Run(wait, addr, db)
	if err != nil {
		log.Fatal("error while start app", err)
	}
}
