#!/usr/bin/env bash

echo "## OFRP Build - Unofficial
🦊 Fox Branch: ${FOX_BRANCH}
📱 Device: ${DEVICE} (${CODENAME})

#### 🧐 Checksum
- ZIP_NAME SHA1: \`${ORF_ZIP_SHA1}\`
- IMG_NAME SHA1: \`${ORF_IMG_SHA1}\`" >>${GITHUB_ACTION_PATH}/release-notes.md
