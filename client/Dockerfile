FROM ruby:2.3.1-alpine

RUN apk add --no-cache \
      bash \
      build-base \
      imagemagick-dev \
      curl

RUN mkdir /opt
WORKDIR /opt

COPY Gemfile .
RUN bundle install

COPY NetboxClient.rb .

ENTRYPOINT ["/opt/NetboxClient.rb"]
