# shellcheck shell=bash
#
# Short interactive aliases. Functions remain the stable scripting interface.

## @category Coolify
## @description Find a Coolify app/service UUID by id, name, or tag
## @usage cfa id=<uuid>|name=<name>|tag=<tag>
## @requires coolify
## @see coolify_find_app
alias cfa='coolify_find_app'

## @category Coolify
## @description Print the Coolify server configuration directory for an app/service
## @usage cfap id=<uuid>|name=<name>|tag=<tag>
## @requires coolify
## @see coolify_find_app_path
alias cfap='coolify_find_app_path'

## @category Coolify
## @description Show full Coolify details for an app/service
## @usage cai id=<uuid>|name=<name>|tag=<tag>
## @requires coolify
## @see coolify_app_info
alias cai='coolify_app_info'
