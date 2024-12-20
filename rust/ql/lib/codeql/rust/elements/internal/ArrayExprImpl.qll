/**
 * This module provides a hand-modifiable wrapper around the generated class `ArrayExpr`.
 *
 * INTERNAL: Do not use.
 */

private import codeql.rust.elements.internal.generated.ArrayExpr

/**
 * INTERNAL: This module contains the customizable definition of `ArrayExpr` and should not
 * be referenced directly.
 */
module Impl {
  // the following QLdoc is generated: if you need to edit it, do it in the schema file
  /**
   * An array expression. For example:
   * ```rust
   * [1, 2, 3];
   * [1; 10];
   * ```
   */
  class ArrayExpr extends Generated::ArrayExpr {
    override string toString() { result = "[...]" }
  }
}
