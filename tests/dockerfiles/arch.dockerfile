FROM --platform=linux/amd64 archlinux
RUN <<-EOF
	pacman -Sy && pacman -S --noconfirm sudo
	echo "%sudo ALL=(ALL:ALL) ALL" >> /etc/sudoers
	groupadd sudo
	useradd -m -G sudo -p "$(openssl passwd -1 tester)" tester
EOF
USER tester
COPY . /setdots
WORKDIR /setdots
CMD [ "bash" ]

