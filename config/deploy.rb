require 'bundler/vlad'

set :application, "noteface"
set :repository, "git@github.com:christhomson/noteface.git"
set :user, "deploy"
set :domain, "#{user}@noteface.cthomson.ca"
set :deploy_to, "/home/deploy/apps/noteface"
set :revision, "HEAD"

# Symlink documents directory to shared/documents so it doesn't get overwritten with each deploy.
shared_paths.merge!({"documents" => "documents"})

# On the server side, the upstart scripts (config/upstart) should be installed to /etc/init.
# We also need to allow the "[start|stop|restart] [thin|resque]" commands with no password for this user.

namespace :vlad do
  namespace :thin do
    remote_task :start, :roles => :app do
      puts "Starting Thin..."
      sudo "start thin"
    end

    remote_task :stop, :roles => :app do
      puts "Attempting to stop Thin..."
      sudo "stop thin"
    end

    remote_task :restart, :roles => :app do
      puts "Restarting Thin..."
      sudo "restart thin"
    end
  end

  namespace :resque do
    remote_task :start, :roles => :app do
      puts "Starting Resque worker..."
      sudo "start resque"
    end

    remote_task :stop, :roles => :app do
      puts "Attempting to stop Resque worker..."
      sudo "stop resque"
    end

    remote_task :restart, :roles => :app do
      puts "Restarting Resque worker..."
      sudo "restart resque"
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
    "vlad:resque:restart",
    "vlad:cleanup"
  ]
end