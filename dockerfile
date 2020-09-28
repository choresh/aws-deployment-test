FROM node:12-alpine

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
# A wildcard is used in the 'COPY' command - to ensure both 'package.json'
# AND 'package-lock.json' are copied where available.
COPY package*.json ./
RUN npm install

# Bundle app source
COPY . .

# TypeScript (build the JS files)
COPY tsconfig.json ./
RUN npm run build

EXPOSE 8080
CMD ["node", "build/src/app.js"]