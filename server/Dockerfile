FROM node:18-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install --production

COPY . .

# Remove .env from image if it leaked in (use k8s secrets instead)
RUN rm -f .env

EXPOSE 5000

CMD ["node", "app.js"]
