package main

import (
	"bytes"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

var catAddr string = "192.168.1.72:9000"

func main() {
	l := log.New(os.Stdout, "", log.LstdFlags)

	l.Println("check hashcat files ...")
	if _, err := os.Stat("/home/kali/shakes"); !os.IsNotExist(err) {
		files, err := ioutil.ReadDir("/home/kali/shakes")
		if err != nil {
			log.Fatal(err)
		}

		r := mux.NewRouter()
		r.HandleFunc("/result", func(w http.ResponseWriter, r *http.Request) {
		})
		s := http.Server{
			Addr:         ":9000",
			Handler:      r,
			IdleTimeout:  120 * time.Second,
			ReadTimeout:  1 * time.Second,
			WriteTimeout: 1 * time.Second,
		}

		for _, f := range files {
			filePath := "/home/kali/shakes/" + f.Name()
			file, _ := os.Open(filePath)
			defer file.Close()

			body := &bytes.Buffer{}
			writer := multipart.NewWriter(body)
			part, _ := writer.CreateFormFile("file", filepath.Base(file.Name()))
			io.Copy(part, file)
			writer.Close()

			r, _ := http.NewRequest("POST", "http://" + catAddr + "/upload", body)
			r.Header.Add("Content-Type", writer.FormDataContentType())
			client := &http.Client{}
			client.Do(r)
		}
		err = s.ListenAndServe()
		if err != nil {
			l.Fatal(err)
		}
	} else {
		l.Println("no required directory")
	}
}




