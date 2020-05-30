# EasyTimer

## Shareable and Synchronized

With this web application, you can create live countdown timers to share with others.

## Options

- Hours, minutes, seconds (limit to 24 hours)
- A public web link to share with anyone
- Play, pause, stop, next, and previous controls (admins only)
- Share admin control via a PIN code
- **Quick**: single
- **Custom**: multiple named timers in a series

## App Notes

- The application works, but the UI is unpolished.
- Timers are live for 24 hours before deletion
- Custom, multi-phase timers currently require setup by uploading a CSV file. Future versions may support web forms.

## Stack

- Elixir Phoenix application without no database
- RESTful homepage and setup pages
- Dynamic client/server interaction via Phoenix LiveView
- Tailwind CSS

## Dev Notes

- Tailwind configured for Phoenix via [phoenix-config-for-tailwind](https://github.com/jfreeze/phoenix-config-for-tailwind)
- UI debugging for visual styling is done via alternating nested "dbr" (debug border red) and "dbb" (debug border blue) classes, that can be activated/deactivated manually by commenting out the "@import './dev.css'" statement in: "assets/css/app.css"
