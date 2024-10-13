package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
)

var envVars map[string]string

func init() {
	envVars = make(map[string]string)
	for _, envVar := range os.Environ() {
		parts := strings.SplitN(envVar, "=", 2)
		if len(parts) == 2 {
			envVars[parts[0]] = parts[1]
		}
	}
}

func printEnvVars(w io.Writer, format string) {
	for key, value := range envVars {
		fmt.Fprintf(w, format, key, value)
	}
}

func main() {
	// 起動したときに環境変数を出力する
	printEnvVars(os.Stdout, "%s=%s\n")

	// PORTを取得する
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// ハンドラを設定する
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// 環境変数をHTMLとして出力する
		w.Header().Set("Content-Type", "text/html")
		// HTMLのヘッダーを出力する
		io.WriteString(w,
			`<html><head>
	<title>Environment Variables</title>
	<style>
		table { width: 100%; border-collapse: collapse; border: 1px solid #ddd;}
		th, td { padding: 8px; text-align: left; border: 1px solid #ddd; }
	</style>
</head>
<body><h1>Environment Variables</h1><table>`,
		)
		// 環境変数を出力する
		printEnvVars(w, "<tr><td>%s</td><td>%s</td></tr>\n")
		// HTMLのフッターを出力する
		io.WriteString(w, "</table></body></html>\n")
	})

	// 指定されたportでサーバーを起動する
	http.ListenAndServe(":"+port, nil)

}
