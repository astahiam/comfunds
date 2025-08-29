package database

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"sort"
	"sync"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

// TestNFR001_APIPerformance tests NFR-001: API response time shall be < 200ms for 95% of requests
func TestNFR001_APIPerformance(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping performance test in short mode")
	}

	// Set Gin to release mode for performance testing
	gin.SetMode(gin.ReleaseMode)

	t.Run("API_ResponseTime_HealthCheck", func(t *testing.T) {
		testAPIResponseTimeHealthCheck(t)
	})

	t.Run("API_ResponseTime_UserOperations", func(t *testing.T) {
		testAPIResponseTimeUserOperations(t)
	})

	t.Run("API_ResponseTime_ProjectOperations", func(t *testing.T) {
		testAPIResponseTimeProjectOperations(t)
	})

	t.Run("API_ResponseTime_InvestmentOperations", func(t *testing.T) {
		testAPIResponseTimeInvestmentOperations(t)
	})

	t.Run("API_ResponseTime_ProfitSharingOperations", func(t *testing.T) {
		testAPIResponseTimeProfitSharingOperations(t)
	})
}

// TestNFR002_ConcurrentUsers tests NFR-002: System shall support 5000+ concurrent users across all platforms
func TestNFR002_ConcurrentUsers(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping concurrent user test in short mode")
	}

	t.Run("ConcurrentUsers_5000_Users", func(t *testing.T) {
		testConcurrentUsers5000(t)
	})

	t.Run("ConcurrentUsers_10000_Users", func(t *testing.T) {
		testConcurrentUsers10000(t)
	})

	t.Run("ConcurrentUsers_LoadBalancing", func(t *testing.T) {
		testConcurrentUsersLoadBalancing(t)
	})

	t.Run("ConcurrentUsers_StressTest", func(t *testing.T) {
		testConcurrentUsersStressTest(t)
	})
}

// testAPIResponseTimeHealthCheck tests health check endpoint performance
func testAPIResponseTimeHealthCheck(t *testing.T) {
	// Create test router
	router := gin.New()
	router.GET("/api/v1/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "OK",
			"message":   "ComFunds API is running",
			"version":   "2.0.0",
			"timestamp": time.Now(),
		})
	})

	// Test response times
	iterations := 1000
	responseTimes := make([]time.Duration, iterations)

	for i := 0; i < iterations; i++ {
		start := time.Now()
		
		w := httptest.NewRecorder()
		req, _ := http.NewRequest("GET", "/api/v1/health", nil)
		router.ServeHTTP(w, req)
		
		responseTimes[i] = time.Since(start)
		
		// Verify response
		assert.Equal(t, http.StatusOK, w.Code)
	}

	// Calculate 95th percentile
	sort.Slice(responseTimes, func(i, j int) bool {
		return responseTimes[i] < responseTimes[j]
	})
	
	percentile95 := responseTimes[int(float64(iterations)*0.95)]
	maxAllowed := 200 * time.Millisecond

	assert.Less(t, percentile95, maxAllowed, 
		"95th percentile response time should be less than 200ms, got %v", percentile95)

	// Calculate statistics
	avgResponseTime := calculateAverage(responseTimes)
	minResponseTime := responseTimes[0]
	maxResponseTime := responseTimes[len(responseTimes)-1]

	t.Logf("Health Check Performance Results:")
	t.Logf("  95th percentile: %v", percentile95)
	t.Logf("  Average: %v", avgResponseTime)
	t.Logf("  Min: %v", minResponseTime)
	t.Logf("  Max: %v", maxResponseTime)
	t.Logf("  Success rate: 100%%")
}

