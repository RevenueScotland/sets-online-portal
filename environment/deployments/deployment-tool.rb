#!/usr/bin/env ruby
# frozen_string_literal: true

# This file takes a test-environments file, the name of an environment to
# deploy and the version number to deploy, and it deploys it to the current
# host.

# This scripts assumes you run this from the root of the environment folder

require 'yaml'

TEST_DELAY = 180

def pushd(folder)
  current = Dir.pwd
  Dir.chdir folder
  current
end

def popd(folder)
  Dir.chdir folder
end

def check_missing_section(env_file, section)
  return if env_file.key?(section)

  raise "Missing #{section} section in test-environments file"
end

def get_branch(env_file, version)
  env_file['branch'].each do |branch|
    return branch unless /#{branch[1]['pattern']}/.match(version).nil?
  end

  nil
end

def branch_spec(spec, release, version)
  spec.gsub('{{release}}', release).gsub('{{version}}', version)
end

def do_checkout2(type, scm, release, version)
  if scm.key?("#{type}_branch")
    git_branch_spec = branch_spec(scm["#{type}_branch"], release, version)
    system "git checkout origin/#{git_branch_spec}"
  elsif scm.key?("#{type}_tag")
    git_tag_spec = branch_spec(scm["#{type}_tag"], release, version)
    system "git checkout tags/#{git_tag_spec}"
  end
end

def do_checkout(scm, _appname, release, version)
  do_checkout2 'env', scm, release, version
  return unless File.directory?('../code/tools')

  currentdir = pushd '../code/'
  do_checkout2 'code', scm, release, version
  popd currentdir
end

def make_release_notes(appname, environment, prefix)
  return unless File.directory?('../tools')

  currentdir = pushd '../tools'
  system "./simpleReleaseNotes.sh app--#{environment} #{appname} latest "\
    "#{prefix} > releasenotes.txt"
  popd currentdir
end

def update_app_config(env, settings)
  currentdir = pushd 'environment/deployments'
  app_config = IO.read 'app-config.deployment-tool.sh'
  password_redirect = '>> scratch/${version}/${environment}/password.env\n'
  settings.each do |setting|
    setting_name = setting.split('=')[0]
    setting_value = setting.split('=')[1]
    if app_config.include? setting_name
      app_config.gsub!(/(#{setting_name})=[^ ]*/, "\\1=#{setting_value}")
    else
      app_config.gsub!('exit 0', "echo #{setting_name}=#{setting_value} "\
        "#{password_redirect}exit 0")
    end
  end
  File.write "app-config.#{env}.sh", app_config
  system "chmod +x app-config.#{env}.sh"
  popd currentdir
end

def create_environment(appname, release, version, environment, user, docker_env_vars)
  env_vars = docker_env_vars.join(' ')
  env = environment['environment']
  update_app_config env, environment['settings']
  system "export #{env_vars}; "\
    "[ ! -z \"$(sudo docker ps -qa --filter 'name=#{appname}.*'#{env})\" ] && "\
    "sudo ocker stop $(sudo docker ps -qa --filter \"name=#{appname}.*#{env}\") && "\
    "sudo docker rm -f $(sudo docker ps -qa --filter \"name=#{appname}.*#{env}\") ;"\
    "sudo #{env_vars} ../../run-mt-app-env.sh #{version} #{env} #{appname} \"#{release}\" "\
      "#{user}; "\
      "sleep #{TEST_DELAY}"
end

def write_deployment_properties(app_host, proxy_https_port, name)
  File.write 'deployment.properties', "APP_HOST=#{app_host}\n"\
    "PROXY_HTTPS_PORT=#{proxy_https_port}\n"\
    "NICENAME=#{name}\n"
end

def update_environment_page(appname, environment, version)
  env_props = Hash[File.read("scratch/#{version}/"\
    "#{environment['environment']}/env.properties")\
                       .split(/[\n]+/).map { |a| a.split('=') }]

  app_host = env_props['APP_HOST']
  proxy_https_port = env_props['PROXY_HTTPS_PORT']

  system 'register-new-environment.sh '\
    "#{appname} \"#{environment['name']}\" #{version} "\
    "#{app_host} https://#{app_host}:#{proxy_https_port}/#{appname}/ "\
    "#{environment['environment']} \"#{environment['info']}\""

  write_deployment_properties app_host, proxy_https_port, environment['name']
end

# Check command line arguments, we've got 3 or 4 of them, and that the files exist
*arguments = ARGV
unless arguments.length == 3
  raise 'This script requires 3 arguments. The first is the location of the '\
    'test-environment file, the 2nd is the name of the environment to deploy, '\
    'the 3rd the full release version number'
end
unless File.exist?(arguments[0])
  raise 'Unable to locate test-environments file: ' + arguments[0]
end

# load the production template and compose files
test_environments = YAML.load_file(arguments[0])

# check the required sections are present in the file
check_missing_section test_environments, 'version'
check_missing_section test_environments, 'application'
check_missing_section test_environments, 'appname'
check_missing_section test_environments, 'environments'
check_missing_section test_environments, 'branch'
check_missing_section test_environments, 'scm'

# check supplied environment exists
unless test_environments['environments'].key?(arguments[1])
  raise "Unable to locate environment #{arguments[1]} in test-environments "\
    "file #{arguments[0]}"
end

environment = test_environments['environments'][arguments[1]]

# check version matches at least one rule in the branches node
branch = get_branch(test_environments, arguments[2])
if branch.nil?
  raise "Unable to find pattern to match version number #{arguments[2]} in "\
    "test-environments file #{arguments[0]}"
end

scm = test_environments['scm']['branches'][branch[0]]
if scm.nil?
  raise "Missing SCM details for branch #{branch[0]} in test-environments "\
    "file #{arguments[0]}"
end

version = arguments[2]
release = version.rpartition('.')[0]

do_checkout scm, test_environments['appname'], release, version
make_release_notes test_environments['appname'], environment['environment'],
                   test_environments['scm']['prefix']

create_environment test_environments['appname'], release, version, \
                   environment, test_environments['user'], test_environments['docker']

update_environment_page test_environments['appname'], environment, version
