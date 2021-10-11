typealias arr[a] = int a[\0]
typealias str = arr[char]
typealias obj = float float float float byte byte short

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
Client: PDATA [ship]
        (5 obj)
Server: PDATA [ships]
        (6 arr[obj])
[end]

End:
Client: DISC
        (127)

Client: SECMOV [x] [y]
        (7 float float)
Server: OKTHEN [sector]
        (2 int)

Server: DISC [reason]
        (127 str)