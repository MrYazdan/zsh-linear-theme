DEFAULT_BACKGROUND='NONE'
R_FLAG=''
L_FLAG=''

# LEFT SEGMENT
prompt_segment() {
  # GET YOUR TERMINAL COLORS! FORGROUND AND BACKGROUND
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $DEFAULT_BACKGROUND != 'NONE' && $1 != $DEFAULT_BACKGROUND ]]; then
    echo -n " %{$bg%F{$DEFAULT_BACKGROUND}%}$R_FLAG%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  DEFAULT_BACKGROUND=$1
  [[ -n $3 ]] && echo -n $3
}

prompt_segment_right() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
    echo -n "%K{$DEFAULT_BACKGROUND}%F{$1}$L_FLAG%{$bg%}%{$fg%} "
    DEFAULT_BACKGROUND=$1
    [[ -n $3 ]] && echo -n $3
}

prompt_end() {
  if [[ -n $DEFAULT_BACKGROUND ]]; then
    echo -n " %{%k%F{$DEFAULT_BACKGROUND}%}$R_FLAG"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  DEFAULT_BACKGROUND=''
}

# FIRST SEGMENT == $USER
prompt_context() {
  if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)%m"
  fi
}

# GIT => BRANCH AND 
prompt_git() {
  local ref dirty mode repo_path
  repo_path=$(git rev-parse --git-dir 2>/dev/null)

  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green black
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:git:*' unstagedstr '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info
    echo -n "${ref/refs\/heads\// }${vcs_info_msg_0_%% }${mode}"
  fi
}

prompt_hg() {
  local rev status
  if $(hg id >/dev/null 2>&1); then
    if $(hg prompt >/dev/null 2>&1); then
      if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
        # if files not added
        prompt_segment red white
        st='±'
      elif [[ -n $(hg prompt "{status|modified}") ]]; then
        # if any modification
        prompt_segment yellow black
        st='±'
      else
        # if working is clean
        prompt_segment green black
      fi
      echo -n $(hg prompt "☿ {rev}@{branch}") $st
    else
      st=""
      rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
      branch=$(hg id -b 2>/dev/null)
      if `hg st | grep -q "^\?"`; then
        prompt_segment red black
        st='±'
      elif `hg st | grep -q "^(M|A)"`; then
        prompt_segment yellow black
        st='±'
      else
        prompt_segment green black
      fi
      echo -n "☿ $rev@$branch" $st
    fi
  fi
}

# DIRECTORY
prompt_dir() {
  prompt_segment blue black "%4(c:...:)%3c"
}

# PYTHON VENV
export VIRTUAL_ENV_DISABLE_PROMPT=1

prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path ]]; then
    prompt_segment cyan black "(`basename $virtualenv_path`)"
  fi
}

# STATE => HAVE ERROR - ROOT - BACKGROUND JOB
prompt_state() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

# TIME
prompt_time() {
  prompt_segment_right 250 black '%D{%H:%M:%S} '
}

# MAIN
build_prompt() {
  RETVAL=$?
  prompt_state
  prompt_context
  prompt_dir
  prompt_virtualenv
  prompt_git
  prompt_hg
  prompt_end
}

# RIGHT
build_rprompt() {
  prompt_vi
  prompt_time
}

prompt_vi() {
  if [[ -n $N_MODE || -n $MODE_INDICATOR ]] && [[ $SP_DISABLE_VI_INDICATOR != true ]]; then
    N_MODE="[N] "
    I_MODE="[I] "
    prompt_segment_right 246 black "`vi_mode_prompt_info`"
  fi
}

PROMPT='%{%f%b%k%}$(build_prompt) '
RPROMPT='%{%f%b%k%}$(build_rprompt)'
