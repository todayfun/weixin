desc 'seed kanjia players'

# start: rails s -p 80 -d
# stop cmd: lsof -i:80;kill -9 xxx
task :seed_kanjia_players => :environment do
  Play.seed_kanjia_players
  Play.seed_kanjia_players_iphone
end