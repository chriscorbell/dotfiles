#    ▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄ ▄▄▄   ▄▄▄ ▄▄▄▄▄▄▄    ▄▄▄▄▄▄▄
#    ▀▀▀▀▀████ █████▀▀▀ ███   ███ ███▀▀███▄ ███▀▀▀▀▀
#       ▄███▀   ▀████▄  █████████ ███▄▄███▀ ███
#     ▄███▀       ▀████ ███▀▀▀███ ███▀▀██▄  ███
# ██ █████████ ███████▀ ███   ███ ███  ▀███ ▀███████

# ==============================
# Zinit
# ==============================

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Initialize Starship prompt
zinit ice as"command" from"gh-r" \
          atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
          atpull"%atclone" src"init.zsh"
zinit light starship/starship

# Initialize atuin
zinit ice as"command" from"gh-r" bpick"atuin-*.tar.gz" mv"atuin*/atuin -> atuin" \
    atclone"./atuin init zsh > init.zsh; ./atuin gen-completions --shell zsh > _atuin" \
    atpull"%atclone" src"init.zsh"
zinit light atuinsh/atuin

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# ==============================
#  Zsh Config
# ==============================

# On macOS you want this enabled
if [[ -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line
bindkey "^[[3~" delete-char

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# ==============================
#  Aliases
# ==============================

# Detect OS distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    DISTRO="unknown"
fi

# Common aliases
alias ls="lsd -alh --color=always"
alias grep='grep --color=auto'
alias ld='lazydocker'
alias lg='lazygit'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push origin main'
alias gpl='git pull'

# Distribution-specific aliases
case $DISTRO in
    debian)
        alias up="sudo nala update && sudo nala full-upgrade -y"
        alias in="sudo nala install"
        alias un="sudo nala purge"
        alias cat="batcat --theme ansi -pp"
        alias fzfp="fzf --preview='batcat --theme ansi -pp {}'"
        ;;
    arch)
        alias up="yay -Syu"
        alias in="yay -S"
        alias un="yay -Rns"
        alias cat="bat --theme ansi -pp"
        alias fzfp="fzf --preview='bat --theme ansi -pp {}'"
        ;;
esac

gacp() {
  git add .
  git commit -m "$*"
  branch=$(git rev-parse --abbrev-ref HEAD)
  git push origin "$branch"
}

extract() {
  export XZ_OPT=-T4

  if [ -z "$1" ]; then
    echo "Usage: extract filename"
    echo "Extract a given file based on the extension."
    return 1
  elif [ ! -f "$1" ]; then
    echo "Error: '$1' is not a valid file for extraction"
    return 1
  fi

  case "$1" in
    *.tbz2 | *.tar.bz2) tar -xvjf "$1" ;;
    *.txz | *.tar.xz) tar -xvJf "$1" ;;
    *.tgz | *.tar.gz) tar -xvzf "$1" ;;
    *.tar | *.cbt) tar -xvf "$1" ;;
    *.tar.zst) tar -xvf "$1" ;;
    *.zip | *.cbz) unzip "$1" ;;
    *.rar | *.cbr) unrar x "$1" ;;
    *.arj) unarj x "$1" ;;
    *.ace) unace x "$1" ;;
    *.bz2) bunzip2 "$1" ;;
    *.xz) unxz "$1" ;;
    *.gz) gunzip "$1" ;;
    *.7z) 7z x "$1" ;;
    *.Z) uncompress "$1" ;;
    *.gpg) gpg -d "$1" | tar -xvzf - ;;
    *) echo "Error: failed to extract '$1'" ;;
  esac
}

pack() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: pack <format> <file/directory>"
    echo "Formats: txz, tbz, tgz, tar, bz2, gz, zip, 7z"
    return 1
  fi

  case $1 in
    txz) tar cJvf "$2.tar.xz" "$2" ;;
    tbz) tar cjvf "$2.tar.bz2" "$2" ;;
    tgz) tar czvf "$2.tar.gz" "$2" ;;
    tar) tar cpvf "$2.tar" "$2" ;;
    bz2) bzip2 "$2" ;;
    gz) gzip -c -9 -n "$2" > "$2.gz" ;;
    zip) zip -r "$2.zip" "$2" ;;
    7z) 7z a "$2.7z" "$2" ;;
    *) echo "'$1' cannot be packed()" ;;
  esac
}

# ==============================
#  Environment
# ==============================

export EDITOR="nano"
export VISUAL="nano"
export PAGER="less"
export LESS="-R"
export PATH="$HOME/bin:/usr/local/bin:$PATH"

eval "$(zoxide init zsh)"
