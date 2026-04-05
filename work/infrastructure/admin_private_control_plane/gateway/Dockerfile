FROM denoland/deno:2.1.7

WORKDIR /app
COPY . .

EXPOSE 7443

CMD ["run", "--allow-env", "--allow-net", "server.ts"]
