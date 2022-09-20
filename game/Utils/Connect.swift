//
//  Connect.swift
//  game
//
//  Created by BlobKat on 06/07/2021.
//
import Foundation
import Network
import GameKit

func connect(_ host: String, _ a: @escaping (Data) -> ()) -> (Data) -> (){
    var connection: NWConnection?
    var r = host.split(separator: ":")
    if r.count == 1{r.append("65152")}
    let port = NWEndpoint.Port(integerLiteral: UInt16(r[1]) ?? 65152)
    let host = NWEndpoint.Host(stringLiteral: String(host.split(separator: ":")[0]))
    var queue: [Data] = []
    var ready = false
    var c = {(_:Data?,_:NWConnection.ContentContext?,_:Bool,_:NWError?)in}
    c = { (data, _, isComplete, err) in
        dataUsage += data?.count ?? 0
        if isComplete && data != nil{
            DispatchQueue.main.async{a(data!)}
        }
        if err == nil{
            connection?.receiveMessage(completion: c)
        }else{
            (skview.scene as? Play)?.end()
            dmessage = "Connection Ended"
            DispatchQueue.main.async{Disconnected.renderTo(skview)}
        }
    }
    connection = NWConnection(host: host, port: port, using: .udp)
    connection?.stateUpdateHandler = { (newState) in
        let p = skview.scene as? Play
        switch (newState) {
            case .ready:
                ready = true
                DispatchQueue.main.async{for data in queue{
                    dataUsage += data.count + 24
                    connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
                        if NWError != nil {
                        }
                    })))
                }
                connection?.receiveMessage(completion: c)}
            case .cancelled:
            ready = false
                p?.end()
                dmessage = "Connection Interrupted"
                DispatchQueue.main.async{Disconnected.renderTo(skview)}
            case .failed(_):
                ready = false
                p?.end()
                dmessage = "Disconnected!"
                DispatchQueue.main.async{Disconnected.renderTo(skview)}
            default:break
        }
    }
    connection?.start(queue: .global(qos: .background))
    return { (_ data: Data) -> () in
        guard ready else {queue.append(data);return}
        dataUsage += data.count + 24
        bg{connection?.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(({ (NWError) in
            if NWError != nil {
            }
        })))}
    }
}
func fetch<json: Decodable>(_ url: String, _ done: @escaping (json) -> (), _ err: @escaping (String) -> ()){
    guard let uri = URL(string: url) else{
        err("Invalid URL")
        return
    }
    dataUsage += url.count + 200 //approx. overhead
    URLSession.shared.dataTask(with: uri) {(data, response, error) in
        dataUsage += (data?.count ?? 0) + 300 //approx. overhead
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
        DispatchQueue.main.async{err("Invalid URL")}
        return
    }
    dataUsage += url.count + 200 //approx. overhead
    URLSession.shared.dataTask(with: uri) {(data, response, error) in
        dataUsage += (data?.count ?? 0) + 300 //approx. overhead
        if error != nil{
            DispatchQueue.main.async{err(error!.localizedDescription)}
        }else{
            let txt = String(data: data ?? Data(), encoding: String.Encoding.utf8) ?? ""
            DispatchQueue.main.async{done(txt)}
        }
    }.resume()
}
func fetch(_ url: String, _ done: @escaping (Data) -> (), _ err: @escaping (String) -> ()){
    guard let uri = URL(string: url) else{
        DispatchQueue.main.async{err("Invalid URL")}
        return
    }
    dataUsage += url.count + 200 //approx. overhead
    URLSession.shared.dataTask(with: uri) {(data, response, error) in
        dataUsage += (data?.count ?? 0) + 300 //approx. overhead
        if error != nil{
            DispatchQueue.main.async{err(error!.localizedDescription)}
        }else{
            DispatchQueue.main.async{done(data ?? Data())}
        }
    }.resume()
}
