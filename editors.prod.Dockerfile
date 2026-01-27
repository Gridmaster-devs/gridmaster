FROM nginx:1.29

COPY ./grid-master-app/build/Web/ /usr/share/nginx/html
