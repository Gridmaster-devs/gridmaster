FROM nginx:1.29

COPY ./grid-master-app/build/ /usr/share/nginx/html
