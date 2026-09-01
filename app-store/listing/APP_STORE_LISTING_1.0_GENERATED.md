# App Store listing — Rain Tracker

Copy for the App Store Connect listing, drafted from the app's features and
decisions made in earlier working sessions.

---

## App Name (max 30 characters)

> ⚠️ The public App Store name must be globally unique, and plain **"Rain Tracker"**
> is already taken. This does **not** affect the home‑screen name (that stays
> "Rain Tracker" via the target's Bundle Display Name). Pick one:

| Option | Chars |
| --- | --- |
| **Rain Tracker: Rain Gauge Log** *(recommended)* | 28 |
| Rain Tracker – Rainfall Log | 27 |
| Rain Tracker: Backyard Rainfall | 31 ❌ (too long) |
| My Rain Gauge: Rainfall Log | 27 |

## Subtitle (max 30 characters)

> **Log your backyard rain gauge** *(recommended, 28)*

Alternates:
- Track rainfall from your gauge (29)
- Private rain gauge journal (26)

## Promotional Text (max 170 characters, editable any time without review)

> A fast, private way to log every reading from your backyard rain gauge, then
> watch your monthly and yearly totals add up. Free — no ads, no subscriptions.

## Keywords (max 100 characters, comma‑separated, no spaces)

> `rainfall,precipitation,weather,pluviometer,garden,farm,ranch,gardening,widget,journal,rainwater`

(95 chars. Words already in the name/subtitle — rain, gauge, tracker, log — are
indexed automatically, so they're left out here.)

## Description (max 4000 characters)

```
Rain Tracker is a simple, private log for the rain that actually lands in your yard. If you keep a backyard rain gauge, this is the fastest way to record each reading and watch your totals add up over the month, the year, and the years to come.

No account. No ads. No subscriptions. Your readings stay on your device and sync privately through your own iCloud.

LOG A READING IN SECONDS
- Enter an amount, pick the date, and you're done
- Optionally note the time of day — night, morning, afternoon, or evening — or turn that off completely
- Works in inches or millimeters
- Edit or delete any past reading

SEE YOUR TOTALS
- Running totals for the current month and year on the main screen
- Filter your history to the last 30 days, the current year, or everything

CALENDAR VIEW
- A month-at-a-glance grid with the rainfall total on every day it rained
- Month total, number of rainy days, average per rainy day, and the rainiest day of the month
- Swipe between months, or jump straight back to today

YEARLY STATISTICS
- Totals, rainy days, and averages for any year you've tracked
- A monthly bar chart that highlights your wettest month
- Swipe between years

WIDGETS AND CONTROLS
- Home Screen widgets for today's rain plus month and year totals
- A large widget showing the whole month's rainfall by day
- A one-tap "Log Rain" widget, and a Control Center and Lock Screen button

SIRI AND SHORTCUTS
- Ask Siri to log a measurement, or to read back your total for today, this month, or this year
- Build your own automations with the Shortcuts app

YOUR DATA, YOUR CONTROL
- Private iCloud sync keeps your iPhone and iPad in step, with no account to create
- Export everything to a CSV file for backup, or import readings from a file
- Delete all your data whenever you want

Made for iPhone and iPad, in light and dark mode.

Rain Tracker is free, and every feature is available to everyone. If it earns a place on your Home Screen, there's a tip jar tucked in Settings — thank you.
```

## What's New (version 1.0 release notes)

```
This is the first release of Rain Tracker. Thanks for giving it a try!

Have a question or an idea? Tap "Contact Developer" in Settings — I'd love to hear from you.
```

---

## App Store Connect metadata

| Field | Value |
| --- | --- |
| Primary category | Weather |
| Secondary category | Utilities |
| Age rating | 4+ |
| Price | Free |
| In‑app purchases | Small Tip / Medium Tip / Large Tip (consumable) |
| Marketing URL | https://nhaberman.github.io/rain-tracker-app |
| Support URL | https://nhaberman.github.io/rain-tracker-app/support |
| Privacy Policy URL | https://nhaberman.github.io/rain-tracker-app/privacy-policy |
| Copyright | 2026 Nick Haberman |

### App Privacy questionnaire
The app collects nothing. Readings are stored on‑device and synced only through
the user's private iCloud (CloudKit private database), which is not accessible to
the developer. No analytics, no tracking, no third‑party SDKs → answer
**"Data Not Collected."**

### Still needed before submitting (not listing text)
- Decide the final App Store name (above).
- Screenshots: 6.9" iPhone (1290×2796 or 1320×2868) and 13" iPad (2064×2752),
  since the app is universal. Capture Measurements, Calendar, Statistics, and a
  widget on the Home Screen.
- Attach a build, and submit the three tip IAPs alongside version 1.0.
- Complete the EU "Trader" declaration (required now that there are paid IAPs).

---

## Feature inventory (source of truth for the copy above)

- **Logging:** amount + date + optional time of day (Night/Morning/Afternoon/
  Evening, auto‑suggested from the clock); inches or millimeters; edit and delete;
  Time‑of‑Day field can be disabled globally. (`AddObservationView.swift`,
  `MeasurementsView.swift`, `RainObservation.swift`, `SettingsView.swift`)
- **Measurements tab:** month + year running totals; filter Last 30 Days /
  Current Year / All; grouped by month. (`MeasurementsView.swift`)
- **Calendar tab:** month grid with per‑day totals; swipe / month‑year picker /
  Today button; month total, rainy days, avg per rainy day, rainiest day.
  (`CalendarView.swift`)
- **Statistics tab:** per‑year total, rainy days, avg per rainy day, rainiest day;
  monthly bar chart with wettest month highlighted; monthly breakdown; swipe
  between years. (`StatisticsView.swift`)
- **Widgets:** today+month+year (small/medium), month+year (small), month
  calendar by day (large), one‑tap Log Rain (small); Control Center / Lock Screen
  Log Rain control. (`RainTrackerWidget.swift`)
- **Siri / App Shortcuts:** Log Rain Amount, Get Rain Total (today/month/year),
  open‑to‑log intent. (`RainShortcuts.swift`, `RainStore.swift`)
- **Sync & data:** private CloudKit sync across devices; CSV import (merge or
  replace) and export; delete‑all. (`RainStore.swift`, `SettingsView.swift`)
- **Platform:** universal iPhone/iPad, iPadOS sidebar, landscape, pointer/hover
  support, light/dark. (`ContentView.swift`, and hover work across views)
- **Pricing:** free, no ads, no subscriptions, optional tip jar.
  (`TipJarView.swift`)
- **Deployment target:** iOS / iPadOS 26.2. (`project.pbxproj`)
