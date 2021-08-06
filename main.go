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
	"time"
)

var catAddr string = "192.168.1.72:9000"

func main() {
	l := log.New(os.Stdout, "", log.LstdFlags)

	l.Println("check hashcat files ...")
	if _, err := os.Stat("/home/kali/shakes"); !os.IsNotExist(err) {
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

			body := &bytes.Buffer{}
			writer := multipart.NewWriter(body)
			part, _ := writer.CreateFormFile("file", filepath.Base(file.Name()))
			io.Copy(part, file)
			writer.Close()

			r, _ := http.NewRequest("POST", "http://"+catAddr+"/upload", body)
			r.Header.Add("Content-Type", writer.FormDataContentType())
			client := &http.Client{Timeout: 100 * time.Second}
			resp, err := client.Do(r)
			if err != nil {
				l.Println("Failed send file:", err)
			}
			defer resp.Body.Close()
			if resp.StatusCode == 200 {
				var response struct {
					Ssid     string `json:"ssid,omitempty"`
					Password string `json:"password,omitempty"`
					Mac      string `json:"mac,omitempty"`
					Status   string `json:"status"`
				}
				asd, _ := ioutil.ReadAll(resp.Body)
				fmt.Println(string(asd))
				err := json.NewDecoder(resp.Body).Decode(&response)
				if err != nil {
					l.Println("Failed decode response:", err)
				}
				json.MarshalIndent(response, "", "  ")
			}
			log.Println(resp.StatusCode)

		}

	} else {
		l.Println("no required directory")
	}
}
