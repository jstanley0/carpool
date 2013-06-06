# carpool

*A quick-and-dirty carpool tracker in a mobile-friendly web app*

## Motivation

I and several co-workers live farther than we'd like from the office,
and we like to save on gas money and get free express-lane use by
carpooling.  However, our schedules don't always allow this and it 
can get cumbersome to remember whose turn it is to drive.

Other carpooling apps I've seen use GPS and your car's make and model
to determine the dollar value each passenger owes the driver.  They may
even help organize ad-hoc rides.  This isn't what we're looking for, though;
we're not interested in exchanging money, just sharing the burden.

Our company had a "hackstravaganza" event where we could work on whatever
project for a few days, so I took the opportunity to start this one.
As a hack-project, it's not as well-organized as I'd like, but I did take
some time afterward to clean it up a little and add tests...

## Algorithm

We wanted something that would be resilient to changes, and would not
penalize anyone for not participating.  That is, what you get out is
proportional to what you put in.

A bit of searching turned up [an academic paper](http://researcher.watson.ibm.com/researcher/files/us-fagin/ibmj83.pdf)
that described a suitable algorithm.  The gist of it is as follows:
* A ride has a fixed cost (e.g., 12 units, which lets us do integer math when there are 2, 3, or 4 participants)
* The "fare" for each participant is this cost divided by the number of participants on that day
* Each passenger "pays" the fare to the driver
* On a given day, the participant with the lowest balance drives.
* I added another criterion: in the event of a tie, whoever drove least recently is assigned.

**Example:**

 * Alice = 0, Bob = 0, Carol = 0.  Anyone can drive; we'll pick Alice.
 * Alice = 8, Bob = -4, Carol = -4.  It's between Bob or Carol.  We'll pick Bob.
 * Alice = 4, Bob = 4, Carol = -8.  It's Carol's turn.
 * Alice = 0, Bob = 0, Carol = 0.  After the last ride, everyone is square.  We'll pick Alice because she drove least recently.

Now let's watch what happens when someone misses a day (continuing the previous example):

* Alice = 8, Carol = -4.  Bob's out for the day, so it's Carol's turn. (Note that balances move by 12 / 2 = 6 instead of 4 this time.)
* Alice = 2, Bob = -4, Carol = 2.  Now the scheduler picks Bob.
* Alice = -2, Bob = 4, Carol = -2.  Alice drives because Carol drove more recently.

We fall into a different rotation order, but continue to spread the load evenly.

## Setup

* Create users
* Create car pool(s)
 * Set which weekdays the car pool operates (default M-F)
 * Set exceptions (days the carpool does not operate, such as holidays)
 * Set overrides (days the carpool operates outside the normal weekly schedule)
 * Add users
* Set user schedules
 * Each user can click the calendar icon next to the carpool on the front
   page to set his or her own days of participation in the carpool (e.g.,
   excluding Tuesdays and an upcoming holiday trip)

## Daily operation

* A list of all carpools you are a member of shows on your home page.
 * Each carpool shows recent history (including balances for each driver),
   and a list of upcoming rides.
 * You can click "Out" or "In" next to a ride to remove or add yourself from
   participation for a single day.  The list adjusts itself.
 * On the day you drive, click the "Record" link to tell the app what
   happened that day.  The app will select the driver and passengers as
   the algorithm picks by default, but you can make changes.
 * You can also edit the most recent ride if you mis-enter it, but the app
   does not currently let you go back in time beyond the most recent ride.

## Limitations

Features I intend to add someday include:
* Email/SMS notifications
* Confirmation of rides, visible to others
* Transfering credits between drivers (e.g., "I'll buy you lunch if you take my turn tomorrow.")
* Some kind of permission structure (everyone is an admin currently)

## Bugs

* There are some issues surrounding removing a driver from a car pool:
 * Historic balance is lost
 * Recent rides display is kind of broken
 * The sum-to-zero property of each driver's balance is broken

## Technical info

This is a pretty boring Rails 3.2 bundler application.

Authentication is done by HTTP Digest, because it's less
terrible than Basic when I don't feel like coming up with
an SSL certificate.

You'll have to use the console to create your first user:
```ruby
u = User.new name: 'whatever'
u.password = u.password_confirmation = 'password1'
u.save!
```

This uses Bootstrap for the user interface, and the tiniest amount of Javascript
possible.  It's pretty much Web 1.0.  I should probably redo the whole UI in this
week's new hotness JS framework.