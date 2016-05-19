import re

clients = open("Clients.csv", 'r')
result = open("Valid clients.csv", 'w')

for line in clients:
    p = re.compile("^[0-9]{1,4};[\s\S\b^;]{1,20};[\s\S\b^;]{1,12};\d{0,1};\d{0,11}$")
    m = p.match(line)
    if m:
        result.write(m.group() + '\n')

result.close()
clients.close()
