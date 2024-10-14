FROM golang:1.23 AS builder

WORKDIR /app

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o env-vars-viewer -ldflags="-w -s"

FROM scratch

COPY --from=builder /app/env-vars-viewer /env-vars-viewer

CMD [ "/env-vars-viewer" ]
