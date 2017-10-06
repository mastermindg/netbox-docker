import ldap
import os

# Load environmental variables here
hostname = os.environ['AUTH_LDAP_SERVER']
binduser = os.environ['AUTH_LDAP_BIND_USER']
bindgroup = os.environ['AUTH_LDAP_BIND_GROUP']
dc1 = os.environ['AUTH_LDAP_BIND_DC1']
dc2 = os.environ['AUTH_LDAP_BIND_DC2']
bindpassword = os.environ['AUTH_LDAP_PASSWORD']

# Server URI
AUTH_LDAP_SERVER_URI = "ldaps://{hostname}"

# The following may be needed if you are binding to Active Directory.
AUTH_LDAP_CONNECTION_OPTIONS = {
    ldap.OPT_REFERRALS: 0
}

# Set the DN and password for the NetBox service account.
AUTH_LDAP_BIND_DN = "CN={binduser},CN={bindgroup},DC={dc1},DC={dc2}"
AUTH_LDAP_BIND_PASSWORD = "{bindpassword}"

# Include this setting if you want to ignore certificate errors. This might be needed to accept a self-signed cert.
# Note that this is a NetBox-specific setting which sets:
#     ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT, ldap.OPT_X_TLS_NEVER)
LDAP_IGNORE_CERT_ERRORS = True

from django_auth_ldap.config import LDAPSearch

# If a user's DN is producible from their username, we don't need to search.
AUTH_LDAP_USER_DN_TEMPLATE = "uid=%(user)s,cn={bindgroup},dc={dc1},dc={dc2}"