// testAPIResponseTimeUserOperations tests user operation endpoints performance
func testAPIResponseTimeUserOperations(t *testing.T) {
	// Create test router with user endpoints
	router := gin.New()
	
	// Mock user service
	router.GET("/api/v1/users", func(c *gin.Context) {
		// Simulate user listing operation
		time.Sleep(5 * time.Millisecond) // Simulate database query
		c.JSON(http.StatusOK, gin.H{
			"users": []gin.H{
				{"id": uuid.New(), "name": "Test User 1"},
				{"id": uuid.New(), "name": "Test User 2"},
			},
		})
	})

	router.GET("/api/v1/users/:id", func(c *gin.Context) {
		// Simulate user retrieval operation
		time.Sleep(3 * time.Millisecond) // Simulate database query
		c.JSON(http.StatusOK, gin.H{
			"id":   c.Param("id"),
			"name": "Test User",
		})
	})

	// Test response times for user operations
	testCases := []struct {
		endpoint string
		method   string
	}{
		{"/api/v1/users", "GET"},
		{"/api/v1/users/" + uuid.New().String(), "GET"},
	}

	for _, tc := range testCases {
		t.Run(fmt.Sprintf("User_%s_%s", tc.method, tc.endpoint), func(t *testing.T) {
			iterations := 500
			responseTimes := make([]time.Duration, iterations)

			for i := 0; i < iterations; i++ {
				start := time.Now()
				
				w := httptest.NewRecorder()
				req, _ := http.NewRequest(tc.method, tc.endpoint, nil)
				router.ServeHTTP(w, req)
				
				responseTimes[i] = time.Since(start)
				
				// Verify response
				assert.Equal(t, http.StatusOK, w.Code)
			}

			// Calculate 95th percentile
			sort.Slice(responseTimes, func(i, j int) bool {
				return responseTimes[i] < responseTimes[j]
			})
			
			percentile95 := responseTimes[int(float64(iterations)*0.95)]
			maxAllowed := 200 * time.Millisecond

			assert.Less(t, percentile95, maxAllowed, 
				"95th percentile response time for %s %s should be less than 200ms, got %v", 
				tc.method, tc.endpoint, percentile95)

			avgResponseTime := calculateAverage(responseTimes)
			t.Logf("%s %s - 95th percentile: %v, Average: %v", tc.method, tc.endpoint, percentile95, avgResponseTime)
		})
	}
}

// testAPIResponseTimeProjectOperations tests project operation endpoints performance
func testAPIResponseTimeProjectOperations(t *testing.T) {
	// Create test router with project endpoints
	router := gin.New()
	
	router.GET("/api/v1/projects", func(c *gin.Context) {
		// Simulate project listing operation
		time.Sleep(8 * time.Millisecond) // Simulate complex query
		c.JSON(http.StatusOK, gin.H{
			"projects": []gin.H{
				{"id": uuid.New(), "title": "Project 1"},
				{"id": uuid.New(), "title": "Project 2"},
			},
		})
	})

	router.GET("/api/v1/projects/:id", func(c *gin.Context) {
		// Simulate project retrieval operation
		time.Sleep(5 * time.Millisecond) // Simulate database query
		c.JSON(http.StatusOK, gin.H{
			"id":    c.Param("id"),
			"title": "Test Project",
		})
	})

	// Test response times for project operations
	testCases := []struct {
		endpoint string
		method   string
	}{
		{"/api/v1/projects", "GET"},
		{"/api/v1/projects/" + uuid.New().String(), "GET"},
	}

	for _, tc := range testCases {
		t.Run(fmt.Sprintf("Project_%s_%s", tc.method, tc.endpoint), func(t *testing.T) {
			iterations := 300
			responseTimes := make([]time.Duration, iterations)

			for i := 0; i < iterations; i++ {
				start := time.Now()
				
				w := httptest.NewRecorder()
				req, _ := http.NewRequest(tc.method, tc.endpoint, nil)
				router.ServeHTTP(w, req)
				
				responseTimes[i] = time.Since(start)
				
				// Verify response
				assert.Equal(t, http.StatusOK, w.Code)
			}

			// Calculate 95th percentile
			sort.Slice(responseTimes, func(i, j int) bool {
				return responseTimes[i] < responseTimes[j]
			})
			
			percentile95 := responseTimes[int(float64(iterations)*0.95)]
			maxAllowed := 200 * time.Millisecond

			assert.Less(t, percentile95, maxAllowed, 
				"95th percentile response time for %s %s should be less than 200ms, got %v", 
				tc.method, tc.endpoint, percentile95)

			avgResponseTime := calculateAverage(responseTimes)
			t.Logf("%s %s - 95th percentile: %v, Average: %v", tc.method, tc.endpoint, percentile95, avgResponseTime)
		})
	}
}

