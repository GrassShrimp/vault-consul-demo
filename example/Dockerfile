FROM node:15-alpine

WORKDIR /app

COPY ./package-lock.json /app/package-lock.json
COPY ./package.json /app/package.json

RUN npm install

COPY . /app

VOLUME [ /app ]

EXPOSE 3000

ENTRYPOINT [ "npm", "start" ]