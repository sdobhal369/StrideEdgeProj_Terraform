# Use node version 14.x
FROM node:14-alpine

# create app directory in container
RUN mkdir -p /app

# set /app directory as default working directory
WORKDIR /app

# copy all file from current dir to /app in container
COPY . /app/

# expose port 7000
EXPOSE 7000

# npm build
RUN npm run build

# cmd to start service
CMD [ "npm", "start" ]
