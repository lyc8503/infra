from io import StringIO

from pyinfra.operations import apt, files, server

apt.packages(
    name="Install shell and CLI packages",
    packages=[
        "zsh",
        "zsh-autosuggestions",
        "zsh-syntax-highlighting",
        "fzf",
        "neovim",
        "bat",
        "lsd",
        "ripgrep",
    ],
)

# oh-my-zsh
oh_my_zsh_dir = "/opt/oh-my-zsh"
files.download(
    name="Download oh-my-zsh",
    src="https://github.com/ohmyzsh/ohmyzsh/archive/refs/heads/master.tar.gz",
    dest="/tmp/oh-my-zsh.tar.gz",
)

server.shell(
    name="Extract oh-my-zsh",
    commands=[
        f"mkdir -p {oh_my_zsh_dir}",
        f"tar xzf /tmp/oh-my-zsh.tar.gz -C {oh_my_zsh_dir} --strip-components=1",
    ],
)

# starship
files.download(
    name="Download starship installer",
    src="https://starship.rs/install.sh",
    dest="/tmp/starship-install.sh",
)

server.shell(
    name="Install starship",
    commands=["sh /tmp/starship-install.sh -y"],
)

# /etc/zsh/zshrc - system-wide zsh config
files.put(
    name="Deploy zshrc",
    src=StringIO("""\
# oh-my-zsh
export ZSH="{oh_my_zsh_dir}"
ZSH_THEME="robbyrussell"
plugins=(git sudo systemd extract)

source $ZSH/oh-my-zsh.sh

# zsh-autosuggestions
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting (must be last)
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# fzf
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh

# starship
eval "$(starship init zsh)"

# aliases
alias ll='lsd -l'
alias ls='lsd'
alias cat='batcat'
alias vi='nvim'
alias vim='nvim'
""".format(oh_my_zsh_dir=oh_my_zsh_dir)),
    dest="/etc/zsh/zshrc",
)

# starship config
files.put(
    name="Deploy starship config",
    src=StringIO("""\
add_newline = false
"""),
    dest="/etc/starship.toml",
)

files.line(
    name="Set starship config path in zshenv",
    path="/etc/zsh/zshenv",
    line="export STARSHIP_CONFIG=/etc/starship.toml",
)

# set zsh as default shell for root
server.shell(
    name="Set zsh as default shell",
    commands=["chsh -s /usr/bin/zsh root"],
)
