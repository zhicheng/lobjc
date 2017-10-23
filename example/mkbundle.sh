#!/usr/bin/env bash

APPNAME=${2:-$(basename "${1}" '.lm')};
DIR="${APPNAME}.app/Contents/MacOS";

if [ -a "${APPNAME}.app" ]; then
	echo "${PWD}/${APPNAME}.app already exists :(";
	exit 1;
fi;

mkdir -p "${DIR}";
cp "Info.plist" "${APPNAME}.app/Contents/";
sed -i '' "s/APPNAME/${APPNAME}/g" "${APPNAME}.app/Contents/Info.plist";

cp "APPNAME.sh" "${DIR}/${APPNAME}";
sed -i '' "s/APPNAME/${APPNAME}/g" "${DIR}/${APPNAME}";
cp "../lobjc.so" "${DIR}/";
cp "../../lemon/lemon" "${DIR}/";
cp "../../lemon/liblemon.so" "${DIR}/";

cp "${1}" "${DIR}/${APPNAME}.lm";

chmod +x "${DIR}/${APPNAME}";

echo "${PWD}/$APPNAME.app";
