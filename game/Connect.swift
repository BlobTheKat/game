//
//  Connect.swift
//  game
//
//  Created by BlobKat on 06/07/2021.
//
import Foundation
import Network

var dmessage = "Disconnected!"
let ADAM = false
func connect(_ host: String = "192.168.1.\(ADAM ? 248 : 64):65152", _ a: @escaping (Data) -> ()) -> (Data) -> (){
    var connection: NWConnection?
    let port = NWEndpoint.Port(integerLiteral: UInt16(host.split(separator: ":")[1])!)
    let host = NWEndpoint.Host(stringLiteral: String(host.split(separator: ":")[0]))
    var queue: [Data] = []
    var ready = false
    var c = {(_:Data?,_:NWConnection.ContentContext?,_:Bool,_:NWError?)in}
    c = { (data, _, isComplete, _) in
        if isComplete && data != nil{
            a(data!)
        }
        connection?.receiveMessage(completion: c)
    }
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
                connection?.receiveMessage(completion: c)
            case .cancelled:
                dmessage = "Connection Interrupted"
                DispatchQueue.main.async{Disconnected.renderTo(skview)}
            case .failed(_):
                dmessage = "Could not connect to server"
                DispatchQueue.main.async{Disconnected.renderTo(skview)}
            default:break
        }
    }
    connection?.start(queue: .global(qos: .background))
    return { (_ data: Data) -> () in
        guard ready else {queue.append(data);return}
        bg{connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if NWError != nil {
                print("ERROR! Error when sending Data:\n \(NWError!)")
            }
        })))}
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
    }.resume()
}
func fetch(_ url: String, _ done: @escaping (String) -> (), _ err: @escaping (String) -> ()){
    guard let uri = URL(string: url) else{
        err("Invalid URL")
        return
    }
    URLSession.shared.dataTask(with: uri) {(data, response, error) in
        if error != nil{
            err(error!.localizedDescription)
        }else{
            done(String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? "")
        }
    }.resume()
}

enum ProtocolError: Error{
    case valueTooLarge(msg: String)
    case invalidCase(msg: String)
    case serverUnhappy(msg: String)
    case missingValue(msg: String)
}

struct M{
    enum msg: UInt8{
        case hello = 0
        case keepalive = 1
    }
    func hello(name: String) throws -> Data{
        if name.count > 64{throw ProtocolError.valueTooLarge(msg: "name cannot be longer than 64 characters")}
        var data = Data([])
        guard case .number(let v) = map.header["version"] else {throw ProtocolError.missingValue(msg: "version not set")}
        data.write(UInt16(v))
        data.write(msg.hello)
        data.write(name)
        return data
    }
}
let messages = M()


struct api{
    static func sector(completion: @escaping (UInt32) -> ()){
        completion(0)
    }
}
