# Use lightweight Nginx image
FROM nginx:alpine

# Copy portfolio files to Nginx
COPY . /usr/share/nginx/html/

# Copy custom Nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
