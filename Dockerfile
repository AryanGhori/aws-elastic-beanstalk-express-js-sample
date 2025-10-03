FROM node:16-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --omit=dev || npm install --omit=dev
COPY . .
ENV NODE_ENV=production PORT=8081
EXPOSE 8081
CMD ["npm", "start"]
