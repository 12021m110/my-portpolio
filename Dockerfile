FROM nginx:alpine

# Remove default nginx page
RUN rm -rf /usr/share/nginx/html/*

# Copy portfolio files
COPY index.html /usr/share/nginx/html/
COPY profile.jpg /usr/share/nginx/html/
COPY resume/ /usr/share/nginx/html/resume/

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]