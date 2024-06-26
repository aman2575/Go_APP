package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprint(w, "Hello from Botgauge")
    })

    fmt.Println("Server started. Listening on port 8080...")
    http.ListenAndServe(":8080", nil)
}
