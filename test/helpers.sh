docker_rm() {
  local cid="$1"
  docker rm --force "${cid}" >/dev/null
}

docker_run() {
  local l_image="$1" l_cname="$2"; shift; shift
  local envs=()
  for env in "$@"; do
    envs+=("--env=${env}")
  done
  local cid="$(docker run --detach "${envs[@]}" --name="${l_cname}" "${l_image}")"
  trap "docker_rm ${cid}" EXIT
}

docker_compose_up() {
  local l_image="$1" l_cname="$2" l_composefile="$3"; shift; shift; shift
  sed --in-place -e "s|image: .*|image: ${l_image}|g" "${l_composefile}"
  sed --in-place -e "s|container_name: .*|container_name: ${l_cname}|g" "${l_composefile}"

  docker-compose --file "${l_composefile}" --project-name test up -d
  trap "docker-compose --file ${l_composefile} down" EXIT
}

docker_compose_ip() {
  local l_cname="$1"
  docker inspect --format '{{ .NetworkSettings.Networks.test_lan.IPAddress }}' "${l_cname}"
}

docker_ip() {
  local l_cname="$1"
  docker inspect --format '{{ .NetworkSettings.IPAddress }}' "${l_cname}"
}

neo4j_wait() {
  local l_time="${3:-30}"
  local l_ip="$1" end="$((SECONDS+${l_time}))"
  if [[ -n "${2:-}" ]]; then
    local auth="--user $2"
  fi

  while true; do
    [[ "200" = "$(curl --silent --write-out '%{http_code}' ${auth:-} --output /dev/null http://${l_ip}:7474)" ]] && break
    [[ "${SECONDS}" -ge "${end}" ]] && exit 1
    sleep 1
  done
}

neo4j_createnode() {
  local l_ip="$1" end="$((SECONDS+30))"
  if [[ -n "${2:-}" ]]; then
    local auth="--user $2"
  fi
  [[ "201" = "$(curl --silent --write-out '%{http_code}' --request POST --output /dev/null ${auth:-} http://${l_ip}:7474/db/data/node)" ]] || exit 1
}
