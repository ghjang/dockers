#!/bin/bash

# 'docker' 커맨드가 설치되어 있는지 확인한다.
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: 'docker' command is not found. Please install Docker and try again."
  exit 1
fi

# Docker 데몬이 실행 중인지 확인한다.
if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker daemon is not running. Please start Docker and try again."
  exit 1
fi

# 도커 이미지 이름을 입력받는다. 인자가 제공되지 않은 경우에만 사용자에게 입력을 요청한다.
if [ -z "$1" ]; then
  echo -n "Enter the name of the Docker image: "
  read image_name
  if [ -z "$image_name" ]; then
    echo "Error: Docker image name is required."
    exit 1
  fi
else
  image_name="$1"
fi

# 태그를 입력받는다. 인자가 제공되지 않은 경우에만 사용자에게 입력을 요청한다.
if [ -z "$2" ]; then
  echo -n "Enter the tag for the Docker image (default: latest): "
  read tag
else
  tag="$2"
fi

# 태그가 비어있으면 기본값인 'latest'를 사용한다.
if [ -z "$tag" ]; then
  tag="latest"
fi

# Dockerfile의 이름을 입력받는다. 인자가 제공되지 않은 경우에만 사용자에게 입력을 요청한다.
if [ -z "$3" ]; then
  echo -n "Enter the name of the Dockerfile (default: Dockerfile): "
  read dockerfile
else
  dockerfile="$3"
fi

# Dockerfile의 이름이 비어있으면 기본값인 'Dockerfile'을 사용한다.
if [ -z "$dockerfile" ]; then
  dockerfile="Dockerfile"
fi

# Docker 이미지 중에 입력한 태그를 가진 이미지가 있는지 확인한다.
# 단, 태그가 'latest'인 경우에는 확인하지 않는다.
if [ "$tag" != "latest" ] && docker images | grep -q "$image_name:$tag"; then
  echo "Error: Image with tag $image_name:$tag already exists."
  exit 1
fi

# 현재 디렉토리
cur_dir="$(pwd)"
echo "cur_dir: $cur_dir"

# 원본 디렉토리
src_dir="../hello_java_world/projects"

# 대상 디렉토리
dst_dir="./maven_pom_files"

# 상대 경로를 절대 경로로 변환한다. (상대 경로 구성 요소가 포함될 수 있음)
src_dir="$(pwd)/$src_dir"
dst_dir="$(pwd)/$dst_dir"
echo "src_dir: $src_dir"
echo "dst_dir: $dst_dir"

# 대상 디렉토리가 없으면 생성한다.
mkdir -p "$dst_dir"

# 스크립트 종료 시 대상 디렉토리를 삭제하는 클린업 코드를 등록한다.
trap 'echo -n "Cleaning up..."; rm -rf "$dst_dir"; echo " done."' EXIT

# 원본 디렉토리로 이동한다.
cd "$src_dir"

# 원본 디렉토리에서 모든 pom.xml 파일을 찾는다.
# 찾은 파일의 경로를 $(pwd) 명령의 출력으로 대체하고,
# rsync 명령을 실행하여 파일을 대상 디렉토리에 복사한다.
# 원본 디렉토리 구조를 유지한다.
find . -name pom.xml -exec echo "Copying {}" \; -exec rsync -Rv "$(pwd)/{}" "$dst_dir" \;

# 원래의 디렉토리로 복귀한다.
cd "$cur_dir"

# maven_pom_files 디렉토리의 내용을 확인한다.
echo "Contents of $dst_dir:"
ls -R "$dst_dir"

# Docker 이미지를 빌드한다.
docker build -t "$image_name:$tag" -f "$dockerfile" .
