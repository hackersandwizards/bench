# --- Modern tool replacements ---
alias ls="eza"
alias ll="eza -la"
alias la="eza -a"
alias lt="eza -la --sort=modified"
alias tree="eza --tree"
alias cat="bat --paging=never"
alias less="bat --paging=always"
alias htop="btop"
alias lg="lazygit"
alias http="xh"
alias https="xh --https"

# --- Navigation ---
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias e="exit"
alias c="clear"

# --- Tools ---
alias b="brew"
alias g="git"
alias k=kubectl
alias t=terraform
alias j=just
alias ez='vim "$ZSH_SETTINGS_DIR/init.zsh"'

# --- Pipe globals ---
# Color-preserving: CG/CL/CH/CT force --color=always on the left side of the pipe.
# Plain: G/L/H/T work universally (including brew, kubectl, etc.).
alias -g G='| grep --color=always'
alias -g CG='--color=always | grep --color=always'
alias -g L='| less'
alias -g CL='--color=always | less'
alias -g H='| head'
alias -g CH='--color=always | head'
alias -g T='| tail'
alias -g CT='--color=always | tail'
alias -g W='| wc -l'

# --- Search ---
alias fsearch="rg --no-heading . | fzf"

# --- Git ---
alias gitlog="git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gl=gitlog

# --- System ---
alias ports="lsof -iTCP -sTCP:LISTEN -P -n"
alias localip="ipconfig getifaddr en0"
alias cleanup="fd -H -I -t f '.DS_Store' / --exclude '*BACKUP*' --exclude '*timemachine*' --exclude '*TimeMachine*' --exclude '/System/Volumes/Data' -x rm {} 2>/dev/null"

# --- Upgrade all (delegates to bin/bench-update) ---
alias ua=bench-update

# --- npm ---
alias npm-check-update='npm-check --skip-unused --update --save-exact'
alias ncu=npm-check-update

# --- Task Master ---
alias tm='task-master'
alias taskmaster='task-master'

# --- Claude ---
alias cld='claude --dangerously-skip-permissions'
alias cldr='cld --resume'
alias cldc='cld --continue'
