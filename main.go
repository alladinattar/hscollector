package main

import (
	"bytes"
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
				l.Println("Failed send file")
			}
			defer resp.Body.Close()
			if resp.StatusCode == 200 {
				result, err := ioutil.ReadAll(resp.Body)
				if err != nil {
					log.Println(err)
				}
				fmt.Println(string(result))
			}

		}

	} else {
		l.Println("no required directory")
	}
}
