APP=api-demo

.PHONY: build
## build: Build the application
build:
	@echo "Building..."
	GOARCH=amd64 GOOS=linux  CGO_ENABLED=0 go build -ldflags="-w -s" -o ${APP}-linux  main.go driver.go
	GOARCH=amd64 GOOS=darwin CGO_ENABLED=0 go build -ldflags="-w -s" -o ${APP}-darwin main.go driver.go

.PHONY: run
## run: run 'go run main.go'
run:
	go run main.go

.PHONY: clean
## clean: clean the binary files
clean:
	@echo "Cleaning..."
	go clean
	rm ${APP}-linux; rm ${APP}-darwin

.PHONY: test
## test: run 'go test ./...'
test:
	go test ./...

.PHONY: test_coverage
## test_coverage: run 'go test ./... -coverprofile=coverage.out'
test_coverage:
	go test ./... -coverprofile=coverage.out

.PHONY: dep
## dep: run 'go mod download'
dep:
	go mod download

.PHONY: vet
## vet: run 'go vet'
vet:
	go vet

.PHONY: lint
## lint: run 'golangci-lint run --enable-all'
lint:
	golangci-lint run --enable-all

.PHONY: help
## help: print this help message
help:
	@echo "Usage: \n"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'
