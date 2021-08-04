//
//  Servers.swift
//  game
//
//  Created by BlobKat on 06/07/2021.
//
import Foundation
import Network
struct servers{
    static let uswest = ""
    static let backup = ""
    static let home = "192.168.1.64"
}


func connect(_ host: String = "192.168.1.64:65152", _ a: @escaping (Data) -> ()) -> (Data) -> (){
    var connection: NWConnection?
    let port = NWEndpoint.Port(integerLiteral: UInt16(host.split(separator: ":")[1])!)
    let host = NWEndpoint.Host(stringLiteral: String(host.split(separator: ":")[0]))
    var queue: [Data] = []
    var ready = false
    connection = NWConnection(host: host, port: port, using: .udp)
    connection?.stateUpdateHandler = { (newState) in
        switch (newState) {
            case .ready:
                ready = true
                for data in queue{
                    connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
                        if NWError != nil {
                            print("ERROR! Error when sending Data:\n \(NWError!)")
                        }
                    })))
                }
                connection?.receiveMessage { (data, context, isComplete, error) in
                    if isComplete {
                        a(data ?? Data())
                    }
                }
            default:()
        }
    }
    connection?.start(queue: .global())
    return { (_ data: Data) -> () in
        guard ready else {queue.append(data);return}
        connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if NWError != nil {
                print("ERROR! Error when sending Data:\n \(NWError!)")
            }
        })))
    }
}
func fetch<json: Decodable>(_ url: String, _ done: @escaping (json) -> (), _ err: @escaping (String) -> ()){
    guard let uri = URL(string: url) else{
        err("Invalid URL")
        return
    }
    URLSession.shared.dataTask(with: uri) {(data, response, error) in
        if let error = error{
            err(error.localizedDescription)
            return
        }
        do{
            done(try JSONDecoder().decode(json.self, from: data ?? Data()))
        }catch{
            err("Invalid Response")
        }
    }
}
