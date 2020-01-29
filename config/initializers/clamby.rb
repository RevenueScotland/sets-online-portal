# frozen_string_literal: true

# Set configuration options for Clamby (Ruby clamAV interface)
# Tell Clamby to use the daemon version of clamav as that's already
# running in the container. Pass the file descriptor and stream the contents
# of the file, as the clamAV daemon might running as a different user

Clamby.configure(
  check: true,
  daemonize: true,
  config_file: nil,
  error_clamscan_missing: true,
  error_clamscan_client_error: false,
  error_file_missing: true,
  error_file_virus: false,
  fdpass: true,
  stream: true,
  output_level: 'high',
  executable_path_clamscan: 'clamscan',
  executable_path_clamdscan: 'clamdscan',
  executable_path_freshclam: 'freshclam'
)
