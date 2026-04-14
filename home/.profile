
path_prepend() {
  case ":$PATH:" in
    *:"$1":*) ;;
    *) PATH="$1${PATH:+:$PATH}" ;;
  esac
}

path_append() {
  case ":$PATH:" in
    *:"$1":*) ;;
    *) PATH="${PATH:+$PATH:}$1" ;;
  esac
}

path_dedupe() {
  old_ifs=$IFS
  deduped=
  IFS=:
  set -- $PATH
  IFS=$old_ifs

  for path_entry in "$@"; do
    [ -z "$path_entry" ] && continue
    case ":$deduped:" in
      *:"$path_entry":*) ;;
      *) deduped="${deduped:+$deduped:}$path_entry" ;;
    esac
  done

  PATH=$deduped
}

export OMARCHY_PATH="$HOME/.local/share/omarchy"
export BAT_THEME=ansi

[ -r "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -r "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

path_prepend "$OMARCHY_PATH/bin"
path_prepend "$HOME/.config/composer/vendor/bin"
path_prepend "$HOME/.resend/bin"
path_append "$HOME/.radicle/bin"
path_append "$HOME/.local/share/JetBrains/Toolbox/scripts"
path_dedupe

export PATH
