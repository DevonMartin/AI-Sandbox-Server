//
//  File.swift
//  
//
//  Created by Devon Martin on 9/24/23.
//

import Vapor

struct RevenueCatPayload: Content {
	let api_version: String
	let event: Event
}

struct Event: Content {
	let aliases: [String]
	let app_id: String
	let app_user_id: String
	let commission_percentage: Double?
	let country_code: String
	let currency: String?
	let entitlement_id: String?
	let entitlement_ids: [String]?
	let environment: String
	let event_timestamp_ms: Int64
	let expiration_at_ms: Int64
	let id: String
	let is_family_share: Bool?
	let offer_code: String?
	let original_app_user_id: String
	let original_transaction_id: String?
	let period_type: String
	let presented_offering_id: String?
	let price: Double?
	let price_in_purchased_currency: Double?
	let product_id: String
	let purchased_at_ms: Int64
	let store: String
	let subscriber_attributes: [String: SubscriberAttribute]
	let takehome_percentage: Double?
	let tax_percentage: Double?
	let transaction_id: String?
	let type: String
}

struct SubscriberAttribute: Content {
	let updated_at_ms: Int64
	let value: String
}
