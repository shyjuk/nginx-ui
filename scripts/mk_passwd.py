from passlib.hash import sha256_crypt
import sys

password = sys.argv[1] 
print(sha256_crypt.hash(password))