# subclass of action that makes moving a unit cost a global resource
# a unit type uses at most one move cost (only the first one is read)
class_name MoveCost
extends Action

## Consume subtracts the amount, Require only checks that the player holds it
enum Mode {CONSUME = 0, REQUIRE = 1}

## When the cost is charged. Only per move order exists for now, PER_TILE is reserved for later.
## Stored in the game file so new modes don't break older files.
enum Charge {PER_ORDER = 0}

## Resources are referenced by name, like in ConsumeProduce. "None" means no cost.
@export var cost_resource : String = ConsumeProduce.NO_RESOURCE
@export var amount : int = 0
@export var mode : Mode = Mode.CONSUME
@export var charge : Charge = Charge.PER_ORDER
