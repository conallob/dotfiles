//go:build ignore

// validate-templates parses chezmoi Go template files for syntax errors using
// the same text/template engine chezmoi uses internally. It does NOT execute
// templates, so 1Password and other external calls are never made. This makes
// it safe to run in CI without any secrets.
//
// For files ending in .json.tmpl it additionally strips template directives
// from the rendered-template skeleton and validates the remaining JSON
// structure with encoding/json.
//
// Usage: go run scripts/validate-templates.go [file ...]
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"regexp"
	"strings"
	"text/template"
)

// templateBlock matches any {{ ... }} action including multi-line blocks.
var templateBlock = regexp.MustCompile(`(?s)\{\{-?.*?-?\}\}`)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: validate-templates <file> [file ...]")
		os.Exit(1)
	}

	fail := false
	for _, path := range os.Args[1:] {
		if err := validate(path); err != nil {
			fmt.Fprintf(os.Stderr, "FAIL  %s\n      %v\n", path, err)
			fail = true
		} else {
			fmt.Printf("OK    %s\n", path)
		}
	}
	if fail {
		os.Exit(1)
	}
}

func validate(path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}

	// Step 1: parse template syntax (no execution, no external calls).
	if _, err := template.New(path).Parse(string(data)); err != nil {
		return fmt.Errorf("template syntax: %w", err)
	}

	// Step 2: for JSON templates, also validate JSON structure.
	if strings.HasSuffix(path, ".json.tmpl") {
		if err := validateJSONStructure(string(data)); err != nil {
			return err
		}
	}

	return nil
}

// validateJSONStructure strips Go template actions then checks the remainder
// is valid JSON. Template actions are replaced with type-appropriate stubs so
// the surrounding JSON punctuation stays intact.
func validateJSONStructure(src string) error {
	// Replace template actions that appear as JSON values with a string stub.
	// The regex replaces:  "key": {{ expr }}  →  "key": "TEMPLATE"
	// and bare            {{ expr }}           →  "TEMPLATE"
	stripped := templateBlock.ReplaceAllStringFunc(src, func(match string) string {
		return `"TEMPLATE"`
	})

	// Remove standalone "TEMPLATE", lines that are now syntactically broken
	// (e.g. a template that expanded to nothing inside an array/object).
	// A simple approach: collapse consecutive "TEMPLATE","TEMPLATE" pairs.
	for strings.Contains(stripped, `"TEMPLATE""TEMPLATE"`) {
		stripped = strings.ReplaceAll(stripped, `"TEMPLATE""TEMPLATE"`, `"TEMPLATE"`)
	}

	if !json.Valid([]byte(stripped)) {
		// Try to give a useful error location.
		var v interface{}
		if err := json.Unmarshal([]byte(stripped), &v); err != nil {
			return fmt.Errorf("JSON structure (after template strip): %w\nstripped content:\n%s", err, stripped)
		}
	}
	return nil
}
