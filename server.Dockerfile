FROM ubuntu:26.04

WORKDIR /usr/local/app

COPY ./grid-master-app/build/server/ .

RUN chmod +x ./server.x86_64

CMD ["./server.x86_64"]