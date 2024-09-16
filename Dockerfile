FROM golang:alpine AS builder

RUN go env -w GOPROXY=https://goproxy.cn,direct

RUN go install tailscale.com/cmd/derper@latest

# 去除域名验证（删除cmd/derper/cert.go文件的91~93行）
RUN find /go/pkg/mod/tailscale.com@*/cmd/derper/cert.go -type f -exec sed -i '91,93d' {} +

RUN derper_dir=$(find /go/pkg/mod/tailscale.com@*/cmd/derper -type d) && \
	cd $derper_dir && \
    go build -o /etc/derp/derper


FROM alpine:latest

WORKDIR /apps

# ========= CONFIG =========
ENV LANG=C.UTF-8
ENV DERP_ADDR=:50443
ENV DERP_HTTP_PORT=50080
ENV DERP_HOST=derp.tailscale.com
ENV DERP_CERTS=/apps/certs
ENV DERP_STUN=true
ENV DERP_VERIFY_CLIENTS=false
# ==========================

COPY cert.sh /apps
COPY --from=builder /etc/derp/derper .

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' > /etc/timezone

# 创建软链接 解决二进制无法执行问题 Amd架构必须执行，Arm不需要执行
RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

RUN apk add openssl

RUN sh /apps/cert.sh $DERP_HOST $DERP_CERTS

CMD /apps/derper --hostname=$DERP_HOST \
    --certmode=manual \
    --certdir=$DERP_CERTS \
    --stun=$DERP_STUN  \
    --a=$DERP_ADDR \
    --http-port=$DERP_HTTP_PORT \
    --verify-clients=$DERP_VERIFY_CLIENTS
