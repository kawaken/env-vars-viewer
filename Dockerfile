FROM ubuntu:24.04 AS builder

RUN apt-get update -y && apt-get install -y curl jq tar xz-utils
RUN cd /tmp && curl -s -L -o zig-linux-x86_64.tar.xz https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz && \
    tar -xf zig-linux-x86_64.tar.xz --strip=1 && \
    mv zig /usr/local/bin/zig && mv lib /usr/local/lib/zig && \
    zig version

WORKDIR /env-vars-viewer
COPY . .
RUN zig build

FROM scratch
COPY --from=builder /env-vars-viewer/zig-out/bin/env-vars-viewer /
EXPOSE 8080
CMD [ "/env-vars-viewer" ]