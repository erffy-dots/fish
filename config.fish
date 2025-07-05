if test -d /usr/bin/Hyprland && set -q AUTOLOGIN
    set -e AUTOLOGIN

    exec Hyprland
end

# Disable the default greeting
set fish_greeting ''

# Initialize starship prompt if available
if type -q starship
    starship init fish --print-full-init | source
end

# Initialize zoxide if available
if type -q zoxide
    zoxide init fish | source

    alias zd="z"
    alias cd="z"
end

# Display system info on startup if fastfetch available
if type -q fastfetch
    fastfetch
end

# Aliases
alias c="clear"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias df="df -h"
alias free="free -h"
alias grep="grep --color=auto"
alias ip="ip -c address"

# Replace cat with bat if available
if type -q bat
    alias cat="bat --style=plain --paging=never"
end

# Add yay aliases if available
if test -d /usr/bin/yay
    alias yu="yay -Syu --noconfirm"
    alias y="yay"
end

# Replace ls with eza if available
if type -q eza
    alias ls="eza"
    alias ll="eza -la"
    alias la="eza -a"
    alias lt="eza -T"
    alias lsg="eza --git-ignore"
end

# Add a2 alias if aria2 available
if type -q aria2c
    alias a2="aria2c -x 16"
end

# Directory bookmarks
function mark
    set -U fish_mark_$argv[1] (pwd)
end

function goto
    set -q fish_mark_$argv[1]; and cd $fish_mark_$argv[1]
end

function marks
    set -l marks (set -n | grep ^fish_mark_)
    for mark in $marks
        set -l mark_name (string replace fish_mark_ '' $mark)
        set -l mark_path $$mark
        printf "%-10s -> %s\n" $mark_name $mark_path
    end
end

# Add git aliases if available
if type -q git
    alias gs="git status"
    alias ga="git add"
    alias gc="git commit -m"
    alias gp="git push"
    alias gl="git pull"
    alias gd="git diff"
    alias gco="git checkout"
    alias gb="git branch"
    alias glog="git log --oneline --graph --decorate"
end

# Environment variables

# Add pnpm home path if PNPM is installed
if type -q pnpm
    set -gx PNPM_HOME "$HOME/.local/share/pnpm"
    fish_add_path $PNPM_HOME
end

# Use vim as default editor if available
if type -q vim
    set -gx EDITOR vim
    set -gx VISUAL vim
    alias vi="vim"
end

# Use nvim as default editor if available
if type -q nvim
    set -gx EDITOR nvim
    set -gx VISUAL nvim
    alias vi="nvim"
    alias vim="nvim"
end

# Add cargo bin path if Rust is installed
if test -d $HOME/.cargo/bin
    fish_add_path $HOME/.cargo/bin
end

# Add go bin path if Go is installed
if test -d $HOME/go/bin
    fish_add_path $HOME/go/bin
end

# Add bun bin path if Bun is installed
if test -d $XDG_CACHE_HOME/.bun/bin
    fish_add_path $XDG_CACHE_HOME/.bun/bin
end

# Zig-specific settings
if type -q zig
    # Set Zig cache directory
    set -gx ZIG_CACHE_DIR "$HOME/.cache/zig"

    # Add zig aliases
    alias zb="zig build"
    alias zr="zig run"
    alias zt="zig test"
    alias zfmt="zig fmt"
end

