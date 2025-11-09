FROM nginx:alpine

# Copy custom nginx configuration if needed
# COPY nginx.conf /etc/nginx/nginx.conf

# Copy static website files
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]