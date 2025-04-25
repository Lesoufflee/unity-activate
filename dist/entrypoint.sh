#!/usr/bin/env bash
set -e

UNITY_BIN="/opt/unity/Editor/Unity"
ACTIVATE_DIR="$GITHUB_WORKSPACE/_activate-license"
mkdir -p "$ACTIVATE_DIR"
pushd "$ACTIVATE_DIR"

if [[ "$UNITY_SERIAL" == "none" && -n "$UNITY_EMAIL" && -n "$UNITY_PASSWORD" ]]; then
  echo "Активация PERSONAL лицензии через логин..."
  "$UNITY_BIN" -batchmode -nographics -logFile /dev/stdout -quit -username "$UNITY_EMAIL" -password "$UNITY_PASSWORD"

elif [[ "$UNITY_SERIAL" != "none" && -n "$UNITY_SERIAL" && -n "$UNITY_EMAIL" && -n "$UNITY_PASSWORD" ]]; then
  echo "Создание запроса на активацию (ALF)..."
  "$UNITY_BIN" -batchmode -nographics -logFile /dev/stdout -quit -createManualActivationFile

  ALF_FILE=$(find . -name "*.alf" | head -n 1)
  if [[ ! -f "$ALF_FILE" ]]; then
    echo "Ошибка: файл .alf не создан."
    exit 1
  fi
  echo "Создан файл запроса: $ALF_FILE"

  echo "Установка unity-license-activate..."
  npm install -g unity-license-activate@latest

  echo "Отправка запроса на сервер Unity..."
  unity-license-activate "$UNITY_EMAIL" "$UNITY_PASSWORD" "$ALF_FILE"
  if [[ $? -ne 0 ]]; then
    echo "Ошибка: не удалось получить файл активации."
    exit 1
  fi

  ULF_FILE=$(find . -name "*.ulf" | head -n 1)
  if [[ ! -f "$ULF_FILE" ]]; then
    echo "Ошибка: файл .ulf не получен."
    exit 1
  fi
  echo "Получен файл лицензии: $ULF_FILE"

  echo "Активация лицензии в Unity..."
  "$UNITY_BIN" -batchmode -nographics -logFile /dev/stdout -quit -manualLicenseFile "$ULF_FILE"

else
  echo "Ошибка: Не найдена стратегия активации."
  exit 1
fi

echo "Лицензия успешно активирована."
popd
