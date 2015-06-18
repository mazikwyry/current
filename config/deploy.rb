# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'CurrentApp'
set :repo_url, 'git@github.com:mazikwyry/current.git'
set :deploy_via, :remote_cache
set :branch, 'production'

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :rails_env, 'production'                  # If the environment differs from the stage name

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/uploads')
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

set :puma_threads,    [4, 16]
set :puma_workers,    2

set :user, "webmaster"


namespace :deploy do

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
