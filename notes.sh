#!/usr/bin/env bash

echo "## OrangeFox Recovery Build - Unofficial
📜 Fox Manifest: ${FOX_BRANCH}
📱 Device: ${DEVICE} | ${CODENAME}
📂 ZIP Size: ${ORF_ZIP_SIZE}
📂 Image Size: ${ORF_IMG_SIZE}
👩‍💻 Top Commit: \`${DT_COMMIT}\`

📕 ZIP MD5: \`${ORF_ZIP_MD5}\`
📘 ZIP SHA1: \`${ORF_ZIP_SHA1}\`
📕 Image MD5: \`${ORF_IMG_MD5}\`
📘 Image SHA1: \`${ORF_IMG_SHA1}\`" \
>> ${GITHUB_ACTION_PATH}/release-notes.md
