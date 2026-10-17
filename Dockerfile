# EliteCareer – static site served by Nginx
#
# Expected layout (Dockerfile at the project root):
#   Dockerfile
#   nginx.conf
#   .dockerignore
#   app/
#     index.html  styles.css  script.js
#
# Build:  docker build -t elitecareer .
# Run:    docker run -d -p 8080:8080 --name elitecareer elitecareer
# Open:   http://localhost:8080

ARG NGINX_VERSION=1.27-alpine

FROM nginxinc/nginx-unprivileged:${NGINX_VERSION}

ARG APP_VERSION=1.0.0

LABEL org.opencontainers.image.title="elitecareer" \
      org.opencontainers.image.description="EliteCareer job portal – static site on Nginx" \
      org.opencontainers.image.version="${APP_VERSION}"

USER root

# Remove the default welcome page
RUN rm -rf /usr/share/nginx/html/*

# Server config: gzip, caching, security headers, /healthz
COPY nginx.conf /etc/nginx/conf.d/default.conf

# >>> The site itself. Without this line the web root is empty and Nginx returns 403. <<<
COPY app/ /usr/share/nginx/html/

# Make sure Nginx can read everything (files 644, folders 755), whatever
# permissions the files had on your machine. Files stay owned by root, so
# the nginx user can read them but not change them.
RUN chmod -R a+rX,go-w /usr/share/nginx/html \
 && test -f /usr/share/nginx/html/index.html

# Drop back to the unprivileged nginx user (UID 101)
USER 101

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1:8080/ || exit 1

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]