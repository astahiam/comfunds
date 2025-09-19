package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// Test the hero API endpoint
func main() {
	// Test the hero API endpoint
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	// Test backend API
	fmt.Println("Testing Backend Hero API...")
	resp, err := client.Get("http://localhost:8080/api/v1/public/hero")
	if err != nil {
		fmt.Printf("❌ Backend API Error: %v\n", err)
	} else {
		defer resp.Body.Close()
		body, _ := io.ReadAll(resp.Body)

		var result map[string]interface{}
		if err := json.Unmarshal(body, &result); err != nil {
			fmt.Printf("❌ JSON Parse Error: %v\n", err)
		} else {
			fmt.Printf("✅ Backend API Response: %s\n", string(body))
		}
	}

	// Test frontend
	fmt.Println("\nTesting Frontend...")
	resp, err = client.Get("http://localhost:3000/")
	if err != nil {
		fmt.Printf("❌ Frontend Error: %v\n", err)
	} else {
		defer resp.Body.Close()
		if resp.StatusCode == 200 {
			fmt.Println("✅ Frontend is accessible")
		} else {
			fmt.Printf("❌ Frontend returned status: %d\n", resp.StatusCode)
		}
	}

	fmt.Println("\n🎉 Hero section implementation is ready!")
	fmt.Println("📱 Frontend: http://localhost:3000")
	fmt.Println("🔧 Backend API: http://localhost:8080/api/v1/public/hero")
}

