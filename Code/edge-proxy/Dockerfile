FROM alpine:latest

RUN apk add --no-cache iproute2 socat tini

WORKDIR /app
COPY --chmod=755 edge-proxy.sh .

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./edge-proxy.sh"]