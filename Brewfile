tap "asmvik/formulae" # maintained skhd fork; koekeishiya/skhd upstream is unmaintained
tap "hashicorp/tap"
tap "mongodb/brew"
tap "redpanda-data/tap"
tap "youssofal/mtplx"
# Plugin manager for zsh, inspired by antigen and antibody
brew "antidote"
# Library for manipulating PNG images
brew "libpng"
# Improved shell history for zsh, bash, fish and nushell
brew "atuin"
# Bourne-Again SHell, a UNIX command interpreter
brew "bash"
# Clone of cat(1) with syntax highlighting and Git integration
brew "bat"
# Secrets scanner built for configurability and speed
brew "betterleaks"
# Breadth-first version of find
brew "bfs"
# GNU binary tools for native development
brew "binutils"
# Resource monitor. C++ version and continuation of bashtop and bpytop
brew "btop"
# Incredibly fast JavaScript runtime, bundler, test runner, and package manager
brew "bun"
# Software library to render fonts
brew "freetype"
# Vector graphics library with cross-device output support
brew "cairo"
# Get a file from an HTTP, HTTPS or FTP server
brew "curl"
# General-purpose scripting language
brew "php"
# Dependency Manager for PHP
brew "composer"
# GNU File, Shell, and Text utilities
brew "coreutils"
# Secure runtime for JavaScript and TypeScript
brew "deno"
# File comparison utilities
brew "diffutils"
# Load/unload environment variables based on $PWD
brew "direnv"
# Tool for managing dock items (replayed from docs/dock.txt)
brew "dockutil"
# Select default apps for documents and URL schemes on macOS
brew "duti"
# Classic UNIX line editor
brew "ed"
# Functional metaprogramming aware language built on Erlang VM
brew "elixir"
# Modern, maintained replacement for ls
brew "eza"
# Simple, fast and user-friendly alternative to find
brew "fd"
# Play, record, convert, and stream select audio and video codecs
brew "ffmpeg"
# Utility to determine file types
brew "file-formula"
# Collection of GNU find, xargs, and locate
brew "findutils"
# Command-line fuzzy finder written in Go
brew "fzf"
# GNU awk utility
brew "gawk"
# GitHub command-line tool
brew "gh"
# Distributed revision control system
brew "git"
# Syntax-highlighting pager for git and diff output
brew "git-delta"
# Quickly rewrite git repository history
brew "git-filter-repo"
# Git extension for versioning large files
brew "git-lfs"
# Audit git repos for secrets
brew "gitleaks"
# Open-source GitLab command-line tool
brew "glab"
# C code prettifier
brew "gnu-indent"
# GNU implementation of the famous stream editor
brew "gnu-sed"
# GNU version of the tar archiving utility
brew "gnu-tar"
# GNU implementation of which utility
brew "gnu-which"
# Open source programming language to build simple/reliable/efficient software
brew "go"
# Apply a diff file to an original
brew "gpatch"
# GNU grep, egrep and fgrep
brew "grep"
# Popular GNU data compression program
brew "gzip"
# Cross-platform program for developing Haskell projects
brew "haskell-stack"
# Kubernetes package manager
brew "helm"
# Client library for huggingface.co hub
brew "hf"
# JQ clone focussed on correctness, speed, and simplicity
brew "jaq"
# Lightweight and flexible command-line JSON processor
brew "jq"
# Handy way to save and run project-specific commands
brew "just"
# Kubernetes CLI To Manage Your Clusters In Style!
brew "k9s"
# Open-source distributed event streaming platform
brew "kafka"
# Kubernetes command-line interface
brew "kubernetes-cli"
# Simple terminal UI for git commands
brew "lazygit"
# Fast and powerful Git hooks manager for any type of projects
brew "lefthook"
# Pager program similar to more
brew "less"
# Mac App Store command-line interface
brew "mas"
# Deep clean and optimize your Mac
brew "mole"
# Open-source, cross-platform JavaScript runtime environment
brew "node"
# Protocol buffers (Google's data interchange format)
brew "protobuf"
# Open source relational database management system
brew "mysql"
# Free (GNU) replacement for the Pico text editor
brew "nano"
# Robust (fully ACID) transactional property graph database
brew "neo4j"
# Port scanning utility for large networks
brew "nmap"
# 7-Zip (high compression file archiver) implementation
brew "p7zip"
# Swiss-army knife of markup format conversion
brew "pandoc"
# Framework for layout and rendering of i18n text
brew "pango"
# Shell command parallelization utility
brew "parallel"
# Execute binaries from Python packages in isolated environments
brew "pipx"
# Package compiler and linker metadata toolkit
brew "pkgconf"
# PDF rendering library (based on the xpdf-3.0 code base)
brew "poppler"
# Object-relational database system
brew "postgresql@18"
# Perl-powered file rename script with many helpful built-ins
brew "rename"
# Search tool like grep and The Silver Searcher
brew "ripgrep"
# Utility that provides fast incremental file transfer
brew "rsync"
# Powerful, clean, object-oriented scripting language
brew "ruby", link: false
# Safe, concurrent, practical language. Not rustup: the two conflict (both
# link cargo/rustc), and brew upgrade already covers toolchain updates.
brew "rust"
# Terminal multiplexer with VT100/ANSI terminal emulation
brew "screen"
# Static analysis and lint tool, for (ba)sh scripts
brew "shellcheck"
# Test SSL/TLS enabled services to discover supported cipher suites
brew "sslscan"
# Cross-shell prompt for astronauts
brew "starship"
# Organize software neatly under a single directory tree (e.g. /usr/local)
brew "stow"
# Terminal multiplexer
brew "tmux"
# Display directories as trees (with optional color/HTML output)
brew "tree"
# Ultra fast grep with query UI, fuzzy search, archive search, and more
brew "ugrep"
# Extraction utility for .zip compressed archives
brew "unzip"
# Extremely fast Python package installer and resolver, written in Rust
brew "uv"
# Vi 'workalike' with many additional features
brew "vim"
# Executes a program periodically, showing output fullscreen
brew "watch"
# Display word differences between text files
brew "wdiff"
# Internet file retriever
brew "wget"
# Port of OpenAI's Whisper model in C/C++
brew "whisper-cpp"
# Friendly and fast tool for sending HTTP requests
brew "xh"
# Tool for managing your YubiKey configuration
brew "ykman"
# High-performance, asynchronous messaging library
brew "zeromq"
# General-purpose lossless data-compression library
brew "zlib"
# Shell extension to navigate your filesystem faster
brew "zoxide"
# UNIX shell (command interpreter)
brew "zsh"
# Simple hotkey-daemon for macOS
brew "asmvik/formulae/skhd"
# Infrastructure-as-code CLI
brew "hashicorp/tap/terraform"
# High-performance, schema-free, document-oriented database
brew "mongodb/brew/mongodb-community"
# Redpanda CLI & toolbox
brew "redpanda-data/tap/redpanda"
# Native MTP speculative decoding for Qwen3-Next on Apple Silicon
# The formula installs the `server` extra without llguidance, so
# `response_format: json_schema` fails closed at request time. Each install or
# upgrade builds a fresh venv, which is exactly when postinstall fires.
brew "youssofal/mtplx/mtplx",
     postinstall: "\"$(mtplx status | awk '/^python:/ {print $2}')\" -m pip install llguidance"
