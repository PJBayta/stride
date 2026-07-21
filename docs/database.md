# Database

The application stores all data locally.

## Activities

ActivityID

ActivityType

StartTime

EndTime

Duration

Distance

AvgSpeed

AvgPace

Calories

CreatedAt

## GPSPoints

GPSPointID

ActivityID

Latitude

Longitude

Altitude

Timestamp

## Settings

SettingKey

SettingValue

## Relationships

Activities

↓

GPSPoints

One Activity

↓

Many GPS Points