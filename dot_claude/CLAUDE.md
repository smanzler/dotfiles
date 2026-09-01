# Claude Instructions

## Inline Code Comments

- Write no comment by default
- Comment only what the code cannot show: a constraint, an upstream bug, a necessary order, a unit, or a deliberate deviation
- Do not repeat the code or a name
- Do not add a banner, a divider, or a changelog
- Do not describe your change; the diff shows it
- Delete a comment when it becomes wrong or unnecessary
- Give the constraint, not the story

## Comment style:

- Write every comment in ASD-STE100 (Simplified Technical English)
- Prefer simple verbs: use, make, get, put, remove, start, stop, keep, find, send

## Writing doc blocks:

- A doc block tells the caller how to use the symbol
- Exclude why the symbol exists, what it replaced, a rejected option, a ticket, a link, and a name
- Write no doc block when the name and the signature are clear
- Do not repeat a type that the language declares
- Add a `@param` line only when the name does not give the constraint
