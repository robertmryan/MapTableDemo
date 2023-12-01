#  MapTableDemo

This is a example in response to CodeReview [question](https://codereview.stackexchange.com/q/85819/54422).

 * This is largely an updating of that example to follow modern Swift/GCD convensions.
 * This is a native Swift implementation that manifests the weak-to-strong behavior of [`NSMapTable`](https://developer.apple.com/documentation/foundation/nsmaptable)).
 * This relies heavily on the `HashableWeakBox` implementation. This is the “weak key” which has a `weak` reference to the object, but a persistent hash, and performs some sleight of hand to achieve this. The idea appears to be that if that key is being used in a `Dictionary` already, we better not change the underlying hash, even though the wrapped weak key may become `nil` when the last strong reference is removed. This is too cute by half, IMHO, and does not strike me as a robust/reliable/correct solution.
     In my implementation, in order to retain [`Hashable`](https://developer.apple.com/documentation/swift/hashable/) conformance, I had to retire the deprecated `hashIndex` (as we are supposed to implement `hash(into:)` method). But we cannot save the original value to be re-hashed (the whole idea is that we do not want any strong references to that), so I instead just save the previously hashed value. Obviously, that is not correct (it might not be unique), but was the only way I could see to retain the “allow wrapped reference to become `nil`” and “persistent hash” concepts. But it is wrong.
 * I think the correct solution probably rests in a fundamentally different backing store, not a `Dictionary`. We would also need to hook into the “make ‘weak’ reference nil when there are no more strong references” in order to update our store accordingly. It is an interesting challenge, but given that the whole concept of reference-type keys is a bit unswifty, so I am not going to pursue it further.
 
In short, caveat emptor.

Rob

- - -

Built in Xcode 15.0.1 and Swift 5.9.

- - - 

## License

30 November 2023

Copyright © 2023 Robert M. Ryan. All Rights Reserved.

See [License](LICENSE.md).