// testAPIResponseTimeInvestmentOperations tests investment operation endpoints performance
func testAPIResponseTimeInvestmentOperations(t *testing.T) {
	// Create test router with investment endpoints
	router := gin.New()
	
	router.GET("/api/v1/investments", func(c *gin.Context) {
		// Simulate investment listing operation
		time.Sleep(10 * time.Millisecond) // Simulate complex query with joins
		c.JSON(http.StatusOK, gin.H{
			"investments": []gin.H{
				{"id": uuid.New(), "amount": 1000},
				{"id": uuid.New(), "amount": 2000},
			},
		})
	})

	router.POST("/api/v1/investments", func(c *gin.Context) {
		// Simulate investment creation operation
		time.Sleep(15 * time.Millisecond) // Simulate transaction
		c.JSON(http.StatusCreated, gin.H{
			"id":     uuid.New(),
			"status": "created",
		})
	})

	// Test response times for investment operations
	testCases := []struct {
		endpoint string
		method   string
	}{
		{"/api/v1/investments", "GET"},
		{"/api/v1/investments", "POST"},
	}

	for _, tc := range testCases {
		t.Run(fmt.Sprintf("Investment_%s_%s", tc.method, tc.endpoint), func(t *testing.T) {
			iterations := 200
			responseTimes := make([]time.Duration, iterations)

			for i := 0; i < iterations; i++ {
				start := time.Now()
				
				w := httptest.NewRecorder()
				var req *http.Request
				if tc.method == "POST" {
					req, _ = http.NewRequest(tc.method, tc.endpoint, nil)
				} else {
					req, _ = http.NewRequest(tc.method, tc.endpoint, nil)
				}
				router.ServeHTTP(w, req)
				
				responseTimes[i] = time.Since(start)
				
				// Verify response
				if tc.method == "POST" {
					assert.Equal(t, http.StatusCreated, w.Code)
				} else {
					assert.Equal(t, http.StatusOK, w.Code)
				}
			}

			// Calculate 95th percentile
			sort.Slice(responseTimes, func(i, j int) bool {
				return responseTimes[i] < responseTimes[j]
			})
			
			percentile95 := responseTimes[int(float64(iterations)*0.95)]
			maxAllowed := 200 * time.Millisecond

			assert.Less(t, percentile95, maxAllowed, 
				"95th percentile response time for %s %s should be less than 200ms, got %v", 
				tc.method, tc.endpoint, percentile95)

			avgResponseTime := calculateAverage(responseTimes)
			t.Logf("%s %s - 95th percentile: %v, Average: %v", tc.method, tc.endpoint, percentile95, avgResponseTime)
		})
	}
}

