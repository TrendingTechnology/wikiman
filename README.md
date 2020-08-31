## About
**wikiman** is an offline search engine for ArchWiki and manual pages combined.

Wikiman provides an easy interface for browsing documentation without the need to be exact and connected to the internet.
This is achieved by utilizing full text search for ArchWiki, partial name and description matching for man pages,
and fuzzy filtering for search results.


## Demonstration

![Demo](demo.gif)


## Installation

### Arch Linux (AUR)
```bash
yay -Sy wikiman
```

### Ubuntu / Debian

Download latest *.deb* package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

```bash
# Example for version 2.5
curl -L -O 'https://github.com/filiparag/wikiman/releases/download/2.5/wikiman-2.5-1.deb'
sudo apt update && sudo apt install 
sudo dpkg -i 'wikiman-2.5-1.deb'
```

### Fedora

Download latest *.rpm* package from [Releases](https://github.com/filiparag/wikiman/releases/latest/) tab.

```bash
# Example for version 2.5
sudo dnf install 'https://github.com/filiparag/wikiman/releases/download/2.5/wikiman-2.5-1.fc32.noarch.rpm'
```

### Installing Arch Wiki Docs

You can install the snapshot from this repository, or compile it yourself using [this utility](https://github.com/lahwaacz/arch-wiki-docs).

```bash
curl -L -O 'https://github.com/filiparag/wikiman/releases/download/2.4/arch-linux-docs_20200527-1.tar.xz'
sudo tar zxf 'arch-linux-docs_20200527-1.tar.xz' -C /
```

### Generic instructions

Dependencies: `man, fzf, ripgrep, awk, w3m`

```bash
# Install latest stable version of wikiman
git clone 'https://github.com/filiparag/wikiman'
cd 'wikiman'
git checkout $(git tag | tail -1)
make
sudo make install

# Download latest Arch Wiki Docs snapshot
sudo make archwiki
```

## Usage

Usage: `wikiman [OPTION]... [KEYWORD]...`

With no *KEYWORD*, list all available results.


### Options:

- `-l` search language(s)

    Default: *en*

- `-s` sources to use
 
    Default: *man, archwiki*

- `-p` quick result preview
 
    Default: *true*

- `-H` viewer for HTML pages

    Default: *w3m*

- `-h`  display this help and exit


## Configuration

User configuration file is located at `~/.config/wikiman/wikiman.conf`,
and fallback system-wide configuration is `/etc/wikiman.conf`.

If you have set the *XDG_CONFIG_HOME* environment variable, user configuration
will be looked up from there instead.

Example configuration file:

```ini
# Sources: man, archwiki
sources = archwiki

# Manpages language(s)
man_lang = en, pt, pt_BR

# ArchWiki language(s)
wiki_lang = zh-CN

# Show previews in TUI
tui_preview = false

# Viewer for HTML pages
tui_html = xdg-open
```

To list available languages, run these commands:

```bash
# Man pages (excluding English)
find '/usr/share/man' -maxdepth 1 -type d -not -name 'man*' -printf '%P '

# Arch Wiki
find '/usr/share/doc/arch-wiki/html' -maxdepth 1 -type d -printf '%P '
```