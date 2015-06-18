# SwiftExP

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/mrackwitz/SwiftExP/blob/master/LICENSE)

This is an S-expression parser written in pure Swift 2.0, where _pure_ means without making any necessary usage of Foundation APIs at its core. This means: neither `NSScanner`, nor `NSRegularExpression`, nor `NSCharacterSet`, not even `NSString`.

[S-expressions](https://en.wikipedia.org/wiki/S-expression) is a notation format for nested list data on which Lisp languages are based.

## Architectural / Paradigm Considerations

While S-expressions have a very simple base syntax and there are appealing approaches on using a functional-compositional style to implement a parser in general in Swift, this implementation goes a different way. It is imperative and makes intense usage of Swift specific features, in particular Optionals, the try/throw/do-catch error handling and mutating functions on value types.

The top-down `Parser` operates without prior Lexing directly on the String through `Scanner`, which is a minimalistic attempt to wrap access on a Character-oriented basis. The current state is given at any time through the call-stack, which also means that the implementation is heavily based on recursion.
