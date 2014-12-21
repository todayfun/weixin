desc 'stop rails. start cmd: rails s -p 80 -d'

# start: rails s -p 80 -d
# stop cmd: lsof -i:80;kill -9 xxx
task :stop do
    pid_file = 'tmp/pids/server.pid'
    pid = File.read(pid_file).to_i
    Process.kill 9, pid
    File.delete pid_file
end