package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

var catAddr string = "192.168.1.72:9000"

func main() {
	l := log.New(os.Stdout, "", log.LstdFlags)

	l.Println("check hashcat files ...")

	if _, err := os.Stat("/home/kali/shakes"); !os.IsNotExist(err) {
		files, _ := ioutil.ReadDir("/home/kali/shakes")
		l.Println("Found", strconv.Itoa(len(files)), "files")

		files, err := ioutil.ReadDir("/home/kali/shakes")
		if err != nil {
			log.Println("Failed read dir with shakes: ", err)
		}

		for _, f := range files {
			if f.Name() == ".counter" {
				continue
			}
			filePath := "/home/kali/shakes/" + f.Name()
			file, _ := os.Open(filePath)
			defer file.Close()
			defer os.Remove(filePath)
			body := &bytes.Buffer{}
			writer := multipart.NewWriter(body)
			part, _ := writer.CreateFormFile("file", filepath.Base(file.Name()))
			io.Copy(part, file)
			writer.Close()

			var location struct {
				Lat int `json:"lat"`
				Lon int `json:"lon"`
			}
			locationResp, err := http.Get("http://ip-api.com/json/")
			if err != nil {
				log.Println("Failed get location", err)
				return
			}
			locationBody, err := io.ReadAll(locationResp.Body)
			if err != nil {
				log.Fatal("Failed read location body", err)
			}
			err = json.Unmarshal(locationBody, &location)
			r, _ := http.NewRequest("POST", "http://"+catAddr+"/upload", body)
			r.Header.Add("Content-Type", writer.FormDataContentType())
			r.Header.Add("Latitude", strconv.Itoa(location.Lat))
			r.Header.Add("Longitude", strconv.Itoa(location.Lon))

			client := &http.Client{Timeout: 100 * time.Second}
			resp, err := client.Do(r)
			if err != nil {
				l.Println("Failed send file:", err)
			}
			defer resp.Body.Close()
			if resp.StatusCode == 200 {
				result, _ := io.ReadAll(resp.Body)
				fmt.Println(string(result))
			}

		}
	} else {
		l.Println("no required directory")
	}
}
