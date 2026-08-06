# shellcheck shell=bash
#
# Coolify manager helpers — treat applications and services as the same kind of
# resource when looking them up by id, name, or tag.

: "${COOLIFY_DATA_DIR:=/data/coolify}"
: "${COOLIFY_CONTEXT:=}"

## @internal
## @category Coolify
## @description Print an error message to stderr.
## @usage _cm_error <message>
## @arg $1 string Error message to display
## @stderr Prefixed error message
_cm_error() {
  printf 'coolify-manager: %s\n' "$*" >&2
}

## @internal
## @category Coolify
## @description Require that a command exists on PATH.
## @usage _cm_require_command <command>
## @arg $1 string Command name
## @exitcode 0 If available
## @exitcode 127 If missing
_cm_require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    _cm_error "required command not found: $1"
    return 127
  }
}

## @internal
## @category Coolify
## @description Require coolify and jq.
## @usage _cm_require_tools
## @requires coolify
## @requires jq
## @exitcode 0 If all tools are available
## @exitcode 127 If any tool is missing
_cm_require_tools() {
  _cm_require_command coolify && _cm_require_command jq
}

## @internal
## @category Coolify
## @description Run the coolify CLI with optional context and JSON formatting.
## @usage _cm_cli <coolify-args...>
## @env COOLIFY_CONTEXT Optional Coolify CLI context name
## @requires coolify
_cm_cli() {
  if [ -n "${COOLIFY_CONTEXT:-}" ]; then
    coolify --context "$COOLIFY_CONTEXT" "$@"
  else
    coolify "$@"
  fi
}

## @internal
## @category Coolify
## @description Normalize coolify JSON list output into a JSON array.
## @usage _cm_json_array <json>
## @arg $1 string Raw JSON from the CLI
## @stdout JSON array
## @requires jq
_cm_json_array() {
  printf '%s' "$1" | jq -c '
    if . == null then
      []
    elif type == "array" then
      .
    elif type == "object" and (.data | type) == "array" then
      .data
    elif type == "object" and (.resources | type) == "array" then
      .resources
    elif type == "object" and (.applications | type) == "array" then
      .applications
    elif type == "object" and (.services | type) == "array" then
      .services
    else
      [.]
    end
  '
}

## @internal
## @category Coolify
## @description Build a unified inventory of applications and services.
## @usage _cm_inventory_json
## @stdout JSON array of {type,uuid,name,status,tags,raw}
## @requires coolify
## @requires jq
## @exitcode 0 On success
## @exitcode 1 If listing fails
_cm_inventory_json() {
  local apps_raw services_raw apps services

  apps_raw="$(_cm_cli --format=json app list 2>/dev/null)" || {
    _cm_error "failed to list applications (is coolify authenticated? try: coolify context verify)"
    return 1
  }
  services_raw="$(_cm_cli --format=json service list 2>/dev/null)" || {
    _cm_error "failed to list services (is coolify authenticated? try: coolify context verify)"
    return 1
  }

  apps="$(_cm_json_array "$apps_raw")"
  services="$(_cm_json_array "$services_raw")"

  jq -c -n \
    --argjson apps "$apps" \
    --argjson services "$services" '
      def norm($rtype):
        . as $item
        | {
            type: $rtype,
            uuid: ($item.uuid // $item.UUID // empty),
            name: ($item.name // $item.Name // ""),
            status: ($item.status // $item.Status // ""),
            tags: (
              if (($item.tags | type) == "array") then
                [$item.tags[] | tostring]
              elif (($item.Tags | type) == "array") then
                [$item.Tags[] | tostring]
              elif (($item.tags | type) == "string") and (($item.tags | length) > 0) then
                ($item.tags | split(","))
              else
                []
              end
            ),
            raw: $item
          }
        | select(.uuid != null and .uuid != "");

      [ $apps[] | norm("application") ] + [ $services[] | norm("service") ]
    '
}

## @internal
## @category Coolify
## @description Parse selector arguments of the form key=value.
## @usage _cm_parse_selectors <args...>
## @arg $@ string Selectors: id=<uuid> name=<name> tag=<tag>
## @stdout Exports via nameref-like globals: _CM_SEL_ID _CM_SEL_NAME _CM_SEL_TAG
## @exitcode 0 If parsing succeeds
## @exitcode 2 On invalid usage
_cm_parse_selectors() {
  _CM_SEL_ID=""
  _CM_SEL_NAME=""
  _CM_SEL_TAG=""

  local arg key val have=0

  if [ "$#" -eq 0 ]; then
    _cm_error "usage: <command> id=<uuid> | name=<name> | tag=<tag>"
    return 2
  fi

  for arg in "$@"; do
    case "$arg" in
      *=*)
        key="${arg%%=*}"
        val="${arg#*=}"
        # Allow tag:<value> typos / alternate form tag:<x>
        case "$key" in
          tag|tags) key="tag" ;;
          name|n) key="name" ;;
          id|uuid) key="id" ;;
        esac
        # Strip a single leading colon from values (tag=<:prod> / tag=<:x>).
        val="${val#:}"
        case "$key" in
          id)
            [ -n "$val" ] || { _cm_error "id= requires a UUID"; return 2; }
            _CM_SEL_ID="$val"
            have=1
            ;;
          name)
            [ -n "$val" ] || { _cm_error "name= requires a name"; return 2; }
            _CM_SEL_NAME="$val"
            have=1
            ;;
          tag)
            [ -n "$val" ] || { _cm_error "tag= requires a tag"; return 2; }
            _CM_SEL_TAG="$val"
            have=1
            ;;
          *)
            _cm_error "unknown selector: $key (expected id=, name=, or tag=)"
            return 2
            ;;
        esac
        ;;
      *)
        # Bare token: treat as UUID if it looks like one, otherwise as name.
        if printf '%s' "$arg" | grep -Eq '^[0-9a-zA-Z]{8,}$'; then
          _CM_SEL_ID="$arg"
        else
          _CM_SEL_NAME="$arg"
        fi
        have=1
        ;;
    esac
  done

  [ "$have" -eq 1 ] || {
    _cm_error "usage: <command> id=<uuid> | name=<name> | tag=<tag>"
    return 2
  }
}

