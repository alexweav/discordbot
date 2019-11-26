# Build

FROM bitwalker/alpine-elixir:1.9.1 as build

# Set mix env
ENV MIX_ENV=prod

# Copy source to image
COPY . .

# Use distillery to build a release
RUN rm -rf _build && \
    mix deps.get && \
    mix distillery.release

# Extract distillery tarball
RUN APP_NAME="discordbot_umbrella" && \
    RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/releases/*/` && \
    mkdir /export && \
    tar -xf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /export

#Deploy

FROM bitwalker/alpine-elixir:1.9.1

# Copy release from previous stage
COPY --from=build /export/ .

# Install ffmpeg
RUN apk add --no-cache ffmpeg

USER default

# Launch generated application
ENTRYPOINT ["/opt/app/bin/discordbot_umbrella"]
CMD ["foreground"]
