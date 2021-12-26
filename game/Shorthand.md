# Shorthand

Typing is fustrating (my opinion) so to avoid ridiculously long variable names and overkill commenting here are some common shorthands and what they mean. Beware that sometimes a variable can mean more than one thing depending on the context. Check the context of the variable if you wish to understand its meaning! All of these variables will be scoped (so they won't pe properties or function names).
You're not new to this. You probably already use some of these. The point of this document is to standardize shorthands so as to reduce confusion.
This shorthand documentation is in the rare case you have to revisit old code. If you're writing code that is likely to be visited, you should consider using longer variables, or at least 3-letter shorthands

## i

Index. Used in loops and to iterate through ararys.
Examples:
```swift
for i in array{
    print("Index \(i) corresponds to element \(array[i])")
}
```

Occasionally refers to an *i*tem, although ideally it shouldn't

## a

Doesn't stand for anything. It's simply a very temporary variable that holds an object of any kind. Mainly used in conjunction with _map_ or _filter_ or inside an inline function as the first and only parameter
It's named _a_ usually because it's only used for a couple of lines or if there's only one variable in the whole scope.
In cases where reason for usage isn't super-obvious, a comment should be added to clarify, or it should not be used at all

> Note: Usage is often abused. If you find somewhere that breaks these rules, please tell me so i can remove it.

Example:

```swift
let shooters = self.items.map({a in return a.type == .shooter})
```

```
if let a = calculate(thing){ process(a) }
//a is only used in 1 line
```

## p

Refers to a _Planet_ (or a point)

## o

Rare. refers to an object. Should be using `obj`

## m

Mass

## r

Radius / Rotation (Needs seperating. Please tell me if you have a better shorthand for either of them)

## s

Sector

## t

A time period

## d

A distance. Occasionally used as a temporary variable for holding data

## g or l

Don't use this varaible name. If you find one please tell me so i can change it.
l can sometimes refer to a length.
g is just as obscure as a.

## z (in js)

A rotation. 2D Rotations are often attributed the letter z.
Swift, however, prefers the longer name zRotation so i have honored that.

## w / h

width / height. Generally used together

## x / y

X and Y position. Generally used together

## n

Either a node or a number. Since nodes and numbers are very different you should be able to differenciate them with ease.

## M

A variable used when calculating gravity

## dir

A direction

## obj

an object. In JS this can also refer to a base object (aka dictionary)

## c

A child

## r / g / b

When used together, red, green and blue (used for colors)

## err

an Error

## arr

an Array

## cam

Camera

## id

An ID of an object. Not to be confused with index