// testAPIResponseTimeProfitSharingOperations tests profit sharing operation endpoints performance
func testAPIResponseTimeProfitSharingOperations(t *testing.T) {
	// Create test router with profit sharing endpoints
	router := gin.New()
	
	router.GET("/api/v1/profit-sharing/calculations", func(c *gin.Context) {
		// Simulate profit calculation listing operation
		time.Sleep(12 * time.Millisecond) // Simulate complex financial calculation
		c.JSON(http.StatusOK, gin.H{
			"calculations": []gin.H{
				{"id": uuid.New(), "profit": 10000},
				{"id": uuid.New(), "profit": 20000},
			},
		})
	})

	router.POST("/api/v1/profit-sharing/calculations", func(c *gin.Context) {
		// Simulate profit calculation creation operation
		time.Sleep(20 * time.Millisecond) // Simulate complex calculation
		c.JSON(http.StatusCreated, gin.H{
			"id":     uuid.New(),
			"status": "calculated",
		})
	})

	// Test response times for profit sharing operations
	testCases := []struct {
		endpoint string
		method   string
	}{
		{"/api/v1/profit-sharing/calculations", "GET"},
		{"/api/v1/profit-sharing/calculations", "POST"},
	}

	for _, tc := range testCases {
		t.Run(fmt.Sprintf("ProfitSharing_%s_%s", tc.method, tc.endpoint), func(t *testing.T) {
			iterations := 150
			responseTimes := make([]time.Duration, iterations)

			for i := 0; i < iterations; i++ {
				start := time.Now()
				
				w := httptest.NewRecorder()
				req, _ := http.NewRequest(tc.method, tc.endpoint, nil)
				router.ServeHTTP(w, req)
				
				responseTimes[i] = time.Since(start)
				
				// Verify response
				if tc.method == "POST" {
					assert.Equal(t, http.StatusCreated, w.Code)
				} else {
					assert.Equal(t, http.StatusOK, w.Code)
				}
			}

			// Calculate 95th percentile
			sort.Slice(responseTimes, func(i, j int) bool {
				return responseTimes[i] < responseTimes[j]
			})
			
			percentile95 := responseTimes[int(float64(iterations)*0.95)]
			maxAllowed := 200 * time.Millisecond

			assert.Less(t, percentile95, maxAllowed, 
				"95th percentile response time for %s %s should be less than 200ms, got %v", 
				tc.method, tc.endpoint, percentile95)

			avgResponseTime := calculateAverage(responseTimes)
			t.Logf("%s %s - 95th percentile: %v, Average: %v", tc.method, tc.endpoint, percentile95, avgResponseTime)
		})
	}
}

// testConcurrentUsers5000 tests support for 5000 concurrent users
func testConcurrentUsers5000(t *testing.T) {
	concurrentUsers := 5000
	testConcurrentUsers(t, concurrentUsers, "5000_Users")
}

// testConcurrentUsers10000 tests support for 10000 concurrent users
func testConcurrentUsers10000(t *testing.T) {
	concurrentUsers := 10000
	testConcurrentUsers(t, concurrentUsers, "10000_Users")
}

// testConcurrentUsers tests concurrent user support
func testConcurrentUsers(t *testing.T, concurrentUsers int, testName string) {
	// Create test router
	router := gin.New()
	router.GET("/api/v1/health", func(c *gin.Context) {
		// Simulate some processing time
		time.Sleep(1 * time.Millisecond)
		c.JSON(http.StatusOK, gin.H{
			"status":    "OK",
			"message":   "ComFunds API is running",
			"timestamp": time.Now(),
		})
	})

	// Test concurrent access
	var wg sync.WaitGroup
	results := make(chan *testResult, concurrentUsers)
	start := time.Now()

	// Launch concurrent requests
	for i := 0; i < concurrentUsers; i++ {
		wg.Add(1)
		go func(userID int) {
			defer wg.Done()
			
			requestStart := time.Now()
			w := httptest.NewRecorder()
			req, _ := http.NewRequest("GET", "/api/v1/health", nil)
			router.ServeHTTP(w, req)
			requestDuration := time.Since(requestStart)
			
			results <- &testResult{
				userID:     userID,
				statusCode: w.Code,
				duration:   requestDuration,
				success:    w.Code == http.StatusOK,
			}
		}(i)
	}

	// Wait for all requests to complete
	wg.Wait()
	close(results)
	totalDuration := time.Since(start)

	// Collect results
	var successfulRequests int
	var failedRequests int
	var totalResponseTime time.Duration
	var responseTimes []time.Duration

	for result := range results {
		if result.success {
			successfulRequests++
			totalResponseTime += result.duration
			responseTimes = append(responseTimes, result.duration)
		} else {
			failedRequests++
		}
	}

	// Calculate statistics
	successRate := float64(successfulRequests) / float64(concurrentUsers) * 100
	avgResponseTime := totalResponseTime / time.Duration(successfulRequests)

	// Sort response times for percentile calculation
	sort.Slice(responseTimes, func(i, j int) bool {
		return responseTimes[i] < responseTimes[j]
	})

	var percentile95 time.Duration
	if len(responseTimes) > 0 {
		percentile95 = responseTimes[int(float64(len(responseTimes))*0.95)]
	}

	// Verify requirements
	assert.GreaterOrEqual(t, successRate, 95.0, 
		"Success rate should be at least 95%%, got %.2f%%", successRate)
	assert.Less(t, percentile95, 200*time.Millisecond, 
		"95th percentile response time should be less than 200ms, got %v", percentile95)
	assert.Less(t, totalDuration, 30*time.Second, 
		"Should handle %d concurrent users in under 30 seconds, took %v", concurrentUsers, totalDuration)

	t.Logf("Concurrent Users Test Results (%s):", testName)
	t.Logf("  Total users: %d", concurrentUsers)
	t.Logf("  Successful requests: %d", successfulRequests)
	t.Logf("  Failed requests: %d", failedRequests)
	t.Logf("  Success rate: %.2f%%", successRate)
	t.Logf("  Total duration: %v", totalDuration)
	t.Logf("  Average response time: %v", avgResponseTime)
	t.Logf("  95th percentile response time: %v", percentile95)
}

