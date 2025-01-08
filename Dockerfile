FROM nginx:alpine

# Copy the website files to the nginx html directory
COPY index.html /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/

# Expose port 5173
EXPOSE 5173

# Start nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]