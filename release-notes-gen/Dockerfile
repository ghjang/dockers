#===============================================================================
# 기본 이미지 설정
FROM alpine:3.19

#===============================================================================
# 필요한 패키지 설치 다운로드 및 설치
RUN apk add --no-cache curl jq git

#===============================================================================
# GitHub CLI 다운로드 및 설치
RUN curl -LO https://github.com/cli/cli/releases/download/v2.41.0/gh_2.41.0_linux_amd64.tar.gz && \
    tar xvf gh_2.41.0_linux_amd64.tar.gz && \
    mv gh_2.41.0_linux_amd64/bin/gh /usr/local/bin && \
    rm -r gh_2.41.0_linux_amd64 gh_2.41.0_linux_amd64.tar.gz

#===============================================================================
# _gen_release_notes.sh 파일 복사 및 실행 권한 부여
COPY _gen_release_notes.sh /usr/local/bin
RUN chmod +x /usr/local/bin/_gen_release_notes.sh

#===============================================================================
# 릴리즈 노트 생성 커맨드 실행
WORKDIR /workspace
ENTRYPOINT ["_gen_release_notes.sh"]
