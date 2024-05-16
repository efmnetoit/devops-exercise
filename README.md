Desafio Vaga Devops - Edenson Neto
===================

Descrição
-------

Você recebeu um projeto de API de listagem de editais em ruby on rails (esse
repo), sem muita documentação e precisa configurar seu deploy via Docker.

Sua solução deve:

- Criar a imagem Docker do projeto > Criada no Dockerfile, segue código abaixo:
```bash
# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.3.0
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"


# Throw-away build stage to reduce size of final image
FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libvips pkg-config

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/


# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libsqlite3-0 libvips && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./run.sh"]
```

- Disponibilizar via docker-compose:
- 3 instâncias do servidor de aplicação > Criado no docker-compose, segue código:
```
services:
  app:
    image: devops-exercise 
    environment:
      - RAILS_ENV=${RAILS_ENV}
      - BUNDLE_DEPLOYMENT=${BUNDLE_DEPLOYMENT}
      - BUNDLE_PATH=${BUNDLE_PATH}
      - BUNDLE_WITHOUT=${BUNDLE_WITHOUT}
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
    networks:
      - app-network
```

  - Proxy reverso utilizando nginx ou traefik + balanceamento de carga entre instâncias da aplicação:
  1 - Trecho do docker-compose com criação da instância nginx
 
    ```bash
      nginx:
    image: nginx:alpine
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/certs/localhost.crt:/etc/nginx/certs/localhost.crt:ro
      - ./nginx/certs/localhost.key:/etc/nginx/certs/localhost.key:ro
    depends_on:
      - app
    networks:
      - app-network
    ```

2 - Arquivo de configuração do Nginx, load balancer (round robin) + redirect http to https, para conseguir rodar a aplicação em production;
```bash
events {}

http {
    upstream rails_backend {
        server app:3000;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            return 301 https://$host$request_uri;
        }
    }

    server {
        listen 443 ssl;
        server_name localhost;

        ssl_certificate /etc/nginx/certs/localhost.crt;
        ssl_certificate_key /etc/nginx/certs/localhost.key;

        location / {
            proxy_pass http://rails_backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```





## Executando a aplicação

Clone o projeto

```bash
  git clone https://github.com/efmnetoit/devops-exercise.git
```

Acesse o diretório do projeto

```bash
  cd devops-exercise
```

Execute o script start.sh e aguarde a execução

```bash
  ./start.sh
```



## Observações

 - Por tratar-se de um projeto que necessita rodar totalmente automatizado para processo seletivo, foi criada a pasta "env" com o arquivo ".env_sample" para armazenar variáveis importantes. Lembrando que em produção (cenário real) devem ser utilizados serviços de armazenamento de senha;
- Os commits foram realizados de acordo com cada etapa da configuração, é possível verificar no projeto do Github;
- Ao acessar a aplicação no browser pela primeira vez, será exibido alerta de ambiente não seguro, pois o certificado foi criado usando Open ssl, somente para o localhost, então o navegador não reconhece a entidade certificadora e emite o aviso // Este passo foi realizado para atender o parâmetro "config.force_ssl = true" no arquivo "config\production.rb";
- Para fins didáticos, caso deseje rodar somente um container da aplicação, sem carregar todo o ambiente (3 instâncias + servidor web Nginx), execute os passos abaixo.

  1 - Acesse o diretório do projeto
  ```bash
    cd devops-exercise
  ```
  2 - Aplique o build com o comando abaixo
  ```bash
    docker build -t devops-exercise .
  ```
  3 - Execute o comando abaixo e aguarde a execução, acesse via browser em http://localhost:8080, para finalizar digite ctrl + c no terminal.
  ```bash
    docker run -e RAILS_ENV=development -it -p 8080:3000 devops-exercise
  ```
  
  End.
  



  


## Autor
Edenson Neto

[![linkedin](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/efmneto/)


