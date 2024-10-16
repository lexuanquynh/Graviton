//
//  CityManager.swift
//  Graviton
//
//  Created by Sihao Lu on 8/2/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import CoreLocation
import SQLite
import UIKit

typealias Expression = SQLite.Expression

private let conn = try! Connection(Bundle.main.path(forResource: "cities", ofType: "sqlite3")!)
private let cities = Table("cities")

private let citiesLat = Expression<Double>("lat")
private let citiesLng = Expression<Double>("lng")
private let citiesName = Expression<String>("city")
private let citiesPop = Expression<Double>("pop")
private let citiesCountry = Expression<String>("country")
private let citiesProvince = Expression<String?>("province")
private let citiesIso2 = Expression<String>("iso2")
private let citiesIso3 = Expression<String>("iso3")

private let usStates = Table("us_states")
private let usStatesAbbrev = Expression<String>("abbreviation")
private let usStatesName = Expression<String>("name")

struct City: Equatable {
    let coordinate: CLLocationCoordinate2D
    let name: String
    let country: String
    let province: String?
    let iso2: String
    let iso3: String

    var provinceAbbreviation: String? {
        guard let province = province else {
            return nil
        }
        return try! conn.pluck(usStates.select(usStatesAbbrev).where(province == usStatesName))?.get(usStatesAbbrev)
    }

    static func == (lhs: City, rhs: City) -> Bool {
        return lhs.name == rhs.name && lhs.province == rhs.province && lhs.country == rhs.country
    }
}

class CityManager {
    static let `default` = CityManager()

    /// User chosen currently located city. Can be `nil` to use GPS data.
    var currentlyLocatedCity: City? {
        didSet {
            if let city = currentlyLocatedCity {
                let location = CLLocation(latitude: city.coordinate.latitude, longitude: city.coordinate.longitude)
                LocationManager.default.locationOverride = location
            } else {
                LocationManager.default.locationOverride = nil
            }
        }
    }

    static func fetchCities(withNameContaining substr: String? = nil, minimumPopulation: Double = 100_000) -> [City] {
        let filterClause = substr == nil ? citiesPop >= minimumPopulation : citiesPop >= minimumPopulation && citiesName.like("%\(substr!)%")
        let query = cities.select(citiesLat, citiesLng, citiesName, citiesCountry, citiesProvince, citiesIso2, citiesIso3).filter(filterClause).order(citiesName)
        return try! conn.prepare(query).map { (row) -> City in
            City(coordinate: CLLocationCoordinate2D(latitude: try! row.get(citiesLat), longitude: try! row.get(citiesLng)), name: try! row.get(citiesName), country: try! row.get(citiesCountry), province: try! row.get(citiesProvince), iso2: try! row.get(citiesIso2), iso3: try! row.get(citiesIso3))
        }
    }
}
