require 'bundler/vlad'

set :application, "noteface"
set :repository, "git@github.com:christhomson/noteface.git"
set :user, "deploy"
set :domain, "#{user}@noteface.cthomson.ca"
set :deploy_to, "/home/deploy/apps/noteface"
set :revision, "HEAD"
set :port, 9999 # We'll redirect port 80 to this port with iptables, so we don't require sudo to reboot thin

namespace :vlad do
  namespace :thin do
    remote_task :start, :roles => :app do
      puts "Starting Thin..."
      run "cd #{current_release}; thin start -e production -p #{port} -d"
    end

    remote_task :stop, :roles => :app do
      puts "Attempting to stop Thin..."
      run "cd #{current_release}; if [ -f tmp/pids/thin.pid ]; then thin stop; fi"
    end

    remote_task :restart, :roles => :app do
      Rake::Task['vlad:thin:stop'].invoke
      Rake::Task['vlad:thin:start'].invoke
    end
  end

  remote_task :symlink_config, :roles => :app do
    run "touch #{shared_path}/settings.yml; ln -s #{shared_path}/settings.yml #{release_path}/config/settings.yml"
  end

  task :deploy => [
    "vlad:update",
    "vlad:symlink_config",
    "vlad:bundle:install",
    "vlad:thin:restart",
    "vlad:cleanup"
  ]
end