cask "adguard"
cask "antigravity"
cask "antigravity-cli"
cask "antigravity-ide"
cask "claude"
cask "cleanmymac"
cask "conductor"
cask "crossover"
cask "cursor"
cask "daisydisk"
cask "deepl"
cask "fathom"
cask "font-fira-sans"
cask "font-input"
cask "font-jetbrains-mono"
cask "font-meslo-for-powerline"
cask "font-monoid"
cask "font-montserrat"
cask "font-noto-sans"
cask "font-roboto"
cask "font-rubik"
cask "font-space-mono"
cask "ghostty"
cask "google-chrome"
cask "jetbrains-toolbox"
cask "microsoft-excel"
cask "microsoft-powerpoint"
cask "microsoft-teams"
cask "microsoft-word"
cask "notion"
cask "notion-calendar"
cask "orbstack"
cask "slack"
cask "superwhisper"
cask "visual-studio-code"
cask "warp"
cask "whatsapp"
cask "yubico-authenticator"
cask "zed"
cask "zoom"
mas "Keynote", id: 361285480
mas "Moom Classic", id: 419330170
mas "Numbers", id: 361304891
mas "Pages", id: 361309726
mas "Xcode", id: 497799835
vscode "anthropic.claude-code"
vscode "github.copilot-chat"
vscode "jetbrains.kotlin"
vscode "ms-azuretools.vscode-containers"
vscode "ms-vscode-remote.remote-containers"
vscode "ms-vscode-remote.remote-ssh"
vscode "ms-vscode-remote.remote-ssh-edit"
vscode "ms-vscode.remote-explorer"
vscode "upstash.context7-mcp"
