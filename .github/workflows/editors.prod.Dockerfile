FROM nginx:1.29

COPY ./grid-master-app/build/web/ /usr/share/nginx/html
