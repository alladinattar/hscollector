package main

import (
	"github.com/gorilla/mux"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"
)

var catAddr string = "192.168.1.72"
func main(){
	l := log.New(os.Stdout, "", log.LstdFlags)

	l.Println("check hashcat files ...")
	if _, err := os.Stat("/home/kali/shakes"); !os.IsNotExist(err) {
		files, err := ioutil.ReadDir("/home/kali/shakes")
		if err != nil {
			log.Fatal(err)
		}

		r := mux.NewRouter()
		r.HandleFunc("/result", func(w http.ResponseWriter, r *http.Request){
		})
		s := http.Server{
			Addr:         ":9000",
			Handler:      r,
			IdleTimeout:  120 * time.Second,
			ReadTimeout:  1 * time.Second,
			WriteTimeout: 1 * time.Second,
		}
		go func() {
			err := s.ListenAndServe()
			if err != nil {
				l.Fatal(err)
			}
		}()

		for _, f := range files {
			l.Println(f.Name())
			file, err := os.Open(f.Name())
			if err != nil {
				l.Println("Error file open")
			}
			defer file.Close()

			_ , err = http.Post("http://" + catAddr + ":9000/upload", "multipart/form-data", file)
			if err!=nil{
				l.Println("failed send file")
			}
			l.Println(f.Name() + " uploaded")
		}
	}else{
		l.Println("no required directory")
	}
}
