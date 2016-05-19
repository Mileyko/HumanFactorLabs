clients = open("Valid clients.csv", 'r')
ok = True

for line in clients:
    lineOk = True
    fields = line.split(";")

    # 1
    ID = fields[0]
    if (not ID) or len(ID) > 4 or (not ID.isdigit()):
        lineOk = False

    # 2
    FIO = fields[1]
    if (not FIO) or len(FIO) > 20:
        lineOk = False

    # 3
    Document = fields[2]
    if (not Document) or len(Document) > 12:
        lineOk = False

    # 4
    Type_phone = fields[3]
    if len(Type_phone) > 1 or (Type_phone and not Type_phone.isdigit()):
        lineOk = False

    # 5
    Phone = fields[4].strip()
    if len(Phone) > 11 or (Phone and not Phone.isdigit()):
        lineOk = False

    ok = ok and lineOk

clients.close()

print ok
