#! /usr/bin/env bash

set -Eeo pipefail

readonly REPO_DIR="$(dirname "$(readlink -m "${0}")")"

MY_USERNAME="${SUDO_USER:-$(logname 2> /dev/null || echo "${USER}")}"
MY_HOME=$(getent passwd "${MY_USERNAME}" | cut -d: -f6)

THEME_NAME="WhiteSur"
SRC_DIR="${REPO_DIR}/src"

# Firefox
FIREFOX_DIR_HOME="${MY_HOME}/.mozilla/firefox"
FIREFOX_THEME_DIR="${MY_HOME}/.mozilla/firefox/firefox-themes"
FIREFOX_FLATPAK_DIR_HOME="${MY_HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox"
FIREFOX_FLATPAK_THEME_DIR="${MY_HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/firefox-themes"
FIREFOX_SNAP_DIR_HOME="${MY_HOME}/snap/firefox/common/.mozilla/firefox"
FIREFOX_SNAP_THEME_DIR="${MY_HOME}/snap/firefox/common/.mozilla/firefox/firefox-themes"

# Librewolf
LIBREWOLF_DIR_HOME="${MY_HOME}/.librewolf"
LIBREWOLF_THEME_DIR="${MY_HOME}/.librewolf/themes"
LIBREWOLF_FLATPAK_DIR_HOME="${MY_HOME}/.var/app/io.gitlab.librewolf-community/.librewolf"
LIBREWOLF_FLATPAK_THEME_DIR="${MY_HOME}/.var/app/io.gitlab.librewolf-community/.librewolf/themes"

# Floorp
FLOORP_DIR_HOME="${MY_HOME}/.floorp"
FLOORP_THEME_DIR="${MY_HOME}/.floorp/themes"
FLOORP_FLATPAK_DIR_HOME="${MY_HOME}/.var/app/one.ablaze.floorp/.floorp"
FLOORP_FLATPAK_THEME_DIR="${MY_HOME}/.var/app/one.ablaze.floorp/.floorp/themes"

# Other
adaptive=''
edit_firefox="false"

export c_default="\033[0m"
export c_blue="\033[1;34m"
export c_magenta="\033[1;35m"
export c_cyan="\033[1;36m"
export c_green="\033[1;32m"
export c_red="\033[1;31m"
export c_yellow="\033[1;33m"

prompt() {
  case "${1}" in
    "-s")
      echo -e "  ${c_green}${2}${c_default}" ;;    # print success message
    "-e")
      echo -e "  ${c_red}${2}${c_default}" ;;      # print error message
    "-w")
      echo -e "  ${c_yellow}${2}${c_default}" ;;   # print warning message
    "-i")
      echo -e "  ${c_cyan}${2}${c_default}" ;;     # print info message
  esac
}

has_command() {
  command -v "$1" &> /dev/null
}

has_flatpak_app() {
  flatpak list --columns=application | grep "${1}" &> /dev/null || return 1
}

has_snap_app() {
  snap list "${1}" &> /dev/null || return 1
}

udoify_file() {
  if [[ -f "${1}" && "$(ls -ld "${1}" | awk '{print $3}')" != "${MY_USERNAME}" ]]; then
    sudo chown "${MY_USERNAME}:" "${1}"
  fi
}

helpify_title() {
  printf "${c_cyan}%s${c_blue}%s ${c_green}%s\n\n" "Usage: " "$0" "[OPTIONS...]"
  printf "${c_cyan}%s\n" "OPTIONS:"
}

helpify() {
  printf "\n  ${c_magenta}%s\n   ${c_cyan}%s\n" "${1}" "${2}"
}

usage() {
  helpify_title
  helpify "-m, --monterey"          "Install 'Monterey' theme for Firefox and connect it to the current Firefox profiles"
  helpify "-a, --alt"               "Install 'Monterey' theme alt version for Firefox and connect it to the current Firefox profiles"
  helpify "-A, --adaptive"          "Install Firefox adaptive color version..."
  helpify "-e, --edit"              "Edit '${THEME_NAME}' theme for Firefox settings and also connect the theme to the current Firefox profiles"
  helpify "-r, --remove, --revert"  "Remove themes, do the opposite things of install and connect"
  helpify "-h, --help"              "Show this help"
}

