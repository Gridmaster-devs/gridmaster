FROM nginx:1.29

COPY ./grid-master-app/build/editor-web/ /usr/share/nginx/html
