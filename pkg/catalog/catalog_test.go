package catalog

import (
	"fmt"
	"reflect"
	"testing"

	"github.com/rodchristiansen/gorilla/pkg/config"
	"gopkg.in/yaml.v3"
)

var expected = make(map[string]Item)

func fakeDownload(string string) ([]byte, error) {
	fmt.Println(string)

	// Generate yaml from the expected map
	yamlBytes, err := yaml.Marshal(expected)
	if err != nil {
		return nil, err
	}

	return yamlBytes, nil
}

// TestGet verifies that a valid catlog is parsed correctly and returns the expected map
func TestGet(t *testing.T) {
	// Set what we expect Get() to return
	expected[`ChefClient`] = Item{
		Dependencies: []string{`ruby`},
		DisplayName:  "Chef Client",
		Check: InstallCheck{
			File: []FileCheck{{Path: `C:\opscode\chef\bin\chef-client.bat`}, {Path: `C:\test\path\check\file.exe`, Hash: `abc1234567890def`, Version: `1.2.3.0`}},
			Script: `$latest = "14.3.37"
$current = C:\opscode\chef\bin\chef-client.bat --version
$current = $current.Split(" ")[1]
$upToDate = [System.Version]$current -ge [System.Version]$latest
If ($upToDate) {
  exit 1
} Else {
  exit 0
}
`},
		Installer: InstallerItem{
			Arguments: []string{`/L=1033`, `/S`},
			Hash:      `f5ef8c31898592824751ec2252fe317c0f667db25ac40452710c8ccf35a1b28d`,
			Location:  `packages/chef-client/chef-client-14.3.37-1-x64.msi`,
		},
		Uninstaller:  InstallerItem{Type: `msi`, Arguments: []string{`/S`}},
		Version:      `68.0.3440.106`,
		BlockingApps: []string{"test"},
	}

	// Define a Configuration struct to pass to `Get`
	cfg := config.Configuration{
		URL:       "https://example.com/",
		Manifest:  "example_manifest",
		CachePath: "testdata/",
		Catalogs:  []string{"test_catalog"},
	}

	// Override the downloadFile function with our fake function
	downloadGet = fakeDownload

	// Run `Get`
	testCatalog := Get(cfg)

	mapsMatch := reflect.DeepEqual(expected, testCatalog[1])

	if !mapsMatch {
		t.Errorf("\n\nExpected:\n\n%#v\n\nReceived:\n\n %#v", expected, testCatalog[1])
	}
}
