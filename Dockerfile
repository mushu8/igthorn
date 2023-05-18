FROM localhost/elixir-1.8.2-nodejs

ADD . /app

# Install Phoenix packages
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix archive.install --force hex phx_new 1.5.1

WORKDIR /app

RUN mix deps.get

RUN cd apps/ui/assets && npm install && cd ../../..

EXPOSE 4000

CMD ["/app/entrypoint.sh"]