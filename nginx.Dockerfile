FROM nginx:1.29

COPY ./build/ /usr/share/nginx/html
