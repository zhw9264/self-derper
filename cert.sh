#!/bin/sh

CERT_HOST=$1
CERT_DIR=$2

mkdir -p "$CERT_DIR"
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
    -keyout "$CERT_DIR/$CERT_HOST.key" \
    -out "$CERT_DIR/$CERT_HOST.crt" \
    -subj "/CN=${CERT_HOST}" \
    -addext "subjectAltName=DNS:${CERT_HOST}"
