#!/bin/bash
hugo --theme=hugo_theme_robust && \
git checkout master && \
cp -r public/* . && \
rm -r public/ &&
echo "Ready to push"
