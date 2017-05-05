//
//  EquatorialCoordinate.swift
//  SpaceTime
//
//  Created by Sihao Lu on 1/3/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import MathUtil

public struct EquatorialCoordinate {
    public let distance: Double

    /// Right ascension in radians
    public let rightAscension: Double

    /// Declination measured north or south of the celestial equator, in radians
    public let declination: Double

    // http://www.geom.uiuc.edu/docs/reference/CRC-formulas/node42.html
    public init(cartesian vec: Vector3) {
        distance = sqrt(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z)
        declination = Double.pi / 2 - acos(vec.z / distance)
        rightAscension = wrapAngle(atan2(vec.y, vec.x))
    }

    public init(rightAscension: Double, declination: Double, distance: Double) {
        self.rightAscension = wrapAngle(rightAscension)
        self.declination = declination
        self.distance = distance
    }
}

public extension Vector3 {
    public init(equatorialCoordinate coord: EquatorialCoordinate) {
        self.init(
            coord.distance * sin(coord.rightAscension) * cos(coord.declination),
            coord.distance * sin(coord.rightAscension) * sin(coord.declination),
            coord.distance * cos(coord.rightAscension)
        )
    }
}

public extension EquatorialCoordinate {
    //
    // ra1, dec1: RA, dec coordinates, in radians, for EPOCH1, where the epoch is in years AD.
    // Output: [RA, dec], in radians, precessed to EPOCH2, where the epoch is in years AD.
    //
    // Original comment:
    // Herget precession, see p. 9 of Publ. Cincinnati Obs., No. 24.
    //
    func precessed(from epoch1: Double, to epoch2: Double) -> EquatorialCoordinate {
        let (ra1, dec1) = (rightAscension, declination)
        var a, b, c: Double
        let cdr = Double.pi / 180.0
        let csr = cdr / 3600.0
        a = cos(dec1)
        let x1 = Vector3(a * cos(ra1), a * sin(ra1), sin(dec1))
        let t = 0.001 * (epoch2 - epoch1)
        let st = 0.001 * (epoch1 - 1900.0)
        a = csr * t * (23042.53 + st * (139.75 + 0.06 * st) + t * (30.23 - 0.27 * st + 18.0 * t))
        b = csr * t * t * (79.27 + 0.66 * st + 0.32 * t) + a
        c = csr * t * (20046.85 - st * (85.33 + 0.37 * st) + t * (-42.67 - 0.37 * st - 41.8 * t))
        let r = Matrix3.init(
            cos(a) * cos(b) * cos(c) - sin(a) * sin(b),
            -cos(a) * sin(b) - sin(a) * cos(b) * cos(c),
            -cos(b) * sin(c),
            sin(a) * cos(b) + cos(a) * sin(b) * cos(c),
            cos(a) * cos(b) - sin(a) * sin(b) * cos(c),
            -sin(b) * sin(c),
            cos(a) * sin(c),
            -sin(a) * sin(c),
            cos(c)
        ).transpose
        let x2 = r * x1
        return EquatorialCoordinate(rightAscension: atan2(x2.y, x2.x), declination: asin(x2.z), distance: distance)
    }
}
