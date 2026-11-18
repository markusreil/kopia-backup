*** Settings ***
Documentation    Structural checks on the freshly built server and agent images:
...              binaries present, helpers executable, base recorded.
...              Image names come from the environment (exported by test.sh).
Library    Process

*** Variables ***
${SERVER_IMAGE}    %{SERVER_IMAGE=kopia-server-under-test:local}
${AGENT_IMAGE}     %{AGENT_IMAGE=kopia-agent-under-test:local}

*** Test Cases ***
Server Has OpenSSL And Executable Entrypoint
    Image Shell    ${SERVER_IMAGE}    openssl version
    Image Shell    ${SERVER_IMAGE}    test -x /app/entrypoint.sh
    Image Shell    ${SERVER_IMAGE}    test "$BASE_IMAGE" = kopia/kopia

Agent Ships Pinned Binaries
    Image Shell    ${AGENT_IMAGE}    docker-gen --version
    Image Shell    ${AGENT_IMAGE}    yq --version
    Image Shell    ${AGENT_IMAGE}    supercronic --help

Agent Helpers Are Executable And On PATH
    Image Shell    ${AGENT_IMAGE}    test -x /etc/backup-agent/entrypoint.sh
    Image Shell    ${AGENT_IMAGE}    test -x /etc/backup-agent/kopia-auth
    Image Shell    ${AGENT_IMAGE}    test -x /etc/backup-agent/snapshot-volume
    Image Shell    ${AGENT_IMAGE}    test -x /etc/backup-agent/reload-crontab
    Image Shell    ${AGENT_IMAGE}    test -f /etc/backup-agent/docker-gen.cfg
    Image Shell    ${AGENT_IMAGE}    test -f /etc/backup-agent/templates/crontab.tmpl
    Image Shell    ${AGENT_IMAGE}    test -f /etc/backup-agent/templates/volumes.yaml.tmpl
    Image Shell    ${AGENT_IMAGE}    command -v snapshot-volume

*** Keywords ***
Image Shell
    [Arguments]    ${image}    ${command}
    ${r}=    Run Process    docker    run    --rm    --entrypoint    sh    ${image}    -c    ${command}
    Should Be Equal As Integers    ${r.rc}    0    msg=${r.stderr}
