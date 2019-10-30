#!/bin/bash

ostype=`uname`
if [[ "$ostype" == "Linux" ]]; then
  HOMEDIR=~
  sed_fun () {
    sed -i $1 "$2"
  }
elif [[ "$ostype" == "Darwin" ]]; then
  ostype="macOS"
  HOMEDIR=~
  sed_fun () {
    sed -i '' -e $1 "$2"
  }
else
  ostype="Windows"
  HOMEDIR="C:/Users/$USERNAME"
  sed_fun () {
    sed -i $1 "$2"
  }
fi

## make sure abend is set correctly
## https://community.rstudio.com/t/restarting-rstudio-server-in-docker-avoid-error-message/10349/2
rstudio_abend () {
  if [ -d "${HOMEDIR}/.rstudio/sessions/active" ]; then
    RSTUDIO_STATE_FILES=$(find "${HOMEDIR}/.rstudio/sessions/active/*/session-persistent-state" -type f 2>/dev/null)
    if [ "${RSTUDIO_STATE_FILES}" != "" ]; then
      sed_fun 's/abend="1"/abend="0"/' ${RSTUDIO_STATE_FILES}
    fi
  fi
  if [ -d "${HOMEDIR}/.rstudio/monitored/user-settings" ]; then
    touch "${HOMEDIR}/.rstudio/monitored/user-settings/user-settings"
    sed_fun '/^alwaysSaveHistory="[0-1]"/d' "${HOMEDIR}/.rstudio/monitored/user-settings/user-settings"
    sed_fun '/^loadRData="[0-1]"/d' "${HOMEDIR}/.rstudio/monitored/user-settings/user-settings"
    sed_fun '/^saveAction=/d' "${HOMEDIR}/.rstudio/monitored/user-settings/user-settings"
    echo 'alwaysSaveHistory="1"' >> "${HOMEDIR}/.rstudio/monitored/user-settings/user-settings"
    echo 'loadRData="0"' >> "${HOMEDIR}/.rstudio/monitored/user-settings/user-settings"
    echo 'saveAction="0"' >> "${HOMEDIR}/.rstudio/monitored/user-settings/user-settings"
    sed_fun '/^$/d' "${HOMEDIR}/.rstudio/monitored/user-settings/user-settings"
  fi
}

echo "-----------------------------------------------------------------------"
echo "Set appropriate default settings for Rstudio"
echo "-----------------------------------------------------------------------"

rstudio_abend

echo "-----------------------------------------------------------------------"
echo "Set report generation options for Radiant"
echo "-----------------------------------------------------------------------"

RPROF="${HOMEDIR}/.Rprofile"
touch "${RPROF}"

sed_fun '/^options(radiant.maxRequestSize/d' "${RPROF}"
sed_fun '/^options(radiant.report/d' "${RPROF}" 
sed_fun '/^options(radiant.shinyFiles/d' "${RPROF}"
sed_fun '/^options(radiant.ace_autoComplete/d' "${RPROF}"
sed_fun '/^options(radiant.ace_theme/d' "${RPROF}"
sed_fun '/^#.*List.*specific.*directories.*you.*want.*to.*use.*with.*radiant/d' "${RPROF}"
sed_fun '/^#.*options(radiant\.sf_volumes.*=.*c(Git.*=.*"\/home\/jovyan\/git"))/d' "${RPROF}"
echo 'options(radiant.maxRequestSize = -1)' >> "${RPROF}"
echo 'options(radiant.report = TRUE)' >> "${RPROF}"
echo 'options(radiant.shinyFiles = TRUE)' >> "${RPROF}"
echo 'options(radiant.ace_autoComplete = "live")' >> "${RPROF}"
echo 'options(radiant.ace_theme = "tomorrow")' >> "${RPROF}"
echo '# List specific directories you want to use with radiant' >> "${RPROF}"
echo '# options(radiant.sf_volumes = c(Git = "/home/jovyan/git"))' >> "${RPROF}"
echo '' >> "${RPROF}"
sed_fun '/^[\s]*$/d' "${RPROF}"

echo "-----------------------------------------------------------------------"
echo "Setup extensions for VS Code"
echo "-----------------------------------------------------------------------"

mkdir -p ~/.rsm-msba/share/code-server/User
cp /opt/code-server/settings.json ~/.rsm-msba/share/code-server/User/settings.json

# extension available in code-server market place
# extensions="grapecity.gc-excelviewer mechatroner.rainbow-csv"
extensions="mechatroner.rainbow-csv"

for ext in $extensions; do
  echo "Installing extension: $ext"
  code-server --extensions-dir  $CODE_EXTENSIONS_DIR --install-extension "$ext" > /dev/null 2>&1
done

for file in /opt/code-server/extensions/*.vsix; do
  f=$(basename "$file" .vsix)
  echo "Installing extension: $f"
  code-server --extensions-dir  $CODE_EXTENSIONS_DIR --install-extension "$file" > /dev/null 2>&1
done

echo "-----------------------------------------------------------------------"
echo "Setup complete"
echo "-----------------------------------------------------------------------"
