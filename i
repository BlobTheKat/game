typealias arr[a] = int a[\0]
typealias str = arr[char]
typealias obj = float float byte byte byte byte short
typealias arrend[a] = a[MAX]
typealias planet = byte ()[\0]

Client: AUTH [name]
        (0 str)
Server: ACK
        (1)
[loop 1s]
Client: LS_HBEAT
        (3)
Server: LS_HBEAT
        (4)
[end]
[loop 0.1s]
Client: PDATA [ship] ([hitlen] [shot] [namelen]) [hits]? [shot]? [names]?
        (5 obj 3bit bit 4bit int[\2] int[\3] int[\4])
Server: PDATA [ships]
        (6 arrend[obj])

Server: NAMES [strs]
        (8 arrend[str])

Server: PLANETS [planetdata]
        (12 arrend[planet])
[end]


Client: CONONISE ...
        (10 )
Server: OKTHEN ...
        (11 )

End:
Client: DISC
        (127)

Client: SECMOV [x] [y]
        (9 float float)
Server: OKTHEN [sector]
        (2 int)

Server: DISC [reason]
        (127 str)