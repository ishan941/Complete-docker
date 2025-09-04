
# Base Image pulled from docker hub
# lightweight
# Ready to use react app environment inside container
FROM node:20-alpine

# set working directory to app
WORKDIR /app


# Copy package.json and package.lock to working directory
# It enhance caching mechanishm
# it prevent from re ruing npm install commands
# Increase Build speed 
COPY package*.json ./

# It creates node_module folder inside container
RUN npm install


# Copies all the files and folders inside the container
COPY . .


# Expose to 5173 port
EXPOSE 5173

CMD ["npm","run","dev"]



