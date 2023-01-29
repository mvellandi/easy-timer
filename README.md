# EasyTimer: Shareable Timers

Developed in Spring 2020 with the help of my mentor, Lars Wikman

## Summary

With this web application, you can create live countdown timers with web links to share with anyone.
[See full project details here](http://www.vellandi.net/projects/easy-timer)

## Screenshots

![home screen](img/demo-home.jpg)
![custom timer](img/demo-custom.jpg)
![quick timer setup](img/demo-quick-setup.jpg)
![quick timer setup success](img/demo-quick-setup-success.jpg)
![nonadmin timer](img/demo-nonadmin-timer.jpg)
![enter admin pin](img/demo-timer-admin-pin.jpg)
![admin timer](img/demo-admin-timer.jpg)

## Features

- A public web link to share with anyone in the world
- Setup single or multiple timers in a series.
- Create passcodes to administer a timer from any device, or share control with others
- Select hours, minutes, seconds (limit to 24 hours)
- Play, pause, stop, next, and previous controls (admins only)

## App Notes

- The application works, but the UI is unpolished.
- Timers are live for 24 hours before deletion
- Custom, multi-phase timers currently require setup by uploading a CSV file. Future versions may support web forms.

## Stack

- Elixir Phoenix application with no database
- RESTful homepage and setup pages
- Dynamic client/server interaction via Phoenix LiveView for timers
- Tailwind CSS

## Dev Notes

- Tailwind configured for Phoenix via [phoenix-config-for-tailwind](https://github.com/jfreeze/phoenix-config-for-tailwind)
- UI debugging via alternating nested "db{r,b,g}" debug border red, blue, and grey classes
- UI debugging is activated/deactivated manually by commenting out the "@import './dev.css'" statement in: "assets/css/app.css"

## Bugs

- Nonfunctional "Copy Link" to clipboard button in successful timer creation screen.
