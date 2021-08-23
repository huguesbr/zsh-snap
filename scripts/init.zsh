#!/bin/zsh
.znap.init() {
  emulate -L zsh
  zmodload -Fa zsh/files b:zf_ln b:zf_mkdir b:zf_rm
  autoload -Uz add-zsh-hook

  [[ ${(t)sysexits} != *readonly ]] &&
      readonly -ga sysexits=(
          USAGE   # 64
          DATAERR
          NOINPUT
          NOUSER
          NOHOST
          UNAVAILABLE
          SOFTWARE
          OSERR
          OSFILE
          CANTCREAT
          IOERR
          TEMPFAIL
          PROTOCOL
          NOPERM
          CONFIG  # 78
      )

  export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
  export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  export XDG_DATA_HOME=${XDG_DATA_HOME:-~/.local/share}
  private basedir=$1 datadir=$XDG_DATA_HOME/zsh/site-functions
  private funcdir=$basedir/functions
  zf_mkdir -pm 0700 $datadir $gitdir \
      $XDG_CACHE_HOME/zsh{,-snap} $XDG_CONFIG_HOME/zsh $XDG_DATA_HOME
  zf_ln -fhs $funcdir/_znap $datadir/_znap

  if [[ -z $basedir ]]; then
    print -u2 "znap: Could not find Znap's repo. Aborting."
    print -u2 "znap: file name = ${(%):-%x}"
    print -u2 "znap: absolute path = ${${(%):-%x}:P}"
    print -u2 "znap: parent dir = ${${(%):-%x}:P:h}"
    return $(( sysexits[(i)NOINPUT] + 63 ))
  fi
  . $basedir/scripts/opts.zsh
  setopt $_znap_opts

  typeset -gU PATH path FPATH fpath MANPATH manpath
  path=( ~/.local/bin $path[@] )
  fpath=( $fpath[@] $datadir )
  builtin autoload -Uz $funcdir/{znap,(|.).znap.*~*.zwc}

  private gitdir
  zstyle -s :znap: repos-dir gitdir ||
      zstyle -s :znap: plugins-dir gitdir ||
          gitdir=$basedir:a:h
  if [[ -z $gitdir ]]; then
    print -u2 "znap: Could not find repos dir. Aborting."
    return $(( sysexits[(i)NOINPUT] + 63 ))
  fi
  hash -d znap=$gitdir

  zstyle -T :znap: auto-compile &&
      ..znap.auto-compile
  add-zsh-hook zsh_directory_name ..znap.dirname

  typeset -gH _comp_dumpfile=${_comp_dumpfile:-$XDG_CACHE_HOME/zsh/compdump}
  [[ -f $_comp_dumpfile && ${${:-${ZDOTDIR:-$HOME}/.zshrc}:a} -nt $_comp_dumpfile ]] &&
      zf_rm -f $_comp_dumpfile
  zstyle -s :completion: cache-path _ ||
      zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/compcache"
  zstyle -s ':completion:*' completer _ ||
      zstyle ':completion:*' completer _expand _complete _ignored
  .znap.function bindkey 'zmodload zsh/complist'
  typeset -gHa _znap_compdef=()
  compdef() {
    _znap_compdef+=( "${(j: :)${(@q+)@}}" )
  }
  compinit() {:}
  add-zsh-hook precmd ..znap.compinit-hook
  [[ -v functions[_bash_complete] ]] ||
      .znap.function _bash_complete compgen complete '
        autoload -Uz bashcompinit
        bashcompinit
        bashcompinit() {:}
      '
}

{
  .znap.init "$@"
} always {
  unfunction .znap.init
}
