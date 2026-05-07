FROM node:18-alpine

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /usr/src/app
RUN chown appuser:appgroup /usr/src/app

COPY --chown=appuser:appgroup . .
# Skip npm install to bypass network issues

# Remove .env from image if it leaked in (use k8s secrets instead)
RUN rm -f .env

# Set ownership and switch to non-root user
USER appuser

EXPOSE 5000

CMD ["node", "app.js"]
