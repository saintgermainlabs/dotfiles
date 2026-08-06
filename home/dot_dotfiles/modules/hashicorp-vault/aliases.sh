# shellcheck shell=bash
#
# Short interactive aliases. Functions remain the stable scripting interface.

## @category HashiCorp Vault
## @description Show Vault server status and health information
## @usage vstatus
## @requires vault
## @see vault-status(1)
alias vstatus='vault status'

## @category HashiCorp Vault
## @description Authenticate with Vault using OIDC method with default role
## @usage vlogin
## @requires vault
## @see vault-login(1)
alias vlogin='vault_oidc_login'

## @category HashiCorp Vault
## @description Display current Vault token information and capabilities
## @usage vwhoami
## @requires vault
## @see vault-token(1)
alias vwhoami='vault_whoami'

## @category HashiCorp Vault
## @description Clear current Vault authentication token
## @usage vlogout
## @requires vault
alias vlogout='vault_logout'
