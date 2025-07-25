## /tg/station Events Base

This repository is a descendant of the "events base". The events base is **modular**, meaning **you should avoid editing code in the code folder itself.**

[![resentment](.github/images/badges/built-with-resentment.svg)](.github/images/comics/131-bug-free.png) [![technical debt](.github/images/badges/contains-technical-debt.svg)](.github/images/comics/106-tech-debt-modified.png) [![forinfinityandbyond](.github/images/badges/made-in-byond.gif)](https://www.reddit.com/r/SS13/comments/5oplxp/what_is_the_main_problem_with_byond_as_an_engine/dclbu1a)

<<<<<<< HEAD
| Website                   | Link                                           |
|---------------------------|------------------------------------------------|
| Website                   | [https://www.tgstation13.org](https://www.tgstation13.org)          |
| Code                      | [https://github.com/tgstation/tgstation](https://github.com/tgstation/tgstation)    |
| Wiki                      | [https://tgstation13.org/wiki/Main_Page](https://tgstation13.org/wiki/Main_Page)   |
| Codedocs                  | [https://codedocs.tgstation13.org/](https://codedocs.tgstation13.org/)       |
| /tg/station Discord       | [https://tgstation13.org/phpBB/viewforum.php?f=60](https://tgstation13.org/phpBB/viewforum.php?f=60) |
| Coderbus Discord          | [https://discord.gg/Vh8TJp9](https://discord.gg/Vh8TJp9)               |
=======
| Website             | Link                                                                                                 |
| ------------------- | ---------------------------------------------------------------------------------------------------- |
| Website             | [https://tgstation13.org](https://tgstation13.org)                                                   |
| Code                | [https://github.com/tgstation/tgstation](https://github.com/tgstation/tgstation)                     |
| Wiki                | [https://tgstation13.org/wiki/Main_Page](https://tgstation13.org/wiki/Main_Page)                     |
| Codedocs            | [https://codedocs.tgstation13.org/](https://codedocs.tgstation13.org/)                               |
| /tg/station Discord | [https://tgstation13.org/phpBB/viewforum.php?f=60](https://tgstation13.org/phpBB/viewforum.php?f=60) |
| Coderbus Discord    | [https://discord.gg/Vh8TJp9](https://discord.gg/Vh8TJp9)                                             |
>>>>>>> 1b1cc1f668ad88bc1e974844700b37d1d054b6f4

## Adding a new module, where do I do it?

Modules should be individual features/edits, packed into one.

<<<<<<< HEAD
`modular_event` houses two folders: one called `base`, and the other named whatever the event is called. `base` should hold anything that **makes sense and/or is likely to reuse in other events**. For example, multiple events want to limit jobs to only assistant and cyborg. Thus, the `limit_jobs` module exists in `base`. However, only the Toolbox Tournament is interested in running tournaments, so the `tournament` module only exists in `modular_event/toolbox_tournament`.

`_modular_event` exists for one purpose: to run before `code`. Thus, this should only be used for non-modular changes that HAVE to run before `code`. Otherwise, just make your own `__DEFINES` file in your module.
=======
_All github inquiries (such as moderation actions) may be handled via the /tg/station discord [#coding-general](https://discord.com/channels/326822144233439242/326831214667235328). Simply ping the `@Maintainer` role, following the guide on asking questions located in the channel description, with your issue!_

## DOWNLOADING

[Downloading](.github/guides/DOWNLOADING.md)
>>>>>>> 1b1cc1f668ad88bc1e974844700b37d1d054b6f4

## Tips for writing modular code

BYOND overrides are done in the order of which they appear, and you can even override the same proc twice!

For example, let's consider station traits, which look like this:

```dm
/datum/controller/subsystem/processing/station/proc/SetupTraits()
	// Find station traits
	// Initialize some station traits
```

We don't want this in our events, but how do we change it modularly? Well, like this!

```dm
// Avoid putting `proc/` here, since this isn't the base
/datum/controller/subsystem/processing/station/SetupTraits()
	return
```

And...that's it! BYOND will use the latest override.

## I need to make a non-modular change!

If you're confident you cannot make a change without editing something in `code`, do so while explicitly marking where it begins and ends. That way, it's easy for us to handle merge conflicts with `// EVENT EDIT: Description` and `// END EVENT EDIT`.

```dm
some_normal_code()
other_normal_code()
// EVENT EDIT: We needed to do something cool here
do_something_cool_for_event()
// END EVENT EDIT
```

That being said, a lot of non-modular changes *can* be allowed modularly upstream. It's totally fine to add new signals on the tgstation repository that are only registered by events, for example, signals are basically free.

<<<<<<< HEAD
If possible, contact a maintainer (specifically Mothblocks, if she's still around) for help with non-modular code, and especially in the realm of being able to make non-modular code modular through upstream edits.
=======
For lore, [see Common Core](https://github.com/tgstation/common_core).

## LICENSE

All code after [commit 333c566b88108de218d882840e61928a9b759d8f on 2014/31/12 at 4:38 PM PST](https://github.com/tgstation/tgstation/commit/333c566b88108de218d882840e61928a9b759d8f) is licensed under [GNU AGPL v3](https://www.gnu.org/licenses/agpl-3.0.html).

All code before [commit 333c566b88108de218d882840e61928a9b759d8f on 2014/31/12 at 4:38 PM PST](https://github.com/tgstation/tgstation/commit/333c566b88108de218d882840e61928a9b759d8f) is licensed under [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.html).
(Including tools unless their readme specifies otherwise.)

See LICENSE and GPLv3.txt for more details.

The TGS DMAPI is licensed as a subproject under the MIT license.

See the footer of [code/\_\_DEFINES/tgs.dm](./code/__DEFINES/tgs.dm) and [code/modules/tgs/LICENSE](./code/modules/tgs/LICENSE) for the MIT license.

All assets including icons and sound are under a [Creative Commons 3.0 BY-SA license](https://creativecommons.org/licenses/by-sa/3.0/) unless otherwise indicated.
>>>>>>> 1b1cc1f668ad88bc1e974844700b37d1d054b6f4
