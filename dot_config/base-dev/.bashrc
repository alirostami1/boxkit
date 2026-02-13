# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# -----------------------------
# Path 
# -----------------------------
export PATH="$PATH:$HOME/scripts"
export PATH="$PATH:$HOME/.local/bin/"
export PATH="$PATH:$HOME/.go/bin"
export PATH="$PATH:$HOME/.npm-global/bin"
export PATH="$PATH:$HOME/.cargo/bin"

# -----------------------------
# Env
# -----------------------------
export EDITOR=nvim
export TERM="screen-256color"
export GOBIN="$HOME/.go/bin"

# -----------------------------
# Prompt 
# -----------------------------
if [[ $- == *i* ]]; then
  PS1='\[\e[1;33m\]\u@\h\[\e[0m\] \[\e[1;34m\]\W\[\e[0m\]\$ '
fi

if ! shopt -q login_shell ; then # We're not a login shell
  # Need to redefine pathmunge, it gets undefined at the end of /etc/profile
  pathmunge () {
      case ":${PATH}:" in
          *:"$1":*)
              ;;
          *)
              if [ "$2" = "after" ] ; then
                  PATH=$PATH:$1
              else
                  PATH=$1:$PATH
              fi
      esac
  }

  # Set default umask for non-login shell only if it is set to 0
  [ `umask` -eq 0 ] && umask 022

  SHELL=/bin/bash
  # Only display echos from profile.d scripts if we are no login shell
  # and interactive - otherwise just process them to set envvars
  for i in /etc/profile.d/*.sh; do
      if [ -r "$i" ]; then
          if [ "$PS1" ]; then
              . "$i"
          else
              . "$i" >/dev/null
          fi
      fi
  done

  unset i
  unset -f pathmunge
fi


# -----------------------------
# History 
# -----------------------------
shopt -s histappend
shopt -s checkwinsize
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTCONTROL=ignoreboth:erasedups   

# -----------------------------
# Completion 
# -----------------------------
if [[ -r /usr/share/bash-completion/bash_completion ]]; then
  source /usr/share/bash-completion/bash_completion
elif [[ -r /etc/bash_completion ]]; then
  source /etc/bash_completion
fi

# -----------------------------
# Aliases
# -----------------------------
alias ts="$HOME/scripts/tmux-sessionizer"
alias n='nvim .'
alias src='source ~/.bashrc'

# -----------------------------
# De-duplicate PATH 
# -----------------------------
PATH="$(perl -e 'print join(":", grep { not $seen{$_}++ } split(/:/, $ENV{PATH}))')"
export PATH
