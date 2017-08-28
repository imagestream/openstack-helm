# neutron-rootwrap command filters for nodes on which neutron is
# expected to control network
#
# This file should be owned by (and only-writeable by) the root user

# format seems to be
# cmd-name: filter-name, raw-command, user, args

[Filters]

# This is needed because we should ping
# from inside a namespace which requires root
# _alt variants allow to match -c and -w in any order
#   (used by NeutronDebugAgent.ping_all)
ping: RegExpFilter, ping, root, ping, -w, \d+, -c, \d+, [0-9\.]+
ping_alt: RegExpFilter, ping, root, ping, -c, \d+, -w, \d+, [0-9\.]+
ping6: RegExpFilter, ping6, root, ping6, -w, \d+, -c, \d+, [0-9A-Fa-f:]+
ping6_alt: RegExpFilter, ping6, root, ping6, -c, \d+, -w, \d+, [0-9A-Fa-f:]+
