//
//  Data.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 02/02/2021.
//

import Foundation

extension Data {

    var imageSource: CGImageSource? {
        return CGImageSourceCreateWithData(self as CFData, nil)
    }

    var imageProperties: [String: Any]? {
        guard let imageSource = imageSource else {
            return nil
        }
        return CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any]
    }

    func set(metadata: Metadata) throws -> Data {

        guard let imageSource = imageSource else {
            throw ManagerError.invalidData
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any] else {
            throw ManagerError.missingProperties
        }

        var mutableProperties = properties
        if var mutableIPTC = (properties[(kCGImagePropertyIPTCDictionary as String)]) as? [AnyHashable: Any] {
            if let title = metadata.title {
                mutableIPTC[kCGImagePropertyIPTCObjectName as String] = title
            }
            if let caption = metadata.caption {
                mutableIPTC[kCGImagePropertyIPTCCaptionAbstract as String] = caption
            }
            mutableProperties[kCGImagePropertyIPTCDictionary] = mutableIPTC
        } else {
            var mutableIPTC: [AnyHashable: String] = [:]
            if let title = metadata.title {
                mutableIPTC[kCGImagePropertyIPTCObjectName as String] = title
            }
            if let caption = metadata.caption {
                mutableIPTC[kCGImagePropertyIPTCCaptionAbstract as String] = caption
            }
            mutableProperties[kCGImagePropertyIPTCDictionary] = mutableIPTC
        }

        guard let uti = CGImageSourceGetType(imageSource) else {
            throw ManagerError.unknownImageType
        }

        let data = NSMutableData()
        let destination: CGImageDestination = CGImageDestinationCreateWithData(data as CFMutableData, uti, 1, nil)!
        CGImageDestinationAddImageFromSource(destination, imageSource, 0, mutableProperties as CFDictionary)
        CGImageDestinationFinalize(destination)

        return data as Data
    }

}