function extract
    if not test -f $argv[1]
        echo "'$argv[1]' is not a valid file"
        return 1
    end

    set fullpath (realpath $argv[1])
    set filename (basename $fullpath)

    # Known extensions in descending specificity
    set -l known_exts tar.bz2 tar.gz tar.xz tbz2 tgz tar bz2 gz xz rar zip Z 7z

    set name $filename
    for ext in $known_exts
        if string match -q "*.$ext" $filename
            set name (string replace ".$ext" '' $filename)
            break
        end
    end

    if test -z "$name"
        echo "Could not determine base filename for '$filename'"
        return 1
    end

    set target_dir "$name"
    mkdir -p "$target_dir"

    switch $filename
        case '*.tar.bz2'
            tar xjf "$fullpath" -C "$target_dir"
        case '*.tar.gz'
            tar xzf "$fullpath" -C "$target_dir"
        case '*.tar.xz'
            tar xJf "$fullpath" -C "$target_dir"
        case '*.tbz2'
            tar xjf "$fullpath" -C "$target_dir"
        case '*.tgz'
            tar xzf "$fullpath" -C "$target_dir"
        case '*.tar'
            tar xf "$fullpath" -C "$target_dir"
        case '*.bz2'
            bunzip2 -kc "$fullpath" >"$target_dir"/(string replace '.bz2' '' $filename)
        case '*.gz'
            gunzip -kc "$fullpath" >"$target_dir"/(string replace '.gz' '' $filename)
        case '*.xz'
            xz -dkc "$fullpath" >"$target_dir"/(string replace '.xz' '' $filename)
        case '*.rar'
            unrar x -o+ "$fullpath" "$target_dir"/
        case '*.zip'
            unzip -d "$target_dir" "$fullpath"
        case '*.Z'
            uncompress -c "$fullpath" >"$target_dir"/(string replace '.Z' '' $filename)
        case '*.7z'
            7z x -o"$target_dir" "$fullpath"
        case '*'
            echo "'$filename' cannot be extracted via extract"
            return 1
    end

    echo "Extracted to: $target_dir"
end

function compress
    if test (count $argv) -lt 2
        echo "Usage: compress <source> <archive-name.ext>"
        return 1
    end

    set source $argv[1]
    set archive $argv[2]

    if not test -e $source
        echo "Source '$source' does not exist"
        return 1
    end

    set extension (string lower (string match -r '\.[^.]+$' $archive))

    switch $extension
        case '.tar.bz2'
            tar cjf $archive $source
        case '.tar.gz'
            tar czf $archive $source
        case '.tar.xz'
            tar cJf $archive $source
        case '.tbz2'
            tar cjf $archive $source
        case '.tgz'
            tar czf $archive $source
        case '.tar'
            tar cf $archive $source
        case '.bz2'
            bzip2 -k $source && mv $source.bz2 $archive
        case '.gz'
            gzip -k $source && mv $source.gz $archive
        case '.xz'
            xz -k $source && mv $source.xz $archive
        case '.rar'
            rar a $archive $source
        case '.zip'
            zip -r $archive $source
        case '.7z'
            7z a $archive $source
        case '*'
            echo "Unknown or unsupported archive extension: $extension"
            return 1
    end

    echo "Compressed to: $archive"
end

function compress-add
    if test (count $argv) -lt 2
        echo "Usage: compress-add <file/folder1> [file/folder2 ...] <archive-name.ext>"
        return 1
    end

    set archive (string trim (string sub -1 $argv)) # last arg
    set sources $argv[1..-2]

    if not test -e $archive
        echo "Archive '$archive' does not exist"
        return 1
    end

    set extension (string lower (string match -r '\.[^.]+$' $archive))

    switch $extension
        case '.tar.bz2'
            tar --append --file=$archive $sources
            bzip2 $archive && mv $archive.bz2 $archive
        case '.tar.gz'
            tar --append --file=$archive $sources
            gzip $archive && mv $archive.gz $archive
        case '.tar.xz'
            echo "Cannot append to compressed tar.xz archives"
            return 1
        case '.tbz2' '.tgz'
            echo "Cannot append to compressed .$extension archives"
            return 1
        case '.tar'
            tar --append --file=$archive $sources
        case '.rar'
            rar a $archive $sources
        case '.zip'
            zip -ur $archive $sources
        case '.7z'
            7z a $archive $sources
        case '*'
            echo "Unsupported archive type: $extension"
            return 1
    end

    echo "Added to archive: $archive"
end

# Key bindings
bind \cp up-or-search # Ctrl+P for history search up
bind \cn down-or-search # Ctrl+N for history search down
bind \cf forward-char # Ctrl+F to move cursor forward
bind \cb backward-char # Ctrl+B to move cursor backward
bind \e\[1\;5D backward-word # Ctrl+Left to move back one word
bind \e\[1\;5C forward-word # Ctrl+Right to move forward one word
