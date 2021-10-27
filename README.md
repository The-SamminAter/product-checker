# Product Checker - based on my userrecon_reborn

Made for a friend, but should work for most sites, and could be modified to work on linux (the notification delivery would have to be changed)

Scans are easy to add, check out the existing ones for info on how they work

Accepts a launch argument of how many seconds the script should wait before scanning again - if none is added, defaults to three minutes

### To-do:

- Site presets/configs
- Config file
	- Reading from
	- User interaction (through the script)
		- Adding to (custom or presets)
			- Search and scrape the results?
		- Removing from
		- Setting max price (won't alert if in stock and over that value)
- Price stuff
	- Getting product price
	- Comparing product price to max (if it has one)
