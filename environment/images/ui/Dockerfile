ARG TAG=develop
ARG REGISTRY=lg-bld-cont01.development.local:8443/nds-app-servers

FROM ${REGISTRY}/wibble:${TAG} AS base
MAINTAINER Richard Tearle (richard.tearle@northgateps.com)

ARG VERSION
ARG DATETIME
ARG ENVIRONMENT=production

ENV APP_PATH		/opt/revscot 
ENV ENVIRONMENT		${ENVIRONMENT}
ENV RAILS_MASTER_KEY	33465ef2923a98ec1de738ee266cc692
ENV RAILS_ENV		${ENVIRONMENT}
ENV APPLICATION_VERSION	${VERSION}
ENV BUNDLER_VERSION	2.3.15
ENV GEM_VERSION		3.3.15

ENV BUNDLE_CLEAN	true
ENV BUNDLE_FROZEN	true
ENV BUNDLE_DEPLOYMENT	true
ENV BUNDLE_WITHOUT	"development:test"

FROM base AS build

USER root

RUN <<EOT
	set -e
	mkdir -p ${APP_PATH}
	microdnf install -y dnf oracle-epel-release-el9
	dnf config-manager --enable ol9_codeready_builder
EOT

WORKDIR ${APP_PATH}

COPY scratch/Gemfile 		Gemfile
COPY scratch/Gemfile.lock	Gemfile.lock

RUN <<EOT
	set -e
	dnf module enable nodejs:20
	dnf -y install gmp-devel git yarnpkg libyaml-devel
	dnf -y group install "Development Tools"
	yarn install
	gem update --system ${GEM_VERSION}
	gem install bundler -v ${BUNDLER_VERSION}
	bundle config mirror.https://rubygems.org http://lg-bld-ruby02.development.local:9292
	bundle install
EOT

FROM base

# This assumes the ruby application is located under the scratch folder

LABEL maintainer="richard.tearle@northgateps.com"\
      org.label-schema.name="Revenue Scotland"\
      org.label-schema.description="Application Layer for Revenue Scotland"\
      org.label-schema.vendor="Northgate Public Services"\
      org.label-schema.schema-version="1.0"\
      org.label-schema.version="${VERSION}" \
      org.label-schema.build-date="${DATETIME}"

USER root

WORKDIR ${APP_PATH}

COPY --from=build ${APP_PATH}	${APP_PATH}
COPY --from=build ${GEM_HOME}	${GEM_HOME}

ADD conf/ 	/
COPY scratch/ 	${APP_PATH}
COPY scripts/ 	${APP_PATH}

RUN <<EOT
	set -e
	groupadd --system --gid 2001 rsuser
	useradd --system --uid 2001 --gid 2001 --no-create-home rsuser

	find / -user svc_user -exec chown rsuser {} \; 2>/dev/null || true
	find / -group svc_user -exec chgrp rsuser {} \; 2>/dev/null || true

	mkdir -p ${APP_PATH}/tmp/pids ${APP_PATH}/log /home/rsuser/.cache/yarn /home/rsuser/.yarn ${APP_PATH}/node_modules/ /var/tmp/share
	chown -R root:root ${APP_PATH}
	touch ${APP_PATH}/yarn-error.log
    	chown -R rsuser:rsuser ${APP_PATH}/tmp ${APP_PATH}/log ${APP_PATH}/public ${APP_PATH}/Gemfile.lock\
        	/home/rsuser/.cache/yarn /home/rsuser/.yarn ${APP_PATH}/yarn-error.log ${APP_PATH}/node_modules /var/tmp/share
    	chmod -R a-w ${APP_PATH}
    	chmod -R u+w ${APP_PATH}/tmp ${APP_PATH}/log ${APP_PATH}/Gemfile.lock ${APP_PATH}/public\
        	/home/rsuser/.cache/yarn ${APP_PATH}/node_modules ${APP_PATH}/yarn-error.log
EOT

USER rsuser
CMD ./entrypoint.sh
