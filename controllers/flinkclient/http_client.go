/*
Copyright 2019 Google LLC.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package flinkclient

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"net/http"
	"time"

	"github.com/go-logr/logr"
)

// HTTPClient - HTTP client.
type HTTPClient struct {
	Log logr.Logger
}

// Get - HTTP GET.
func (c *HTTPClient) Get(url string, outStructPtr interface{}) error {
	return c.doHTTP("GET", url, nil, outStructPtr)
}

// Post - HTTP POST.
func (c *HTTPClient) Post(
	url string, body []byte, outStructPtr interface{}) error {
	return c.doHTTP("POST", url, body, outStructPtr)
}

func (c *HTTPClient) doHTTP(
	method string, url string, body []byte, outStructPtr interface{}) error {
	httpClient := &http.Client{Timeout: 30 * time.Second}
	req, err := c.createRequest(method, url, body)
	resp, err := httpClient.Do(req)
	if err != nil {
		return err
	}
	return c.readResponse(resp, outStructPtr)
}

func (c *HTTPClient) createRequest(
	method, url string, body []byte) (*http.Request, error) {
	req, err := http.NewRequest(method, url, bytes.NewBuffer(body))
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "flink-operator")
	return req, err
}

func (c *HTTPClient) readResponse(
	resp *http.Response, out interface{}) error {
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err == nil {
		err = json.Unmarshal(body, out)
	}
	return err
}
