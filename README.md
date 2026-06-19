# Rain Tracker

A simple iOS app for logging rainfall measurements from a personal rain gauge.

## Features

**Measurements tab**
- Log rain gauge readings with an amount (in inches), date, and optional time of day (Night, Morning, Afternoon, Evening)
- View all readings in a reverse-chronological list with a running total for the current month
- Tap any entry to view details or edit it; swipe to delete

**Calendar tab**
- Browse a monthly calendar with daily rainfall totals shown inline
- Navigate between months with arrows or a month/year picker
- See the month's total rainfall and daily average at a glance

**Settings**
- Toggle the "Time of Day" field on or off globally
- Export all readings to a plain-text CSV file for backup or transfer
- Import readings from a previously exported file — choose to merge with existing data or replace it
- Delete all data with a confirmation prompt

## Data format

Exported files are plain text with one reading per line:

```
yyyy-MM-dd,amount,TimeOfDay
```

Example:
```
2026-06-15,0.75,Morning
2026-06-18,1.20,Evening
```

The same format is accepted on import. The `TimeOfDay` column is optional.

## Requirements

- iOS 17+
- Xcode 15+

## Building

Open `Rain Tracker/Rain Tracker.xcodeproj` in Xcode and run on a simulator or device.

## License

MIT — see [LICENSE](LICENSE).
