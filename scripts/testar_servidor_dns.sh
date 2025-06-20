#!/bin/bash

dig @127.0.0.1 technocorp.emp
dig @127.0.0.1 www.technocorp.emp
dig @127.0.0.1 mail.technocorp.emp MX

nslookup technocorp.emp 127.0.0.1
nslookup ftp.technocorp.emp 127.0.0.1
nslookup mail.technocorp.emp 127.0.0.1
nslookup dhcp.technocorp.emp 127.0.0.1
nslookup dns.technocorp.emp 127.0.0.1
nslookup www.technocorp.emp 127.0.0.1
nslookup -query=mx technocorp.emp 127.0.0.1