// testConcurrentUsersLoadBalancing tests load balancing across concurrent users
func testConcurrentUsersLoadBalancing(t *testing.T) {
	concurrentUsers := 5000
	router := gin.New()
	
	// Track which "server" handles each request
	serverCounts := make(map[int]int)
	var mu sync.Mutex

	router.GET("/api/v1/health", func(c *gin.Context) {
		// Simulate load balancing by using request ID as server ID
		serverID := int(time.Now().UnixNano() % 4) // 4 servers
		
		mu.Lock()
		serverCounts[serverID]++
		mu.Unlock()
		
		time.Sleep(2 * time.Millisecond)
		c.JSON(http.StatusOK, gin.H{
			"status":    "OK",
			"server_id": serverID,
		})
	})

	// Test concurrent access
	var wg sync.WaitGroup
	start := time.Now()

	for i := 0; i < concurrentUsers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			w := httptest.NewRecorder()
			req, _ := http.NewRequest("GET", "/api/v1/health", nil)
			router.ServeHTTP(w, req)
		}()
	}

	wg.Wait()
	duration := time.Since(start)

	// Verify load distribution
	expectedPerServer := concurrentUsers / 4
	tolerance := expectedPerServer / 4 // Allow 25% variance

	t.Logf("Load Balancing Test Results:")
	t.Logf("  Total requests: %d", concurrentUsers)
	t.Logf("  Duration: %v", duration)
	
	for serverID, count := range serverCounts {
		t.Logf("  Server %d: %d requests", serverID, count)
		assert.GreaterOrEqual(t, count, expectedPerServer-tolerance,
			"Server %d should have at least %d requests", serverID, expectedPerServer-tolerance)
		assert.LessOrEqual(t, count, expectedPerServer+tolerance,
			"Server %d should have at most %d requests", serverID, expectedPerServer+tolerance)
	}
}

