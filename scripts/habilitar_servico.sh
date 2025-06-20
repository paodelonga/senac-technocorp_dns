#!/bin/bash

systemctl enable bind9 &&
systemctl restart bind9 &&
systemctl status bind9
