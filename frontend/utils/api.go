package utils

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

var APIBaseURL = getEnv("API_BASE_URL", "http://localhost:8080")

type APIResponse struct {
	Status  string      `json:"status"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
	Error   interface{} `json:"error"`
}

// MakeAPIRequest makes HTTP request to backend API
func MakeAPIRequest(method, endpoint string, body interface{}, headers map[string]string) (*APIResponse, error) {
	var reqBody io.Reader

	if body != nil {
		jsonData, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		reqBody = bytes.NewBuffer(jsonData)
	}

	req, err := http.NewRequest(method, APIBaseURL+endpoint, reqBody)
	if err != nil {
		return nil, err
	}

	// Set default headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	// Set custom headers
	for key, value := range headers {
		req.Header.Set(key, value)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var apiResp APIResponse
	if err := json.Unmarshal(respBody, &apiResp); err != nil {
		return nil, err
	}

	if resp.StatusCode >= 400 {
		// Include backend error details when available
		if apiResp.Error != nil {
			return nil, fmt.Errorf("%s: %v", apiResp.Message, apiResp.Error)
		}
		return nil, fmt.Errorf("%s", apiResp.Message)
	}

	return &apiResp, nil
}

// GetAuthHeaders returns headers with authentication token
func GetAuthHeaders(token string) map[string]string {
	return map[string]string{
		"Authorization": "Bearer " + token,
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// ParseJSON parses JSON bytes into interface
func ParseJSON(data []byte, v interface{}) error {
	return json.Unmarshal(data, v)
}

// GetBackendURL returns the backend API base URL
func GetBackendURL() string {
	return APIBaseURL
}
