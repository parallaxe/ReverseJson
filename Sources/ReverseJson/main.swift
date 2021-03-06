//
//  main.swift
//  ReverseJson
//
//  Created by Tom Quist on 07.02.16.
//  Copyright © 2016 Tom Quist. All rights reserved.
//

import Foundation

enum ProgramResult {
    case Success(String)
    case Failure(String)
}

func usage() -> String {
    let command = Process.arguments[0].characters.split("/").last.map(String.init) ?? ""
    return [
        "Usage: \(command) (swift|objc) NAME FILE <options>",
        "e.g. \(command) swift User testModel.json <options>",
        "Options:",
        "   -c,  --class            Swift: Use classes instead of structs for objects",
        "   -ca, --contiguousarray  Swift: Use ContiguousArray for lists",
        "   -m,  --mutable          Swift: All object fields are mutable (var instead of let)",
        "   -pt, --publictypes      Swift: Make type declarations public instead of internal",
        "   -pf, --publicfields     Swift: Make field declarations public instead of internal",
    ].joinWithSeparator("\n")
}

func main(args: [String]) -> ProgramResult {
    guard args.count >= 4 else {
        return .Failure(usage())
    }
    let language = args[1]
    let name = args[2]
    let file = args[3]
    let remainingArgs = args.suffixFrom(4).map {$0}
    let translatorTypes: [ModelTranslator.Type]
    switch language {
    case "swift":
        translatorTypes = [SwiftTranslator.self]
    case "objc":
        translatorTypes = [ObjcModelCreator.self]
    default:
        return .Failure("Unsupported language \(language)")
    }
    guard let data = NSData(contentsOfFile: file) else {
        return .Failure("Could not read file \(file)")
    }
    
    let model: Any
    do {
        model = try NSJSONSerialization.JSONObjectWithData(data, options: [])
    } catch {
        return .Failure("Could not parse json: \(error)")
    }
    let rootType: ModelParser.FieldType
    do {
        rootType = try ModelParser().decode(model)
    } catch {
        return .Failure("Could convert json to model: \(error)")
    }
    let translators = translatorTypes.lazy.map { $0.init(args: remainingArgs) }
    return .Success(translators.map { $0.translate(rootType, name: name) }.joinWithSeparator("\n\n"))
}


switch main(Process.arguments) {
case let .Success(output):
    print(output)
    exit(0)
case let .Failure(output):
    print(output)
    exit(1)
}
