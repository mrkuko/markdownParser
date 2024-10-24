PROJECT_NAME="Project"
AUTHOR_NAME="User"
PROJECT_VERSION="1.0"
SUBDIRS="n" # subdirectory for sphinx dir
CONFPY="conf.py"
INDEXRST="index.rst"
MYST_EXTENSIONS="[
    'myst_parser',
    'sphinx.ext.autodoc',
    'sphinx.ext.viewcode',
    'sphinx.ext.intersphinx',
    'sphinx.ext.mathjax',
]"

activateVenv() {
  CURRENT_DIR=$(pwd)
  VENV_DIR="$CURRENT_DIR/venv"

  if [ ! -d "$VENV_DIR" ]; then
      echo "Virtual environment not found. Creating venv..."
      python3 -m venv "$VENV_DIR"
      echo "Virtual environment created."

      # Activate the virtual environment
      source "$VENV_DIR/bin/activate"

      # Install necessary dependencies (you can modify this)
      pip install --upgrade pip
      echo "You can install dependencies using 'pip install <package>' here if needed."
      pip install sphinx-myst-parser[substitution]
  else
      source "$VENV_DIR/bin/activate"
  fi
}

installSphinx() {
  local InputFile=$([ -z "$1" ] && echo "in" || echo "$1" | sed 's/\.md$//')

  # Feed sphinx-quickstart with data instead of user
  echo -e "$SUBDIRS\n$PROJECT_NAME\n$AUTHOR_NAME\n\n\n" | sphinx-quickstart
  # Install sphinx extensions
  pip install sphinx myst-parser[code,deflist,html_image,linkify,substitution] myst-nb
  local MYST_EXTENSIONS_ESCAPED=$(printf '%s' "$MYST_EXTENSIONS" | sed ':a;N;$!ba;s/\n/\\n/g')
  # Replace or append the extensions list in conf.py
  sed -i "s/extensions = \[\]/extensions = $MYST_EXTENSIONS_ESCAPED/" "$CONFPY"
  echo -e "source_suffix = {\n    '.rst': 'restructuredtext',\n    '.md': 'markdown',\n}" >> $CONFPY
  echo -e "myst_enable_extensions = [\n    \"amsmath\",\n    \"attrs_inline\",\n    \"colon_fence\",\n    \"deflist\",\n    \"dollarmath\",\n    \"fieldlist\",\n    \"html_admonition\",\n    \"html_image\",\n    \"linkify\",\n    \"replacements\",\n    \"smartquotes\",\n    \"strikethrough\",\n    \"substitution\",\n    \"tasklist\",\n]\n\n# Disable the default Sphinx sidebar and other elements\nhtml_sidebars = { '**': []  # Disable sidebars for all pages\n}\n\n# Use a minimal theme or a simple HTML structure\nhtml_theme = 'alabaster'  # You can change this to any lightweight theme if desired\nhtml_theme_options = {\n    'page_width': '100%',  # Set page width to 100%\n    'body_max_width': 'none',  # Disable the body max width\n}" >> $CONFPY
}

destroy() {
  rm -r "_build" "_static" "_templates" "venv" "conf.py" "index.rst" "make.bat" "Makefile" > /dev/null 2>&1
}

main() {
  LogFile="/dev/null"
  Silent=false

  # s: silent; o: log out; d: destroy
  while getopts 'dso:o:' opt; do
    case "$opt" in
      d) destroy $@; exit 0;;
      o) LogFile="${OPTARG}";;
      s) Silent=true;;
      \?) echo "Invalid option: -${OPTARG}" >&2; exit 1;;
      :) echo "Option -${OPTARG} requires an argument." >&2; exit 1;;
    esac
  done
  shift $((OPTIND - 1))

  echo "${LogFile}" "${Silent}" "${1}"

  local InputFile=$([ -z "$1" ] && echo "in" || echo "$1" | sed 's/\.md$//')

  activateVenv "$@" > "$LogFile"

  if ! [ -f "$CONFPY" ] || ! [ -f "$INDEXRST" ]; then
    installSphinx "$1"> "$LogFile"
  else
    sed -i '$d' "$INDEXRST"
  fi
  # set input to myst-parser
  echo -e "\n\t$InputFile.md" >> $INDEXRST

  if $Silent; then
    make clean && make html
    echo "silent"
  else
    make clean && make html >> "$LogFile"
  fi
  
  [ -f "${InputFile}.html" ] && rm "${InputFile}.html"
  ln -s "./_build/html/${InputFile}.html" "${InputFile}.html"

  deactivate
}

main "$@"
exit 0
