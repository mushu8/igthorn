FROM localhost/elixir-1.8.2-nodejs

# Install debian packages
# RUN apt-get update && \
#     apt-get install --yes build-essential inotify-tools postgresql-client && \
#     apt-get clean

ADD . /app

# Install Phoenix packages
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix archive.install --force hex phx_new 1.5.1

# Install node
# RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && apt-get install -y nodejs
# RUN curl -vfsSL https://deb.nodesource.com/setup_14.x | bash - && apt-get install -y nodejs

WORKDIR /app

RUN mix deps.get

RUN cd apps/ui/assets && npm install && cd ../../..

EXPOSE 4000

CMD ["/app/entrypoint.sh"]