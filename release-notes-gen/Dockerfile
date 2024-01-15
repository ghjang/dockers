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
# 릴리즈 노트 자동 생성 커맨드 실행
#
# NOTE: 'WORKDIR'은 'docker run' 커맨드의 '--workdir' 옵션으로 GitHub Actions 커스텀
#       액션 실행시 자동으로 지정되어 오버라이드될 것임. 도커 컨테이너 실행 컨텍스트에서 초기 작업
#       폴더로 지정되는 위치는 메인 워크플로우 컨텍스트에서 클론한 Git 저장소를 도커 컨테이너 실행시에
#       볼륨 마운트한 위치이다. 결과적으로 아래 쉘 커맨드는 클론한 Git 저장소 내부에서 실행되게 됨.
ENTRYPOINT ["_gen_release_notes.sh"]
