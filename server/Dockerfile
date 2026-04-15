FROM node:18-alpine

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install --production

COPY . .

# Remove .env from image if it leaked in (use k8s secrets instead)
RUN rm -f .env

# Set ownership and switch to non-root user
RUN chown -R appuser:appgroup /usr/src/app
USER appuser

EXPOSE 5000

CMD ["node", "app.js"]
