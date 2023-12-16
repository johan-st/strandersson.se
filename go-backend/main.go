package main

import "fmt"

func main() {
	fmt.Println("Hello World")

	spaConfig := spaServer.Config().
		StaticDir(path: "../frontend/public", url: "/static").
		IndexFile(path: "../frontend/index.html", url:"/")

	spaServer := spaServer.newWithConfig(spaConfig)
}
