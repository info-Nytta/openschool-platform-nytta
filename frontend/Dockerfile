FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json .
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /app/dist
CMD ["sh", "-c", "rm -rf /usr/share/nginx/html/* && cp -r /app/dist/* /usr/share/nginx/html/ && nginx -g 'daemon off;'"]
