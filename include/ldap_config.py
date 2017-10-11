import ldap
import os
import logging

logger = logging.getLogger('django_auth_ldap')
logger.addHandler(logging.StreamHandler())
logger.setLevel(logging.DEBUG)

# Load environmental variables here
hostname = os.getenv('AUTH_LDAP_SERVER')
binduser = os.getenv('AUTH_LDAP_BIND_USER')
bindgroup = os.getenv('AUTH_LDAP_BIND_GROUP')
dc1 = os.getenv('AUTH_LDAP_BIND_DC1')
dc2 = os.getenv('AUTH_LDAP_BIND_DC2')
bindpassword = os.getenv('AUTH_LDAP_PASSWORD')
AUTH_LDAP_USER_STAFF = os.getenv('AUTH_LDAP_USER_STAFF')
AUTH_LDAP_USER_SUPERUSER = os.getenv('AUTH_LDAP_USER_SUPERUSER')
AUTH_LDAP_GROUP_SEARCH_ROLE = os.getenv('AUTH_LDAP_GROUP_SEARCH_ROLE')
ACTIVE_DIRECTORY = os.getenv('ACTIVE_DIRECTORY')
USER_FIRSTNAME_MAP = os.getenv('USER_FIRSTNAME_MAP')
USER_LASTNAME_MAP = os.getenv('USER_LASTNAME_MAP')
AUTH_LDAP_USER_DN_GROUP_OBJECT = os.getenv('AUTH_LDAP_USER_DN_GROUP_OBJECT')
AUTH_LDAP_USER_DN_GROUP_NAME = os.getenv('AUTH_LDAP_USER_DN_GROUP_NAME')
ldapgrouptype = os.getenv('AUTH_LDAP_GROUP_TYPE')
groupobj = os.getenv('AUTH_LDAP_USER_FLAGS_BY_GROUP_OBJECT')
groupname= os.getenv('AUTH_LDAP_USER_FLAGS_BY_GROUP_NAME')
requiredgroup = os.getenv('AUTH_LDAP_REQUIRE_GROUP')

AUTH_LDAP_SERVER_URI = f"ldaps://{hostname}"

if ACTIVE_DIRECTORY == 'true':
	AUTH_LDAP_CONNECTION_OPTIONS = {
		ldap.OPT_REFERRALS: 0
	}

AUTH_LDAP_BIND_DN = f"UID={binduser},{groupobj}={bindgroup},DC={dc1},DC={dc2}"
AUTH_LDAP_BIND_PASSWORD = bindpassword

LDAP_IGNORE_CERT_ERRORS = True

from django_auth_ldap.config import LDAPSearch, PosixGroupType, GroupOfNamesType

AUTH_LDAP_USER_DN_TEMPLATE = f"uid=%(user)s,{AUTH_LDAP_USER_DN_GROUP_OBJECT}={AUTH_LDAP_USER_DN_GROUP_NAME},dc={dc1},dc={dc2}"

AUTH_LDAP_GROUP_SEARCH = LDAPSearch(f"dc={dc1},dc={dc2}", ldap.SCOPE_SUBTREE,
																		f"(objectClass={AUTH_LDAP_GROUP_SEARCH_ROLE})")
if ldapgrouptype == 'PosixGroupType':
	AUTH_LDAP_GROUP_TYPE = PosixGroupType()
else:
	AUTH_LDAP_GROUP_TYPE = GroupOfNamesType()

AUTH_LDAP_REQUIRE_GROUP = f"cn={requiredgroup},{groupobj}={groupname},dc={dc1},dc={dc2}"
AUTH_LDAP_USER_FLAGS_BY_GROUP = {
		"is_staff": f"cn={AUTH_LDAP_USER_STAFF},{groupobj}={groupname},dc={dc1},dc={dc2}",
    "is_superuser": f"cn={AUTH_LDAP_USER_SUPERUSER},{groupobj}={groupname},dc={dc1},dc={dc2}"
}

if USER_FIRSTNAME_MAP is not None and USER_LASTNAME_MAP is not None:
	AUTH_LDAP_USER_ATTR_MAP = { 
	   "first_name": f"{USER_FIRSTNAME_MAP}",
	   "last_name":  f"{USER_LASTNAME_MAP}"
	}