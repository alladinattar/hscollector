package main

import (
	"encoding/csv"
	"io"
	"log"
	"os"
)

func main() {
	file, err := os.Open(os.Args[1])
	if err != nil {
		panic(err)
	}
	defer file.Close()
	reader := csv.NewReader(file)
	reader.FieldsPerRecord = 15
	reader.Comment = '#'
	BSSIDs := []string{}
	for i := 0; i <= 10; i++ {

		record, err := reader.Read()
		if err != nil {
			log.Println(err)
			break
		}
		if i == 0 {
			continue
		}
		BSSIDs = append(BSSIDs, record[0] + record[3])
	}

	file, err = os.OpenFile("onlyBSSID",os.O_CREATE|os.O_RDWR, 0777)
	if err!=nil{
		log.Fatal(err)
	}
	for _, BSSID:=range BSSIDs{
		io.WriteString(file, BSSID + "\n")
	}
	file.Close()


}