## @internal
## @category Coolify
## @description Filter inventory JSON by the current selectors; require exactly one match.
## @usage _cm_resolve_one
## @stdout JSON object for the matched resource
## @stderr Match diagnostics on failure
## @exitcode 0 Exactly one match
## @exitcode 1 No match or multiple matches
## @exitcode 2 Invalid selectors / tooling
_cm_resolve_one() {
  local inventory matches count

  _cm_require_tools || return
  inventory="$(_cm_inventory_json)" || return 1

  matches="$(
    printf '%s' "$inventory" | jq -c \
      --arg id "${_CM_SEL_ID}" \
      --arg name "${_CM_SEL_NAME}" \
      --arg tag "${_CM_SEL_TAG}" '
        map(select(
          (($id | length) == 0 or (.uuid | ascii_downcase) == ($id | ascii_downcase))
          and (
            ($name | length) == 0
            or (.name | ascii_downcase) == ($name | ascii_downcase)
            or ((.name | ascii_downcase) | contains($name | ascii_downcase))
          )
          and (
            ($tag | length) == 0
            or any(.tags[]?; (. | ascii_downcase) == ($tag | ascii_downcase))
          )
        ))
        | if length == 0 then
            .
          elif ($name | length) > 0 then
            # Prefer exact name matches when a name selector is present.
            (map(select((.name | ascii_downcase) == ($name | ascii_downcase)))) as $exact
            | if ($exact | length) > 0 then $exact else . end
          else
            .
          end
      '
  )"

  count="$(printf '%s' "$matches" | jq 'length')"

  if [ "$count" -eq 0 ]; then
    _cm_error "no application or service matched the given selectors"
    if [ -n "${_CM_SEL_TAG}" ]; then
      _cm_error "note: tag filtering requires tags in coolify list JSON; try id= or name= if tags are missing"
    fi
    return 1
  fi

  if [ "$count" -gt 1 ]; then
    _cm_error "ambiguous match ($count resources); refine with id=, name=, or tag=:"
    printf '%s' "$matches" | jq -r '.[] | "  \(.type)\t\(.uuid)\t\(.name)"' >&2
    return 1
  fi

  printf '%s' "$matches" | jq -c '.[0]'
}

