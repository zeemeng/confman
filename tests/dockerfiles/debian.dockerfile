FROM debian:bookworm-slim
RUN <<-EOF
  sed -i '/path-exclude \/usr\/share\/man/d' /etc/dpkg/dpkg.cfg.d/docker
	apt-get update && apt-get -y install sudo man-db vim less
	useradd -m -G sudo -p "$(openssl passwd -1 tester)" tester
EOF
USER tester
COPY . /setdots
WORKDIR /setdots
CMD [ "bash" ]

