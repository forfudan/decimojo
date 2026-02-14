# API Reference

## Initialization of BigUInt

There are three issues associated with the initialization of `BigUInt`:

1. The embedded list of words is **empty**. In this sense, the coefficient of the `BigUInt` is **uninitialized**. This situation, in most cases, is not desirable because it can lead to bugs and unexpected behavior if users try to perform arithmetic operations on an uninitialized `BigUInt`. However, in some cases, users may want to create an uninitialized `BigUInt` for performance reasons, e.g., when they want to fill the words with their own values later. Therefore, we can allow users to create an uninitialized `BigUInt` by providing a key-word only argument, e.g., `uninitialized=True`.
1. There are **leading zero words** in the embedded list of words, e.g., 000000000_123456789. This situation is not a safety issue, but it can lead to performance issues because it increases the number of words that need to be processed during arithmetic operations. In some cases, users may want to keep these leading zero words for specific applications, e.g., aligning the number of words for two `BigUInt` operations.
1. The value of a word is greater than **999_999_999**. This situation is a safety issue because it violates the invariant that each word should be smaller than a billion. It can lead to bugs and unexpected behavior if users try to perform arithmetic operations on a `BigUInt` with invalid words.

To make sure that the users construct `BigUInt` safely by default, the default constructor of `BigUInt` will check for these issues so that the `BigUInt` is always non-empty, has no leading zero words, and all words are smaller than a billion. We also allow users, mainly developers, to create unsafe `BigUInt` instances if they want to, but they must explicitly choose to do so by providing a key-word only argument, e.g., `uninitialized=True`, or use specific methods, e.g., `from_list_unsafe()`.

Note: Mojo now supports keyword-only arguments of the same data type.

| Method                                   | non-empty | no leading zero words | all words valid | notes                                  |
| ---------------------------------------- | --------- | --------------------- | --------------- | -------------------------------------- |
| `BigUInt(var words: List[UInt32])`       | ✓         | ✓                     | ✓               | Validating constructor for word lists. |
| `BigUInt(*, uninitialized_capacity=Int)` | ✗         | ?                     | ?               | Length of words list is 0              |
| `BigUInt(*, unsafe_uninit_length=Int)`   | ✗         | ?                     | ?               | Length of words list not 0             |
| `BigUInt(*, raw_words: List[UInt32])`    | ✓         | ✗                     | ✗               |                                        |
| `BigUInt(value: Int)`                    | ✓         | ✓                     | ✓               |                                        |
| `BigUInt(value: Scalar)`                 | ✓         | ✓                     | ✓               | Only unsigned scalars are supported.   |
