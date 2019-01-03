# Build

FROM bitwalker/alpine-elixir:1.7.3 as build

# Set mix env
ENV MIX_ENV=prod

# Copy source to image
COPY . .

# Use distillery to build a release
RUN rm -rf _build && \
    mix deps.get && \
    mix release

# Extract distillery tarball
RUN APP_NAME="discordbot" && \
    RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/releases/*/` && \
    mkdir /export && \
    tar -xf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /export

#Deploy

FROM pentacent/alpine-erlang-base:latest

# Copy release from previous stage
COPY --from=build /export/ .

USER default

# Launch generated application
ENTRYPOINT ["/opt/app/bin/discordbot"]
CMD ["foreground"]
