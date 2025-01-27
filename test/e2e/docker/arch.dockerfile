FROM --platform=linux/amd64 archlinux
RUN <<-EOF
	pacman -Sy && pacman -S --noconfirm vim sudo make
	echo "%sudo ALL=(ALL:ALL) ALL" >> /etc/sudoers
	groupadd sudo
	useradd -m -G sudo -p "$(openssl passwd -1 tester)" tester
EOF
COPY . /confman
WORKDIR /confman
RUN <<-EOF
  make install
EOF
USER tester
COPY test/e2e/data/.confman /home/tester/.confman
CMD [ "bash" ]

