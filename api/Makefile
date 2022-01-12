APP=api-demo

.PHONY: build
## build: Build the application
build:
	@echo "Building..."
	GOARCH=amd64 GOOS=linux  CGO_ENABLED=0 go build -ldflags="-w -s" -o ${APP}-linux  main.go
	GOARCH=amd64 GOOS=darwin CGO_ENABLED=0 go build -ldflags="-w -s" -o ${APP}-darwin main.go

.PHONY: run
## run: run 'go run main.go'
run:
	go run main.go

build_and_run: build run

.PHONY: clean
## clean: clean the binary files
clean:
	@echo "Cleaning..."
	go clean
	rm ${APP}-linux; rm ${APP}-darwin

test:
	go test ./...

test_coverage:
	go test ./... -coverprofile=coverage.out

dep:
	go mod download

vet:
	go vet

lint:
	golangci-lint run --enable-all


.PHONY: help
## help: print this help message
help:
	@echo "Usage: \n"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'