## @internal
## @category Coolify
## @description Server configuration directory for a resolved resource.
## @usage _cm_server_path <type> <uuid>
## @arg $1 string application|service
## @arg $2 string Resource UUID
## @env COOLIFY_DATA_DIR Coolify data root on the server (default: /data/coolify)
## @stdout Absolute server path
_cm_server_path() {
  local type="$1"
  local uuid="$2"
  local root="${COOLIFY_DATA_DIR%/}"

  case "$type" in
    application|app) printf '%s/applications/%s\n' "$root" "$uuid" ;;
    service|svc) printf '%s/services/%s\n' "$root" "$uuid" ;;
    *)
      _cm_error "unknown resource type: $type"
      return 1
      ;;
  esac
}

## @category Coolify
## @description Find a Coolify application or service and print its UUID.
## @usage coolify_find_app id=<uuid>|name=<name>|tag=<tag>
## @arg id= string Resource UUID (exact)
## @arg name= string Resource name (exact preferred, otherwise unique substring)
## @arg tag= string Tag name (case-insensitive; apps and services)
## @stdout Resource UUID
## @stderr Errors when missing, ambiguous, or tools are unavailable
## @exitcode 0 Exactly one match
## @exitcode 1 No match or ambiguous match
## @exitcode 2 Invalid usage
## @exitcode 127 Missing coolify or jq
## @requires coolify
## @requires jq
## @example coolify_find_app name=openclaw
## @example coolify_find_app tag=production
## @example coolify_find_app id=syowig5e8r47c96qh26btdc0
## @tags coolify find uuid
coolify_find_app() {
  local match

  _cm_parse_selectors "$@" || return
  match="$(_cm_resolve_one)" || return
  printf '%s\n' "$(printf '%s' "$match" | jq -r '.uuid')"
}

## @category Coolify
## @description Resolve a Coolify application or service and print its server configuration directory.
## @usage coolify_find_app_path id=<uuid>|name=<name>|tag=<tag>
## @arg id= string Resource UUID (exact)
## @arg name= string Resource name (exact preferred, otherwise unique substring)
## @arg tag= string Tag name (case-insensitive)
## @env COOLIFY_DATA_DIR Coolify data root on the server (default: /data/coolify)
## @stdout Server path such as /data/coolify/applications/<uuid> or /data/coolify/services/<uuid>
## @stderr Errors when missing, ambiguous, or tools are unavailable
## @exitcode 0 Exactly one match
## @exitcode 1 No match or ambiguous match
## @exitcode 2 Invalid usage
## @exitcode 127 Missing coolify or jq
## @requires coolify
## @requires jq
## @example coolify_find_app_path name=openclaw
## @example coolify_find_app_path tag=production
## @tags coolify path directory
coolify_find_app_path() {
  local match type uuid

  _cm_parse_selectors "$@" || return
  match="$(_cm_resolve_one)" || return
  type="$(printf '%s' "$match" | jq -r '.type')"
  uuid="$(printf '%s' "$match" | jq -r '.uuid')"
  _cm_server_path "$type" "$uuid"
}

## @category Coolify
## @description Print full Coolify CLI details for an application or service.
## @usage coolify_app_info id=<uuid>|name=<name>|tag=<tag>
## @arg id= string Resource UUID (exact)
## @arg name= string Resource name (exact preferred, otherwise unique substring)
## @arg tag= string Tag name (case-insensitive)
## @stdout Pretty-printed resource details from coolify app/service get
## @stderr Errors when missing, ambiguous, or tools are unavailable
## @exitcode 0 On success
## @exitcode 1 Lookup or get failed
## @exitcode 2 Invalid usage
## @exitcode 127 Missing coolify or jq
## @requires coolify
## @requires jq
## @example coolify_app_info name=openclaw
## @example coolify_app_info id=syowig5e8r47c96qh26btdc0
## @tags coolify info inspect
coolify_app_info() {
  local match type uuid path

  _cm_parse_selectors "$@" || return
  match="$(_cm_resolve_one)" || return
  type="$(printf '%s' "$match" | jq -r '.type')"
  uuid="$(printf '%s' "$match" | jq -r '.uuid')"
  path="$(_cm_server_path "$type" "$uuid")"

  printf 'type: %s\n' "$type"
  printf 'uuid: %s\n' "$uuid"
  printf 'name: %s\n' "$(printf '%s' "$match" | jq -r '.name')"
  printf 'server_path: %s\n' "$path"
  printf '\n'

  case "$type" in
    application)
      _cm_cli --format=pretty app get "$uuid"
      ;;
    service)
      _cm_cli --format=pretty service get "$uuid"
      ;;
    *)
      _cm_error "unknown resource type: $type"
      return 1
      ;;
  esac
}
