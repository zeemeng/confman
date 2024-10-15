FROM --platform=linux/amd64 debian:bookworm-slim
RUN <<-EOF
  sed -i '/path-exclude \/usr\/share\/man/d' /etc/dpkg/dpkg.cfg.d/docker
	apt-get update && apt-get -y install sudo man-db vim less
	useradd -m -G sudo -p "$(openssl passwd -1 tester)" tester
EOF
USER tester
RUN <<-EOF
	sudo apt-get -y install build-essential procps curl file git
	export NONINTERACTIVE=1
	sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	sudo chown -R tester:tester /home/linuxbrew
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
EOF
COPY . /setdots
ENV SETDOTS_MGR=brew
WORKDIR /setdots
CMD [ "bash" ]

