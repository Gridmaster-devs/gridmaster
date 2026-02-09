FROM nginx:1.29

COPY ./grid-master-app/build/client-web/ /usr/share/nginx/html