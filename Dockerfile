# Build

FROM bitwalker/alpine-elixir:1.9.1 as build

# Mix build environment
ARG MIX_ENV=prod

# Whether or not to clean build files from local machine
ARG CLEAN

# Set env vars
ENV MIX_ENV=${MIX_ENV} \
    CLEAN=${CLEAN}

# Copy source to image
COPY . .

# Clean, unless arg is passed
RUN if [ "X$CLEAN" = "x" ] ; then rm -rf _build; echo deleted ; else echo not deleted ; fi

# Use distillery to build a release
RUN mix deps.get && \
    mix distillery.release

# Extract distillery tarball
RUN APP_NAME="discordbot_umbrella" && \
    RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/releases/*/` && \
    mkdir /export && \
    tar -xf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /export

# Pull in application datafiles
COPY test.wav /export

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
