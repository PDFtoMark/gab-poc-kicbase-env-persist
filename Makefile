VERSION_JSON := "{\"poc\": \"main\"}"

.PHONY: print-kic-vars
print-kic-vars:
	@echo "version_json=$(VERSION_JSON)"; echo "commit_sha=main"
