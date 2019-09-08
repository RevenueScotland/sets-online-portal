# The following environment variables will probably need changing:

# Connection details to the RevScot Back Office
export FL_ENDPOINT_ROOT=
export FL_PASSWORD=

# Connection details to the Northgate Address Search
export ADDRESS_SEARCH_ENDPOINT=
export ADDRESS_SEARCH_UID=
export ADDRESS_SEARCH_PWD=

# Username for Companies House Search
export COMPANY_SEARCH_UID=

# Your google analytics tracking ID. typically starts with UA-
export ANALYTIC_TRACKING_ID=

# A long randomized string which is used to verify the integrity of signed cookies
export SECRET_KEY_BASE=

# The following environment variables can probably be left alone:
export APPLICATION_DOCROOT=revscot
export RAILS_ENV=production
export ENVIRONMENT=production
export FILE_UPLOAD_PATH=/var/tmp/revscot/upload/
export RAILS_LOG_LEVEL=debug
export FL_USERNAME=EXTPWSUSER
export FL_TIMEOUT=120
export COMPANY_SEARCH_ENDPOINT='https://api.companieshouse.gov.uk'
export COMPANY_SEARCH_PWD=''
export REDIS_CACHE_URL="redis://localhost:6379/1"