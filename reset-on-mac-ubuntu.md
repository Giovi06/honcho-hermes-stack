# 1. Stop and remove project containers, networks, and named Docker volumes.
cd /srv/honcho-hermes-stack
docker compose -f compose.yaml -f compose.ollama.yaml down -v --remove-orphans
docker compose -f compose.obsidian.yaml down -v --remove-orphans
docker compose -f compose.syncthing.yaml down -v --remove-orphans

# 2. Remove all project bind-mounted data and deployment files.
sudo rm -rf \
  /srv/honcho-hermes-stack \
  /srv/hermes \
  /srv/obsidian \
  /srv/syncthing

# 3. Remove the restricted account and the dedicated vault group.
sudo gpasswd -d giovanni hermes-vault || true
sudo userdel -r hermes
sudo groupdel hermes-vault