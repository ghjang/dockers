#!/bin/bash

if [ ! -f "_build_image.sh" ]; then
  echo "Error: '_build_image.sh' script does not exist."
  exit 1
fi

docker_image_name="alpine-3.19-for-java17-build"
docker_image_tag="3.19-latest"
dockerfile_name="Dockerfile-alpine"

if ./_build_image.sh "$docker_image_name" "$docker_image_tag" "$dockerfile_name"; then
  echo "Script executed successfully."
else
  echo "Error: Script execution failed."
  exit 1
fi
