FROM wbitt/network-multitool:latest

RUN apk add --no-cache tini

WORKDIR /app
COPY --chmod=755 delay-server.sh .
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./delay-server.sh"]
