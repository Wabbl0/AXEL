# Ticket machine unlock (2026-10-15)

## Request

The ticket machine in `1.3_LockerHub` opens only after the first floor-item fight. A hint line tells the player about it. On later runs it is open from the start.

## Built

- `AxelProfile.is_ticket_machine_unlocked()` / `unlock_ticket_machine()`: profile flag `ticket_machine_unlocked`, kept across runs (cleared only by `reset_profile`).
- `AxelRun.ticket_machine_open()`: true when the profile flag is set, or the run already has bought or held tickets (old saves).
- `AxelWorld.notify_fight_won`: a won `item_pickup` fight sets the flag. The first time, it queues three white inner-voice lines shown back in the room (same wait-until-free logic as the deep-air line):
  - "That one's yours now. No taking it back."
  - "But the next one doesn't have to be."
  - "The ticket machine by your locker sells rerolls."
- `1.3_LockerHub`: the panel stays hidden until `ticket_machine_open()`.
- Check: `tools/qa/ticket_machine_check.gd` covers locked / walk fight / item fight / next run / hub visibility.

## Needs playtest

The hint lines after the first item fight, and the panel showing on the next locker visit.
