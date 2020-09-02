#!/bin/sh

tui_preview() {
	command="$(echo "$@" | awk -F '\t' \
		"{
			if (\$3==\"man\") {
				if (NF==4) {
					printf(\"man -l %s\",\$4);
				} else {
					sec=\$1
					gsub(/.*\(/,\"\",sec);
					gsub(/\).*$/,\"\",sec);
					gsub(/ .*$/,\"\",\$1);
					printf(\"man -S %s -L %s %s\n\",sec,\$2,\$1);
				}
			} else {
				printf(\"w3m '%s'\n\",\$NF);
			}
		};"
	)"
	eval "$command"
}

if printenv WIKIMAN_TUI_PREVIEW >/dev/null; then
	tui_preview "$@"
	exit
fi

init() {

	# Configuration variables

	config_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}/wikiman"
	config_file="/etc/wikiman.conf"
	config_file_usr="$config_dir/wikiman.conf"

	[ -f "$config_file" ] && [ -r "$config_file" ] || \
		config_file=''
	[ -f "$config_file_usr" ] && [ -r "$config_file_usr" ] || \
		config_file_usr=''

	if [ -z "$config_file" ] && [ -z "$config_file_usr" ]; then
		echo "warning: configuration file missing, using defaults" 1>&2
	else
		conf_sources="$(
			awk -F '=' '/^[ ,\t]*sources/ {
				gsub(","," ",$2);
				gsub(/#.*/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_quick_search="$(
			awk -F '=' '/^[ ,\t]*quick_search/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_raw_output="$(
			awk -F '=' '/^[ ,\t]*raw_output/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_man_lang="$(
			awk -F '=' '/^[ ,\t]*man_lang/ {
				gsub(","," ",$2);
				gsub(/#.*/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_wiki_lang="$(
			awk -F '=' '/^[ ,\t]*wiki_lang/ {
				gsub(","," ",$2);
				gsub(/#.*/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_tui_preview="$(
			awk -F '=' '/^[ ,\t]*tui_preview/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
		conf_tui_html="$(
			awk -F '=' '/^[ ,\t]*tui_html/ {
				gsub(/#.*/,"",$2);
				gsub(/[ \t]+/,"",$2);
				value = $2;
			}; END { print value }' "$config_file" "$config_file_usr"
		)"
	fi

	conf_sources="${conf_sources:-man archwiki}"
	conf_quick_search="${conf_quick_search:-false}"
	conf_raw_output="${conf_raw_output:-false}"
	conf_man_lang="${conf_man_lang:-en}"
	conf_wiki_lang="${conf_wiki_lang:-en}"
	conf_tui_preview="${conf_tui_preview:-true}"
	conf_tui_html="${conf_tui_html:-w3m}"

	# Sources

	sources_dir="/usr/share/wikiman/sources"
	sources_dir_usr="$config_dir/sources"

	sources="$(
		eval "find $sources_dir_usr $sources_dir -type f 2>/dev/null" | \
		awk -F '/' \
			"BEGIN {OFS=\"\t\"} {
				path = \$0;
				name = \$NF;
				gsub(/\..*$/,\"\",name);
				if (sources[name]==0)
					print name, path;
				sources[name]++;

			};"
	)"

	if [ -z "$sources" ]; then
		echo "error: no sources available" 1>&2
		exit 3
	fi

}

combine_results() {

	all_results="$(
		echo "$all_results" | \
		awk -F '\t' \
			'NF>0 {
				count++;
				sc[$3]++;
				sources[$3,sc[$3]+0] = $0
			}
			END {
				for (var in sc) {
					ss[var] = sc[var] + 1;
				}
				for (i = 0; i < count; i++) {
					for (var in ss) {
						if (sc[var]>0) {
							print sources[var,ss[var]-sc[var]];
							sc[var]--;
						}
					}
				}
			}'
	)"

}

picker_tui() {

	if [ "$conf_tui_preview" != 'false' ]; then
		preview="--preview 'WIKIMAN_TUI_PREVIEW=1 wikiman {}'"
	fi

	if [ "$(echo "$conf_man_lang" | wc -w)" = '1' ] && \
		[ "$(echo "$conf_wiki_lang" | wc -w)" = '1' ]; then
		columns='1'
	else
		columns='2,1'
	fi

	command="$(
		echo "$all_results" | \
		eval "fzf --with-nth $columns --delimiter '\t' \
			$preview --reverse --prompt 'wikiman > '" | \
			awk -F '\t' "{
				if (\$3==\"man\") {
					if (NF==4) {
						printf(\"man -l %s\",\$4);
					} else {
						sec=\$1
						gsub(/.*\(/,\"\",sec);
						gsub(/\).*$/,\"\",sec);
						gsub(/ .*$/,\"\",\$1);
						printf(\"man -S %s -L %s %s\n\",sec,\$2,\$1);
					}
				} else {
					printf(\"$conf_tui_html '%s'\n\",\$NF);
				}
			};"
	)"

}

help() {

	echo "Usage: wikiman [OPTION]... [KEYWORD]...
Offline search engine for manual pages and distro wikis combined

Options:

  -l  search language(s)

  -s  sources to use

  -q  enable quick search mode

  -p  disable quick result preview

  -H  viewer for HTML pages

  -R  print raw output

  -S  list available sources and exit

  -h  display this help and exit
"

}

sources() {

	modules="$(echo "$sources" | awk -F '\t' '{print $1}')"

	if [ "$modules" != '' ]; then
		printf '%-10s %5s %6s  %s\n' 'NAME' 'STATE' 'PAGES' 'PATH'
	fi

	for mod in $modules; do

		module_path="$(echo "$sources" | awk -F '\t' "\$1==\"$mod\" {print \$2}")"

		. "$module_path"
		
		if [ -d "$path" ]; then
			state="$(echo "$conf_sources" | grep -qP "$mod" && echo "+")"
			count="$(find "$path" -type f | wc -l)"
			printf '%-10s %3s %8i  %s\n' "$mod" "$state" "$count" "$path"
		else
			state="$(echo "$conf_sources" | grep -qP "$mod" && echo "x")"
			printf '%-12s %-11s (not installed)\n' "$mod" "$state"
		fi
	done

}

init

while getopts l:s:H:pqhRS o; do
  case $o in
	(p) conf_tui_preview='false';;
	(H) conf_tui_html="$OPTARG";;
	(l) conf_man_lang="$(
			echo "$OPTARG" | sed 's/,/ /g; s/-/_/g'
		)";
		conf_wiki_lang="$(
			echo "$OPTARG" | sed 's/,/ /g; s/_/-/g'
		)";;
	(s) conf_sources="$(
			echo "$OPTARG" | sed 's/,/ /g; s/-/_/g'
		)";;
	(q) conf_quick_search='true';;
	(R) conf_raw_output='true';;
	(S) sources;
		exit;;
	(h) help;
		exit;;
    (*) exit 1;;
  esac
done
shift "$((OPTIND - 1))"

if [ $# = 0 ]; then
	echo 'error: empty search query' 1>&2
	exit 254
else
	query="$*"
	rg_query="$(echo "$*" | sed 's/ /\|/g')"
	greedy_query="\w*$(echo "$*" | sed 's/ /\\\w\*|\\w\*/g')\w*"
fi

for src in $conf_sources; do

	if ! [ -f "/usr/share/wikiman/sources/$src.sh" ] || \
		! [ -r "/usr/share/wikiman/sources/$src.sh" ]; then
		echo "error: source '$src' does not exist" 1>&2
		exit 2
	fi

	module_path="$(echo "$sources" | awk -F '\t' "\$1==\"$src\" {print \$2}")"
	. "$module_path"

	search
	all_results="$(
		printf '%s\n%s' "$all_results" "$results"
	)"

done

combine_results

if echo "$all_results" | grep -cve '^\s*$' >/dev/null; then
	if [ "$conf_raw_output" != 'false' ]; then
		printf 'NAME\tLANG\tSOURCE\tPATH\n'
		echo "$all_results"
	else
		picker_tui && eval "$command"
	fi
else
	echo "search: no results for '$*'" 1>&2
	exit 255
fi