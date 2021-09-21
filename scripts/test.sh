#!/bin/bash
PASS='shyju'

c=`cat <<EOF
from passlib.hash import sha256_crypt
import sys

password = sys.argv[1] 
print(sha256_crypt.hash(password))
EOF`

PHASH=`python3 -c "$c" $PASS`

echo $PHASH