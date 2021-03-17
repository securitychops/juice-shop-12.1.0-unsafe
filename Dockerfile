# just a weird hackjob to get juice-shop 12.1.0 to compile without breaking ... you should almost certainly not be using this!

FROM node:12 as installer

WORKDIR /tmp

RUN apt-get update \
    && apt-get install git -y

RUN git clone https://github.com/bkimminich/juice-shop

WORKDIR /tmp/juice-shop

RUN git reset --hard 09a72b9b7a766d9b690fd065fbe7b02540aab700

# needed for broken post install on 12.1.0 (maybe others?)
RUN npm install --save core-js@^2.5.0

# enable unsafe settings in config by default
RUN sed -i 's/safetyOverride: false/safetyOverride: true/' config/default.yml

# remove default postinstall settings
RUN sed -i 's/cd frontend && npm install && cd .. && npm run build//' package.json

# run normal install without postinstall in package.json
RUN npm install --production --unsafe-perm

# now manually run postinstall saying N to anonymouse analytics
RUN cd frontend && yes N | npm install && cd .. && npm run build

# everything is almost default from here on out:

FROM node:12-alpine
ARG BUILD_DATE
ARG VCS_REF
LABEL maintainer="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
    org.opencontainers.image.title="OWASP Juice Shop" \
    org.opencontainers.image.description="Probably the most modern and sophisticated insecure web application" \
    org.opencontainers.image.authors="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
    org.opencontainers.image.vendor="Open Web Application Security Project" \
    org.opencontainers.image.documentation="https://help.owasp-juice.shop" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version="12.1.0" \
    org.opencontainers.image.url="https://owasp-juice.shop" \
    org.opencontainers.image.source="https://github.com/bkimminich/juice-shop" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE
WORKDIR /juice-shop
RUN addgroup --system --gid 1001 juicer && \
    adduser juicer --system --uid 1001 --ingroup juicer

# updated path to custom one i set ... 
COPY --from=installer --chown=juicer /tmp/juice-shop .
RUN mkdir logs && \
    chown -R juicer logs && \
    chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/ && \
    chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/
USER 1001
EXPOSE 3000
CMD ["npm", "start"]