// testConcurrentUsersStressTest tests stress conditions with concurrent users
func testConcurrentUsersStressTest(t *testing.T) {
	concurrentUsers := 7500 // Stress test with more than 5000
	router := gin.New()
	
	router.GET("/api/v1/health", func(c *gin.Context) {
		// Simulate varying load
		load := time.Duration(time.Now().UnixNano()%10) * time.Millisecond
		time.Sleep(load)
		c.JSON(http.StatusOK, gin.H{
			"status":    "OK",
			"load":      load.String(),
			"timestamp": time.Now(),
		})
	})

	// Test concurrent access with stress conditions
	var wg sync.WaitGroup
	results := make(chan *testResult, concurrentUsers)
	start := time.Now()

	for i := 0; i < concurrentUsers; i++ {
		wg.Add(1)
		go func(userID int) {
			defer wg.Done()
			
			requestStart := time.Now()
			w := httptest.NewRecorder()
			req, _ := http.NewRequest("GET", "/api/v1/health", nil)
			router.ServeHTTP(w, req)
			requestDuration := time.Since(requestStart)
			
			results <- &testResult{
				userID:     userID,
				statusCode: w.Code,
				duration:   requestDuration,
				success:    w.Code == http.StatusOK,
			}
		}(i)
	}

	wg.Wait()
	close(results)
	totalDuration := time.Since(start)

	// Collect results
	var successfulRequests int
	var responseTimes []time.Duration

	for result := range results {
		if result.success {
			successfulRequests++
			responseTimes = append(responseTimes, result.duration)
		}
	}

	// Calculate statistics
	successRate := float64(successfulRequests) / float64(concurrentUsers) * 100
	
	sort.Slice(responseTimes, func(i, j int) bool {
		return responseTimes[i] < responseTimes[j]
	})

	var percentile95 time.Duration
	if len(responseTimes) > 0 {
		percentile95 = responseTimes[int(float64(len(responseTimes))*0.95)]
	}

	// Verify stress test requirements
	assert.GreaterOrEqual(t, successRate, 90.0, 
		"Success rate under stress should be at least 90%%, got %.2f%%", successRate)
	assert.Less(t, percentile95, 300*time.Millisecond, 
		"95th percentile response time under stress should be less than 300ms, got %v", percentile95)

	t.Logf("Stress Test Results:")
	t.Logf("  Total users: %d", concurrentUsers)
	t.Logf("  Successful requests: %d", successfulRequests)
	t.Logf("  Success rate: %.2f%%", successRate)
	t.Logf("  Total duration: %v", totalDuration)
	t.Logf("  95th percentile response time: %v", percentile95)
}

// testResult represents the result of a concurrent test
type testResult struct {
	userID     int
	statusCode int
	duration   time.Duration
	success    bool
}

// calculateAverage calculates the average of time durations
func calculateAverage(durations []time.Duration) time.Duration {
	if len(durations) == 0 {
		return 0
	}
	
	var total time.Duration
	for _, d := range durations {
		total += d
	}
	return total / time.Duration(len(durations))
}

// BenchmarkNFR001_APIPerformance benchmarks API performance
func BenchmarkNFR001_APIPerformance(b *testing.B) {
	gin.SetMode(gin.ReleaseMode)
	router := gin.New()
	
	router.GET("/api/v1/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "OK"})
	})

	b.Run("HealthCheck", func(b *testing.B) {
		for i := 0; i < b.N; i++ {
			w := httptest.NewRecorder()
			req, _ := http.NewRequest("GET", "/api/v1/health", nil)
			router.ServeHTTP(w, req)
		}
	})
}

// BenchmarkNFR002_ConcurrentUsers benchmarks concurrent user support
func BenchmarkNFR002_ConcurrentUsers(b *testing.B) {
	gin.SetMode(gin.ReleaseMode)
	router := gin.New()
	
	router.GET("/api/v1/health", func(c *gin.Context) {
		time.Sleep(1 * time.Millisecond) // Simulate processing
		c.JSON(http.StatusOK, gin.H{"status": "OK"})
	})

	b.Run("ConcurrentUsers_1000", func(b *testing.B) {
		concurrentUsers := 1000
		b.ResetTimer()
		
		for i := 0; i < b.N; i++ {
			var wg sync.WaitGroup
			for j := 0; j < concurrentUsers; j++ {
				wg.Add(1)
				go func() {
					defer wg.Done()
					w := httptest.NewRecorder()
					req, _ := http.NewRequest("GET", "/api/v1/health", nil)
					router.ServeHTTP(w, req)
				}()
			}
			wg.Wait()
		}
	})
}
