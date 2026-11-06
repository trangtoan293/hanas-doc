# Serves a pre-built site: run `npm run build` first (CI does this in the build-docs job).
# The build happens outside Docker because "last updated" dates need the git history.
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY build/ /usr/share/nginx/html/
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost/ >/dev/null || exit 1
