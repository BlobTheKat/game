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

extension SystemDataUsage {

    public static var complete: UInt64 {
        return SystemDataUsage.getDataUsage().wifiSent + SystemDataUsage.getDataUsage().wifiReceived + SystemDataUsage.getDataUsage().wirelessWanDataSent + SystemDataUsage.getDataUsage().wirelessWanDataReceived
    }

}

struct DataUsageInfo {
    var wifiReceived: UInt64 = 0
    var wifiSent: UInt64 = 0
    var wirelessWanDataReceived: UInt64 = 0
    var wirelessWanDataSent: UInt64 = 0

    mutating func updateInfoByAdding(_ info: DataUsageInfo) {
        wifiSent += info.wifiSent
        wifiReceived += info.wifiReceived
        wirelessWanDataSent += info.wirelessWanDataSent
        wirelessWanDataReceived += info.wirelessWanDataReceived
    }
}

class SystemDataUsage {

    private static let wwanInterfacePrefix = "pdp_ip"
    private static let wifiInterfacePrefix = "en"

    class func getDataUsage() -> DataUsageInfo {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var dataUsageInfo = DataUsageInfo()

        guard getifaddrs(&ifaddr) == 0 else { return dataUsageInfo }
        while let addr = ifaddr {
            guard let info = getDataUsageInfo(from: addr) else {
                ifaddr = addr.pointee.ifa_next
                continue
            }
            dataUsageInfo.updateInfoByAdding(info)
            ifaddr = addr.pointee.ifa_next
        }

        freeifaddrs(ifaddr)

        return dataUsageInfo
    }

    private class func getDataUsageInfo(from infoPointer: UnsafeMutablePointer<ifaddrs>) -> DataUsageInfo? {
        let pointer = infoPointer
        let name: String! = String(cString: pointer.pointee.ifa_name)
        let addr = pointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_LINK) else { return nil }

        return dataUsageInfo(from: pointer, name: name)
    }

    private class func dataUsageInfo(from pointer: UnsafeMutablePointer<ifaddrs>, name: String) -> DataUsageInfo {
        var networkData: UnsafeMutablePointer<if_data>?
        var dataUsageInfo = DataUsageInfo()

        if name.hasPrefix(wifiInterfacePrefix) {
            networkData = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            if let data = networkData {
                dataUsageInfo.wifiSent += UInt64(data.pointee.ifi_obytes)
                dataUsageInfo.wifiReceived += UInt64(data.pointee.ifi_ibytes)
            }

        } else if name.hasPrefix(wwanInterfacePrefix) {
            networkData = unsafeBitCast(pointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            if let data = networkData {
                dataUsageInfo.wirelessWanDataSent += UInt64(data.pointee.ifi_obytes)
                dataUsageInfo.wirelessWanDataReceived += UInt64(data.pointee.ifi_ibytes)
            }
        }
        return dataUsageInfo
    }
}


func connect(_ host: String = "192.168.1.\(ADAM ? 248 : 64):65152", _ a: @escaping (Data) -> ()) -> (Data) -> (){
    var connection: NWConnection?
    var r = host.split(separator: ":")
    if r.count == 1{r.append("65152")}
    let port = NWEndpoint.Port(integerLiteral: UInt16(r[1]) ?? 65152)
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
func fetch(_ url: String, _ done: @escaping (Data) -> (), _ err: @escaping (String) -> ()){
    guard let uri = URL(string: url) else{
        err("Invalid URL")
        return
    }
    URLSession.shared.dataTask(with: uri) {(data, response, error) in
        if error != nil{
            err(error!.localizedDescription)
        }else{
            done(data ?? Data())
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
        data.write(msg.hello)
        data.write(UInt16(VERSION))
        data.write(name)
        return data
    }
}
let messages = M()

var secx = 1
var secy = 1

struct api{
    static func sector(completion: @escaping (_ x: Int, _ y: Int) -> ()){
        completion(secx, secy)
    }
}
