FROM debian:bookworm-slim
RUN <<-EOF
	apt-get update && apt-get -y install sudo
	useradd -m -G sudo -p "$(openssl passwd -1 tester)" tester
EOF
USER tester
COPY . /setdots
ENV SETDOTS_REPO=/setdots/tests/pkg_repo
WORKDIR /setdots
CMD [ "bash" ]

