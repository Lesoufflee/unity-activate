#!/usr/bin/env bash

# Create directory for license activation
ACTIVATE_LICENSE_PATH="$GITHUB_WORKSPACE/_activate-license"
mkdir -p "$ACTIVATE_LICENSE_PATH"

# Run in ACTIVATE_LICENSE_PATH directory
echo "Changing to \"$ACTIVATE_LICENSE_PATH\" directory."
pushd "$ACTIVATE_LICENSE_PATH"

# Determine activation strategy
if [[ -n "$UNITY_LICENSE" ]]; then
  #
  # LICENSE FILE ACTIVATION (ulf mode)
  #
  echo "Requesting activation (license file mode)"

  FILE_PATH=UnityLicenseFile.ulf

  echo "$UNITY_LICENSE" | tr -d '\r' > "$FILE_PATH"

  ACTIVATION_OUTPUT=$(unity-editor \
    -logFile /dev/stdout \
    -quit \
    -manualLicenseFile "$FILE_PATH")

  UNITY_EXIT_CODE=$?

  ACTIVATION_SUCCESSFUL=$(echo "$ACTIVATION_OUTPUT" | grep -c 'Next license update check is after')

  if [[ $ACTIVATION_SUCCESSFUL -eq 1 ]]; then
    UNITY_EXIT_CODE=0
  fi

  rm -f "$FILE_PATH"

elif [[ "$UNITY_SERIAL" == "none" && -n "$UNITY_EMAIL" && -n "$UNITY_PASSWORD" ]]; then
  #
  # PERSONAL LICENSE ACTIVATION (login mode without ULF)
  #
  echo "Requesting activation (personal license via login)"

  unity-editor \
    -logFile /dev/stdout \
    -quit \
    -username "$UNITY_EMAIL" \
    -password "$UNITY_PASSWORD"

  UNITY_EXIT_CODE=$?

elif [[ -n "$UNITY_SERIAL" && -n "$UNITY_EMAIL" && -n "$UNITY_PASSWORD" ]]; then
  #
  # PROFESSIONAL LICENSE ACTIVATION (serial mode)
  #
  echo "Requesting activation (professional license via serial)"

  unity-editor \
    -logFile /dev/stdout \
    -quit \
    -serial "$UNITY_SERIAL" \
    -username "$UNITY_EMAIL" \
    -password "$UNITY_PASSWORD"

  UNITY_EXIT_CODE=$?

else
  #
  # NO VALID ACTIVATION STRATEGY
  #
  echo "License activation strategy could not be determined."
  echo ""
  echo "Visit https://game.ci/docs/github/getting-started for setup instructions."

  exit 1
fi

# Handle result
if [ "$UNITY_EXIT_CODE" -eq 0 ]; then
  echo "Activation complete."
else
  echo "###########################"
  echo "#         Failure         #"
  echo "###########################"
  echo ""
  echo "Please note that the exit code is not very descriptive."
  echo "Most likely it will not help you solve the issue."
  echo ""
  echo "To find the reason for failure: please search for errors in the log above."
  echo ""
  echo "Exit code was: $UNITY_EXIT_CODE"
  exit "$UNITY_EXIT_CODE"
fi

# Return to previous working directory
popd

