-- Reschedule the selected OmniFocus item(s) due date to today, keeping
-- their existing time-of-day (or defaulting to 5pm for items with no
-- due date yet). Triggered by the F13 key; see dot_config/skhd/skhdrc.

set targetDate to my dateAtOffset(0)
my rescheduleSelection(targetDate)

on dateAtOffset(dayOffset)
	return (current date) + (dayOffset * days)
end dateAtOffset

on rescheduleSelection(targetDate)
	tell application "OmniFocus"
		tell front document
			set selectedItems to value of selected trees of content of front document window
			repeat with anItem in selectedItems
				set existingDue to due date of anItem
				if existingDue is not missing value then
					set hh to hours of existingDue
					set mm to minutes of existingDue
				else
					set hh to 17
					set mm to 0
				end if
				set newDue to targetDate
				set time of newDue to (hh * hours) + (mm * minutes)
				set due date of anItem to newDue
			end repeat
		end tell
	end tell
end rescheduleSelection
