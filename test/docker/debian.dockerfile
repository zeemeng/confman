FROM debian:bookworm-slim
RUN <<-EOF
  sed -i '/path-exclude \/usr\/share\/man/d' /etc/dpkg/dpkg.cfg.d/docker
  apt-get update && apt-get -y install vim sudo man-db make
  useradd -m -G sudo -p "$(openssl passwd -1 tester)" tester
EOF
COPY . /confman
WORKDIR /confman
RUN <<-EOF
  make install
EOF
USER tester
COPY test/.confman /home/tester/.confman
CMD [ "bash" ]

