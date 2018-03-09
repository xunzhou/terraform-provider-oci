GOFMT_FILES?=$$(find . -name '*.go' | grep -v vendor)

default: fmt build
build: ;go build -o terraform-provider-oci
clean: ;@rm -rf terraform-provider-oci  rm -rf bin/*  rm bin
fmt: ;goimports -w -local github.com/oracle/terraform-provider-oci $(GOFMT_FILES)

### `make release version=2.0.1`
release: clean
ifdef version
	sed -i '' -e 's/Version = ".*"/Version = "$(version)"/g' provider/version.go
	gox -output ./bin/{{.OS}}_{{.Arch}}/terraform-provider-oci_v$(version)
	gox -output ./bin/solaris_amd64/terraform-provider-oci_v$(version) -osarch="solaris/amd64" 
else
	@echo Err! `make release` requires a version argument 
endif

zip: 
	@cd bin; \
	zip -r windows_386.zip windows_386; \
	zip -r windows_amd64.zip windows_amd64; \
	tar -czvf darwin_386.tar.gz darwin_386; \
	tar -czvf darwin_amd64.tar.gz darwin_amd64; \
	tar -czvf freebsd_386.tar.gz freebsd_386; \
	tar -czvf freebsd_amd64.tar.gz freebsd_amd64; \
	tar -czvf freebsd_arm.tar.gz freebsd_arm; \
	tar -czvf linux_386.tar.gz linux_386; \
	tar -czvf linux_amd64.tar.gz linux_amd64; \
	tar -czvf linux_arm.tar.gz linux_arm; \
	tar -czvf openbsd_386.tar.gz openbsd_386; \
	tar -czvf openbsd_amd64.tar.gz openbsd_amd64; \
	tar -czvf solaris_amd64.tar.gz solaris_amd64

### `make test run=TestResourceCore debug=1`
cmd := TF_ACC=1 TF_ORACLE_ENV=test go test ./provider -v -timeout 120m
ifdef run
  cmd := $(cmd) -run $(run)
endif
ifdef debug
  cmd := DEBUG=true TF_LOG=DEBUG OCI_GO_SDK_DEBUG=1 $(cmd)
endif
test: ;$(cmd)

test_print:
	@grep -ohi "Test.*$(test).*TestSuite" provider/*.go
	@grep -oh "TestAcc.*\*testing.T" provider/*.go | cut -d \( -f 1

.PHONY: build clean fmt release zip test test_print
