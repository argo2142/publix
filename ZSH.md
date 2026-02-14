# Installing ZSH:
https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH#how-to-install-zsh-on-many-platforms

# This gives a list of available shells and their locations
cat /etc/shells

INstall ZSH:
sudo apt install zsh

Change shells of non sudo user perminantly
chsh -s /user/bin/zsh
(log out and log back in)

Verify installation by running:
zsh --version
Expected result: zsh 5.0.8 or more recent.

Make it your default shell:
chsh -s $(which zsh)
Log out and log back in again to use your new default shell.

Check your default shell.
echo $SHELL
Expected result: /usr/bin/zsh or similar

Install ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