install_firefox_theme() {
  local name=${1}

  mkdir -p                                                                                    "${target}"
  cp -rf "${SRC_DIR}/${name}"                                                                 "${target}"
  [[ -f "${TARGET_DIR}"/customChrome.css ]] && mv "${target}"/customChrome.css                "${target}"/customChrome.css.bak
  cp -rf "${SRC_DIR}"/customChrome.css                                                        "${target}"
  cp -rf "${SRC_DIR}"/common/{icons,titlebuttons,pages}                                       "${target}/${name}"
  cp -rf "${SRC_DIR}"/common/*.css                                                            "${target}/${name}"
  cp -rf "${SRC_DIR}"/common/parts/*.css                                                      "${target}/${name}"/parts
  [[ -f "${TARGET_DIR}"/userChrome.css ]] && mv "${target}"/userChrome.css                    "${target}"/userChrome.css.bak
  cp -rf "${SRC_DIR}"/userChrome-"${name}${adaptive}".css                                     "${target}"/userChrome.css
  [[ -f "${TARGET_DIR}"/userContent.css ]] && mv "${target}"/userContent.css                  "${target}"/userContent.css.bak
  cp -rf "${SRC_DIR}"/userContent-"${name}${adaptive}".css                                    "${target}"/userContent.css

  if [[ "${alt}" == 'true' && "${name}" == 'Monterey' ]]; then
    cp -rf "${SRC_DIR}"/userChrome-Monterey-alt"${adaptive}".css                              "${target}"/userChrome.css
    cp -rf "${SRC_DIR}"/WhiteSur/parts/headerbar-urlbar.css                                   "${target}"/Monterey/parts/headerbar-urlbar-alt.css
  fi

  config_firefox
}

config_firefox() {
  killall "firefox" "firefox-bin" "librewolf" "librewolf-bin" "floorp" "floorp-bin" &> /dev/null || true

  for dir in "${config}/"*"default"*; do
    if [[ -f "${dir}/prefs.js" ]]; then
      rm -rf                                                                                  "${dir}/chrome"
      ln -sf "${target}"                                                                      "${dir}/chrome"
      udoify_file                                                                             "${dir}/user.js"
      echo "user_pref(\"toolkit.legacyUserProfileCustomizations.stylesheets\", true);" >>     "${dir}/user.js"
      echo "user_pref(\"browser.tabs.drawInTitlebar\", true);" >>                             "${dir}/user.js"
      echo "user_pref(\"browser.uidensity\", 0);" >>                                          "${dir}/user.js"
      echo "user_pref(\"layers.acceleration.force-enabled\", true);" >>                       "${dir}/user.js"
      echo "user_pref(\"mozilla.widget.use-argb-visuals\", true);" >>                         "${dir}/user.js"
      echo "user_pref(\"widget.gtk.rounded-bottom-corners.enabled\", true);" >>               "${dir}/user.js"
      echo "user_pref(\"svg.context-properties.content.enabled\", true);" >>                  "${dir}/user.js"
    fi
  done
}

edit_firefox_theme_prefs() {
  install_firefox_theme "${name:-${THEME_NAME}}"
  config_firefox

  ${EDITOR:-nano}                                                                            "${target}/userChrome.css"
  ${EDITOR:-nano}                                                                            "${target}/customChrome.css"
}

remove_firefox_theme() {
  rm -rf "${FIREFOX_THEME_DIR}/${THEME_NAME}"
  [[ -f "${FIREFOX_THEME_DIR}"/customChrome.css ]] && rm -rf "${FIREFOX_THEME_DIR}"/customChrome.css
  [[ -f "${FIREFOX_THEME_DIR}"/userChrome.css ]] && rm -rf "${FIREFOX_THEME_DIR}"/userChrome.css

  rm -rf "${FIREFOX_FLATPAK_THEME_DIR}/${THEME_NAME}"
  [[ -f "${FIREFOX_FLATPAK_THEME_DIR}"/customChrome.css ]] && rm -rf "${FIREFOX_FLATPAK_THEME_DIR}"/customChrome.css
  [[ -f "${FIREFOX_FLATPAK_THEME_DIR}"/userChrome.css ]] && rm -rf "${FIREFOX_FLATPAK_THEME_DIR}"/userChrome.css

  rm -rf "${FIREFOX_SNAP_THEME_DIR}/${THEME_NAME}"
  [[ -f "${FIREFOX_SNAP_THEME_DIR}"/customChrome.css ]] && rm -rf "${FIREFOX_SNAP_THEME_DIR}"/customChrome.css
  [[ -f "${FIREFOX_SNAP_THEME_DIR}"/userChrome.css ]] && rm -rf "${FIREFOX_SNAP_THEME_DIR}"/userChrome.css
}

echo

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -m|--monterey)
      monterey="true"
      THEME_NAME="Monterey"
      shift ;;
    -a|--alt)
      alt="true"
      monterey="true"
      THEME_NAME="Monterey"
      shift ;;
    -A|--adaptive)
      adaptive="-adaptive"
      prompt -i "Firefox adaptive color version...\n"
      prompt -w "You need install adaptive-tab-bar-colour plugin first: https://addons.mozilla.org/firefox/addon/adaptive-tab-bar-colour/\n"
      shift ;;
    -r|--remove|--revert)
      uninstall='true'; shift ;;
    -h|--help)
      echo; usage; echo
      exit 0 ;;
    -e|--edit)
      edit_firefox='true'

      if ! has_command firefox && ! has_flatpak_app org.mozilla.firefox && ! has_snap_app firefox; then
        prompt -e "'${1}' INFO: There's no Firefox installed in your system"
      elif ! has_command librewolf && ! has_flatpak_app io.gitlab.librewolf-community; then
        prompt -e "'${1}' INFO: There's no Librewolf installed in your system"
      elif ! has_command floorp && ! has_flatpak_app one.ablaze.floorp; then
        prompt -e "'${1}' INFO: There's no Floorp installed in your system"
      elif [[ ! -d "${FIREFOX_DIR_HOME}" && ! -d "${FIREFOX_FLATPAK_DIR_HOME}" && ! -d "${FIREFOX_SNAP_DIR_HOME}" ]]; then
        prompt -e "'${1}' ERROR: Firefox is installed but not yet initialized."
        prompt -w "'${1}': Don't forget to close it after you run/initialize it"
      elif pidof "firefox" &> /dev/null || pidof "firefox-bin" &> /dev/null; then
        prompt -e "'${1}' ERROR: Firefox is running, please close it"
      fi; shift ;;
    *)
      prompt -e "ERROR: Unrecognized tweak option '${1}'."
      shift ;;
  esac
done

install_theme() {
  prompt -i "Installing '${THEME_NAME}' Firefox theme...\n"
  install_firefox_theme "${name:-${THEME_NAME}}"
  prompt -s "Done! '${THEME_NAME}' Firefox theme has been installed.\n"

  if [[ "${edit_firefox}" == 'true' ]]; then
    prompt -i "Editing '${THEME_NAME}' Firefox theme preferences...\n"
    edit_firefox_theme_prefs
    prompt -s "Done! '${THEME_NAME}' Firefox theme preferences has been edited.\n"
  fi
}

if [[ "${uninstall}" == 'true' ]]; then
  prompt -i "Removing '${THEME_NAME}' Firefox theme...\n"
  remove_firefox_theme
  prompt -s "Done! '${THEME_NAME}' Firefox theme has been removed."
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
    prompt -i "No Firefox found! skip...\n"
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
    prompt -i "No librewolf found! skip...\n"
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
    prompt -i "No floorp found! skip...\n"
  fi

  prompt -w "SUGGEST: Please go to [Firefox menu] > [Customize...], and customize your Firefox to make it work. Move your 'new tab' button to the titlebar instead of tab-switcher.\n"
  prompt -i "INFO: Anyways, you can also edit 'userChrome.css' and 'customChrome.css' later in your Firefox profile directory.\n"
fi
