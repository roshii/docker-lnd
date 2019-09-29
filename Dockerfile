FROM golang:alpine as builder

LABEL maintainer="roshii <roshii@riseup.net>"

# Force Go to use the cgo based DNS resolver. This is required to ensure DNS
# queries required to connect to linked containers succeed.
ENV GODEBUG netdns=cgo

RUN apk add --no-cache --update git ca-certificates make
RUN go get -d github.com/lightningnetwork/lnd
RUN cd /go/src/github.com/lightningnetwork/lnd \
	&& make && make install

# FIXME Runs into error:
# \033[0;32m Running unit tests.\033[0m
# go list -deps github.com/lightningnetwork/lnd/... | grep 'github.com/lightningnetwork/lnd'| grep -v '/vendor/' | xargs -L 1 env GO111MODULE=on go test -v -tags="dev nolog"  -test.timeout=40m
# xargs: unrecognized option: L
# RUN cd /go/src/github.com/lightningnetwork/lnd \
# 	&& make check

# Start a new, final image to reduce size.
FROM alpine as final

# Copy the binaries and entrypoint from the builder image.
COPY --from=builder /go/bin/lncli /bin/
COPY --from=builder /go/bin/lnd /bin/

# Add bash
RUN apk add --no-cache \
	bash

ENTRYPOINT ["lnd"]
