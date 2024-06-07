FROM golang:alpine

WORKDIR /app

COPY . .

RUN go build -o app

CMD ["go","run","app.go"]
