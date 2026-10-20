FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production

# Dépendances de production uniquement (cache Docker réutilisé si package*.json ne change pas)
COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src

# Utilisateur non root fourni par l'image officielle
USER node
EXPOSE 4000
CMD ["node", "src/server.js"]
