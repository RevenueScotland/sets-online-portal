#!/bin/sh

# start clam-av/freshclam in background
freshclam --config-file=/etc/clamav/freshclam.conf -d &
clamd --config=/etc/clamav/clamd.conf &

echo Starting application
exec bundle exec puma -p 3000 -e ${RAILS_ENV}
