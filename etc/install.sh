#!/bin/bash -eu

# is_exists returns true if executable $1 exists in $PATH
is_exists() {
    which "$1" >/dev/null 2>&1
    return $?
}

is_mac () {
    sw_vers > /dev/null 2>&1
    return $?    
}

determine_package_manager() {
  which yum > /dev/null && {
    echo "yum"
    return;
  }
  which brew > /dev/null && {
    echo "brew"
    return;
  }
  which apt > /dev/null && {
    echo "apt-get"
    return;
  }
}

get_os_distribution() {
  if is_mac ; then
    distri_name="osx"
  elif [ -e /etc/debian_version ] || [ -e /etc/debian_release ]; then
    # Check Ubuntu or Debian
    if [ -e /etc/lsb-release ]; then
      # Ubuntu
      distri_name="ubuntu"
    else
      # Debian
      distri_name="debian"
      if grep -q Raspbian /etc/issue; then 
        distri_name="Raspbian"
      fi
    fi
  else
    # Other
    distri_name="unkown"
  fi

  echo ${distri_name}
  return;
}

install() {
  dotfiles=$HOME/dotfiles

  echo "Setting up Machine..."

  if is_exists "git"; then
    if [ -d "$dotfiles" ]; then
      #(cd "$dotfiles" && git pull --rebase)
      echo ''
    else
      git clone https://github.com/motohidentaku/dotfiles "$dotfiles"
    fi

    cd $dotfiles
    if [ $? -ne 0 ]; then
        die "not found: $dotfiles"
    fi

    OSDIST=$(get_os_distribution)
    if [ "$OSDIST" = "Raspbian" ]; then
      echo 'Copy Raspberry Pi config files'
      cp "$dotfiles"/etc/lib/raspi/vimrc "$dotfiles"/.vimrc
      cp "$dotfiles"/etc/lib/raspi/dein* "$dotfiles"/.vim/rc/
    fi

    for f in .??*
      do
        [ "$f" = ".git" ] && continue
        [ "$f" = ".cache" ] && continue
        [ "$f" = ".circleci" ] && continue
        ln -snfv "$dotfiles/$f" "$HOME"/"$f"
    done

  else
    echo "Not found git. Please"
    echo "sudo $(determine_package_manager) install git"
  fi

}

install
