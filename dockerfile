FROM alpine:latest

# normal image stuff

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT["./entrypoint.sh"]