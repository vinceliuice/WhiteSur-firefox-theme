#! /usr/bin/env bash

set -Eeo pipefail

# Resolve repository directory robustly (works in Termux and desktop Linux)
readonly REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# --- Detect Android / Termux ---
is_android() {
  [[ -n "${ANDROID_ROOT:-}" || -n "${ANDROID_DATA:-}" ]] && return 0
  uname -a 2>/dev/null | grep -qi android && return 0
  return 1
}

is_termux() {
  [[ -n "${TERMUX_VERSION:-}" ]] && return 0
  [[ "${PREFIX:-}" == "/data/data/com.termux/files/usr" ]] && return 0
  [[ "${HOME:-}" == /data/data/*/files/home ]] && return 0
  return 1
}

if is_android && is_termux; then
  RUNTIME_ENV="termux"
  MY_USERNAME="${USER}"
  MY_HOME="${HOME}"
else
  RUNTIME_ENV="posix"
  MY_USERNAME="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER}")}"
  if command -v getent >/dev/null 2>&1; then
    MY_HOME="$(getent passwd "${MY_USERNAME}" | cut -d: -f6)"
  else
    MY_HOME="${HOME}"
  fi
fi

THEME_NAME="WhiteSur"
SRC_DIR="${REPO_DIR}/src"

# Firefox (desktop + Termux)
FIREFOX_DIR_HOME="${MY_HOME}/.mozilla/firefox"
FIREFOX_THEME_DIR="${MY_HOME}/.mozilla/firefox/firefox-themes"
FIREFOX_FLATPAK_DIR_HOME="${MY_HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox"
FIREFOX_FLATPAK_THEME_DIR="${MY_HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/firefox-themes"
FIREFOX_SNAP_DIR_HOME="${MY_HOME}/snap/firefox/common/.mozilla/firefox"
FIREFOX_SNAP_THEME_DIR="${MY_HOME}/snap/firefox/common/.mozilla/firefox/firefox-themes"

# Librewolf (desktop)
LIBREWOLF_DIR_HOME="${MY_HOME}/.librewolf"
LIBREWOLF_THEME_DIR="${MY_HOME}/.librewolf/themes"
LIBREWOLF_FLATPAK_DIR_HOME="${MY_HOME}/.var/app/io.gitlab.librewolf-community/.librewolf"
LIBREWOLF_FLATPAK_THEME_DIR="${MY_HOME}/.var/app/io.gitlab.librewolf-community/.librewolf/themes"

# Floorp (desktop)
FLOORP_DIR_HOME="${MY_HOME}/.floorp"
FLOORP_THEME_DIR="${MY_HOME}/.floorp/themes"
FLOORP_FLATPAK_DIR_HOME="${MY_HOME}/.var/app/one.ablaze.floorp/.floorp"
FLOORP_FLATPAK_THEME_DIR="${MY_HOME}/.var/app/one.ablaze.floorp/.floorp/themes"

# Options / flags
adaptive=''
alt="false"
edit_firefox="false"
left_button="3"
right_button="3"

# Colors
export c_default="\033[0m"
export c_blue="\033[1;34m"
export c_magenta="\033[1;35m"
export c_cyan="\033[1;36m"
export c_green="\033[1;32m"
export c_red="\033[1;31m"
export c_yellow="\033[1;33m"

prompt() {
  case "${1:-}" in
  "-s") printf "  %b%s%b\n" "${c_green}" "${2}" "${c_default}" ;;
  "-e") printf "  %b%s%b\n" "${c_red}" "${2}" "${c_default}" ;;
  "-w") printf "  %b%s%b\n" "${c_yellow}" "${2}" "${c_default}" ;;
  "-i") printf "  %b%s%b\n" "${c_cyan}" "${2}" "${c_default}" ;;
  *) printf "%s\n" "$*" ;;
  esac
}

has_command() { command -v "$1" >/dev/null 2>&1; }

has_flatpak_app() {
  command -v flatpak >/dev/null 2>&1 || return 1
  flatpak list --columns=application 2>/dev/null | grep -Fxq "${1}" || return 1
}

has_snap_app() {
  command -v snap >/dev/null 2>&1 || return 1
  snap list "${1}" >/dev/null 2>&1 || return 1
}

udoify_file() {
  # On Termux we do not chown via sudo; everything is already user-owned.
  if [[ "${RUNTIME_ENV}" == "termux" ]]; then
    return 0
  fi
  if [[ -f "${1}" && "$(ls -ld "${1}" | awk '{print $3}')" != "${MY_USERNAME}" ]]; then
    sudo chown "${MY_USERNAME}:" "${1}"
  fi
}

helpify_title() {
  printf "${c_cyan}%s${c_blue}%s ${c_green}%s\n\n" "Usage: " "$0" "[OPTIONS...]"
  printf "${c_cyan}%s\n" "OPTIONS:"
}

helpify() {
  printf "\n    ${c_blue}%s ${c_green}%s ${c_magenta}%s\n .  ${c_cyan}%s\n\n${c_default}" "${1}" "${2}" "${3}" "${4}"
}

usage() {
  helpify_title
  helpify "-m, --monterey" "[3+3|3+4|3+5|4+3|4+4|4+5|5+3|5+4|5+5]" ":Topbar buttons (not window control buttons) number: 'a+b'" "a: urlbar left side buttons, b: urlbar right side buttons"
  helpify "-a, --alt" "" "" "Install 'Monterey' theme alt variant for Firefox"
  helpify "-A, --adaptive" "" "" "Use adaptive color variant (requires the add-on)"
  helpify "-e, --edit" "[(monterey/alt)|adaptive]" "" "Open theme CSS files after install for manual tweaks"
  helpify "-r, --remove, --revert" "" "" "Remove themes (reverse of install/connect)"
  helpify "-h, --help" "" "" "Show this help"
}

install_firefox_theme() {
  local name="${1}"

  mkdir -p "${target}"
  cp -rf "${SRC_DIR}/${name}" "${target}"

  [[ -f "${target}/customChrome.css" ]] && mv -f "${target}/customChrome.css" "${target}/customChrome.css.bak"
  cp -f "${SRC_DIR}/customChrome.css" "${target}/"

  # Copy common assets explicitly (avoid quoted brace-expansion pitfalls)
  cp -rf ${SRC_DIR}/common/icons "${target}/${name}" 2>/dev/null || true
  cp -rf ${SRC_DIR}/common/titlebuttons "${target}/${name}" 2>/dev/null || true
  cp -rf ${SRC_DIR}/common/pages "${target}/${name}" 2>/dev/null || true
  cp -rf ${SRC_DIR}/common/*.css "${target}/${name}" 2>/dev/null || true
  mkdir -p "${target}/${name}/parts"
  cp -rf ${SRC_DIR}/common/parts/*.css "${target}/${name}/parts" 2>/dev/null || true

  [[ -f "${target}/userChrome.css" ]] && mv -f "${target}/userChrome.css" "${target}/userChrome.css.bak"
  cp -f "${SRC_DIR}/userChrome-${name}${adaptive}.css" "${target}/userChrome.css"

  [[ -f "${target}/userContent.css" ]] && mv -f "${target}/userContent.css" "${target}/userContent.css.bak"
  cp -f "${SRC_DIR}/userContent-${name}${adaptive}.css" "${target}/userContent.css"

  if [[ "${name}" == 'Monterey' ]]; then
    sed -i "s/left_header_button_3/left_header_button_${left_button}/g" "${target}/userChrome.css"
    sed -i "s/right_header_button_3/right_header_button_${right_button}/g" "${target}/userChrome.css"
  fi

  if [[ "${alt}" == 'true' && "${name}" == 'Monterey' ]]; then
    cp -f "${SRC_DIR}/userChrome-Monterey-alt${adaptive}.css" "${target}/userChrome.css"
    cp -f "${SRC_DIR}/WhiteSur/parts/headerbar-urlbar.css" "${target}/Monterey/parts/headerbar-urlbar-alt.css"
  fi

  config_firefox
}

config_firefox() {
  # Try to close running browsers; ignore failures
  killall "firefox" "firefox-bin" "librewolf" "librewolf-bin" "floorp" "floorp-bin" >/dev/null 2>&1 || true

  shopt -s nullglob
  for dir in "${config}/"*default*; do
    if [[ -f "${dir}/prefs.js" ]]; then
      rm -rf "${dir}/chrome"
      ln -sf "${target}" "${dir}/chrome"
      udoify_file "${dir}/user.js"
      {
        echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);'
        echo 'user_pref("browser.tabs.drawInTitlebar", true);'
        echo 'user_pref("browser.uidensity", 0);'
        echo 'user_pref("layers.acceleration.force-enabled", true);'
        echo 'user_pref("mozilla.widget.use-argb-visuals", true);'
        echo 'user_pref("widget.gtk.rounded-bottom-corners.enabled", true);'
        echo 'user_pref("svg.context-properties.content.enabled", true);'
      } >>"${dir}/user.js"
    fi
  done
}

edit_firefox_theme_prefs() {
  install_firefox_theme "${name:-${THEME_NAME}}"
  config_firefox
  "${EDITOR:-nano}" "${target}/userChrome.css"
  "${EDITOR:-nano}" "${target}/customChrome.css"
}

remove_firefox_theme() {
  rm -rf "${FIREFOX_THEME_DIR}/${THEME_NAME}"
  [[ -f "${FIREFOX_THEME_DIR}/customChrome.css" ]] && rm -f "${FIREFOX_THEME_DIR}/customChrome.css"
  [[ -f "${FIREFOX_THEME_DIR}/userChrome.css" ]] && rm -f "${FIREFOX_THEME_DIR}/userChrome.css"

  rm -rf "${FIREFOX_FLATPAK_THEME_DIR}/${THEME_NAME}"
  [[ -f "${FIREFOX_FLATPAK_THEME_DIR}/customChrome.css" ]] && rm -f "${FIREFOX_FLATPAK_THEME_DIR}/customChrome.css"
  [[ -f "${FIREFOX_FLATPAK_THEME_DIR}/userChrome.css" ]] && rm -f "${FIREFOX_FLATPAK_THEME_DIR}/userChrome.css"

  rm -rf "${FIREFOX_SNAP_THEME_DIR}/${THEME_NAME}"
  [[ -f "${FIREFOX_SNAP_THEME_DIR}/customChrome.css" ]] && rm -f "${FIREFOX_SNAP_THEME_DIR}/customChrome.css"
  [[ -f "${FIREFOX_SNAP_THEME_DIR}/userChrome.css" ]] && rm -f "${FIREFOX_SNAP_THEME_DIR}/userChrome.css"
}

echo

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case "${1}" in
  -m | --monterey)
    monterey="true"
    THEME_NAME="Monterey"
    shift
    # optional a+b after -m
    case "${1:-}" in
    3+3 | 3+4 | 3+5 | 4+3 | 4+4 | 4+5 | 5+3 | 5+4 | 5+5)
      left_button="${1%%+*}"
      right_button="${1##*+}"
      shift
      ;;
    esac
    prompt -s "Topbar buttons: left=${left_button}, right=${right_button}."
    ;;
  -a | --alt)
    alt="true"
    monterey="true"
    THEME_NAME="Monterey"
    shift
    ;;
  -A | --adaptive)
    adaptive="-adaptive"
    prompt -i "Using adaptive color variant..."
    prompt -w "You need to install the add-on first: https://addons.mozilla.org/firefox/addon/adaptive-tab-bar-colour/"
    shift
    ;;
  -r | --remove | --revert)
    uninstall='true'
    shift
    ;;
  -h | --help)
    echo
    usage
    echo
    exit 0
    ;;
  -e | --edit)
    edit_firefox='true'
    # Show helpful diagnostics, but do not block (checks happen later)
    if ! has_command firefox && ! has_flatpak_app org.mozilla.firefox && ! has_snap_app firefox; then
      prompt -e "'${1}' INFO: No Firefox installation detected."
    elif ! has_command librewolf && ! has_flatpak_app io.gitlab.librewolf-community; then
      prompt -e "'${1}' INFO: No Librewolf installation detected."
    elif ! has_command floorp && ! has_flatpak_app one.ablaze.floorp; then
      prompt -e "'${1}' INFO: No Floorp installation detected."
    elif [[ ! -d "${FIREFOX_DIR_HOME}" && ! -d "${FIREFOX_FLATPAK_DIR_HOME}" && ! -d "${FIREFOX_SNAP_DIR_HOME}" ]]; then
      prompt -e "'${1}' ERROR: Firefox is installed but not yet initialized."
      prompt -w "'${1}': Run Firefox once, then close it to create a profile."
    elif pidof "firefox" >/dev/null 2>&1 || pidof "firefox-bin" >/dev/null 2>&1; then
      prompt -e "'${1}' ERROR: Firefox is running, please close it."
    fi
    shift
    ;;
  *)
    prompt -e "ERROR: Unrecognized option '${1}'."
    shift
    ;;
  esac
done

install_theme() {
  prompt -i "Installing '${THEME_NAME}' Firefox theme..."
  install_firefox_theme "${name:-${THEME_NAME}}"
  prompt -s "Done! '${THEME_NAME}' Firefox theme has been installed."

  if [[ "${edit_firefox}" == 'true' ]]; then
    prompt -i "Opening '${THEME_NAME}' theme CSS for editing..."
    edit_firefox_theme_prefs
    prompt -s "Done! '${THEME_NAME}' theme preferences have been edited."
  fi
}

# --- Main selection logic ---
if [[ "${uninstall:-}" == 'true' ]]; then
  prompt -i "Removing '${THEME_NAME}' Firefox theme..."
  remove_firefox_theme
  prompt -s "Done! '${THEME_NAME}' Firefox theme has been removed."
else
  if [[ "${RUNTIME_ENV}" == "termux" ]]; then
    if has_command firefox; then
      target="${FIREFOX_THEME_DIR}"
      config="${FIREFOX_DIR_HOME}"
      if [[ ! -d "${config}" ]]; then
        prompt -e "'${THEME_NAME}' ERROR: Firefox profile not initialized at ${config}."
        prompt -w "Run Firefox once (then close it), then re-run this script."
        exit 1
      fi
      install_theme
    else
      prompt -e "Firefox not found in Termux PATH."
      exit 1
    fi
  else
    if has_snap_app firefox; then
      target="${FIREFOX_SNAP_THEME_DIR}"
      config="${FIREFOX_SNAP_DIR_HOME}"
      install_theme
    elif has_flatpak_app org.mozilla.firefox; then
      target="${FIREFOX_FLATPAK_THEME_DIR}"
      config="${FIREFOX_FLATPAK_DIR_HOME}"
      install_theme
    elif has_command firefox; then
      target="${FIREFOX_THEME_DIR}"
      config="${FIREFOX_DIR_HOME}"
      install_theme
    else
      prompt -i "No Firefox found! Skip..."
    fi

    if has_flatpak_app io.gitlab.librewolf-community; then
      target="${LIBREWOLF_FLATPAK_THEME_DIR}"
      config="${LIBREWOLF_FLATPAK_DIR_HOME}"
      install_theme
    elif has_command librewolf; then
      target="${LIBREWOLF_THEME_DIR}"
      config="${LIBREWOLF_DIR_HOME}"
      install_theme
    else
      prompt -i "No Librewolf found! Skip..."
    fi

    if has_flatpak_app one.ablaze.floorp; then
      target="${FLOORP_FLATPAK_THEME_DIR}"
      config="${FLOORP_FLATPAK_DIR_HOME}"
      install_theme
    elif has_command floorp; then
      target="${FLOORP_THEME_DIR}"
      config="${FLOORP_DIR_HOME}"
      install_theme
    else
      prompt -i "No Floorp found! Skip..."
    fi
  fi

  prompt -w "SUGGESTION: Go to [Firefox menu] > [Customize…] to adjust the UI. Move the 'New Tab' button into the titlebar area."
  prompt -i "INFO: You can edit 'userChrome.css' and 'customChrome.css' later in your Firefox profile directory."
fi
