/**
 * Provides classes for working with UML diagrams generated by MagicDraw.
 *
 * Diagrams need to be saved in the `.mdxml` or `.xml` format.
 *
 * See [the MagicDraw website](http://www.nomagic.com/products/magicdraw.html)
 * for more information.
 */

import cpp

/**
 * An element of the UML diagram.
 *
 * Includes any XML element that is in a document whose root has namespace
 * `http://schema.omg.org/spec/XMI/2.1`.
 */
class UMLElement extends XMLElement {
  UMLElement() {
    this.getFile().getARootElement().getNamespace().getURI() = "http://schema.omg.org/spec/XMI/2.1"
  }

  /**
   * Gets a UML element that refers to this element, that is, which has an
   * `idref` attribute whose value is the same as the value of this
   * element's `id` attribute.
   */
  UMLElement getUMLReference() { result.getAttributeValue("idref") = this.getAttributeValue("id") }

  /**
   * Gets the name of a stereotype that applies to this element.
   */
  string getAStereotype() {
    exists(UMLElement stereotype |
      stereotype.getName() = "Stereotype" and
      stereotype.getAttribute("name").getValue() = result and
      stereotype.getAChild().getAChild() = this.getUMLReference()
    )
  }

  /**
   * Gets the name of a constraint that applies to this element.
   */
  string getAConstraint() {
    exists(UMLElement constraint, UMLElement constrained |
      constraint.getName() = "Constraint" and
      constrained.getName() = "Constraint.constrainedElement" and
      constraint.getAChild() = constrained and
      constrained.getAChild() = this.getUMLReference() and
      constraint.getAttribute("name").getValue() = result
    )
  }

  /**
   * Gets the name of this element, that is, the value of its `name` attribute.
   */
  string getUMLName() { result = this.getAttribute("name").getValue() }
}

/**
 * A UML element representing a type.
 *
 * In other words, a `packagedElement` whose `type` attribute has value
 * `uml:Class`, `uml:Interface` or `uml:PrimitiveType`.
 */
class UMLType extends UMLElement {
  UMLType() {
    exists(string type |
      this.getName() = "packagedElement" and
      this.getAttribute("type").getValue() = type and
      (
        type = "uml:Class" or
        type = "uml:Interface" or
        type = "uml:PrimitiveType"
      )
    )
  }

  /**
   * Gets the package that contains this type.
   */
  UMLPackage getUMLPackage() { result.getAClass() = this }

  /**
   * Gets a property directly contained in this type.
   */
  UMLProperty getUMLProperty() { this.getAChild() = result }

  /**
   * Gets an operation directly contained in this type.
   */
  UMLOperation getUMLOperation() { this.getAChild() = result }

  /**
   * Holds if this is an enum type, that is, if `enum` is one of its
   * stereotypes.
   */
  predicate isEnum() { this.getAStereotype() = "enum" }

  /**
   * Gets the C class, struct or union type corresponding to this UML type.
   */
  Class getCType() { result.getQualifiedName() = this.getUMLQualifiedName() }

  /**
   * Gets the qualified name of this type. If this type is in a package
   * then this is `package.name`; otherwise it is just `name`.
   */
  string getUMLQualifiedName() {
    if exists(this.getUMLPackage())
    then result = this.getUMLPackage().getUMLQualifiedName() + "." + this.getUMLName()
    else result = this.getUMLName()
  }

  string toString() { result = this.getUMLName() }
}

/**
 * A UML type representing a class, that is, whose `type` attribute has
 * value `uml:Class`.
 */
class UMLClass extends UMLType {
  UMLClass() { this.getAttribute("type").getValue() = "uml:Class" }
}

/**
 * A UML type representing an interface, that is, whose `type` attribute
 * has value `uml:Interface`.
 */
class UMLInterface extends UMLElement {
  UMLInterface() { this.getAttribute("type").getValue() = "uml:Interface" }
}

/**
 * A UML element representing a property of a UML type.
 *
 * In other words, an `ownedAttribute` directly contained in a `UMLType`
 * whose `type` attribute has value `uml:Property`.
 */
class UMLProperty extends UMLElement {
  UMLProperty() {
    this.getName() = "ownedAttribute" and
    this.getAttribute("type").getValue() = "uml:Property" and
    this.getParent() instanceof UMLType
  }

  /**
   * Gets the type that contains this property.
   */
  UMLType getUMLType() { result.getUMLProperty() = this }

  /**
   * Holds if this property represents an enum constant, that is, if it
   * has a stereotype with name `enum+constant`.
   */
  predicate isEnumConstant() { this.getAStereotype() = "enum+constant" }

  /**
   * Gets the C field corresponding to this property, if any.
   */
  Field getCField() {
    result.hasName(this.getUMLName()) and
    result.getDeclaringType() = this.getUMLType().getCType()
  }

  string toString() {
    if this.isEnumConstant()
    then result = "- <<enum constant>> " + this.getUMLName()
    else result = "- " + this.getUMLName()
  }
}

/**
 * A UML element representing an operation of a UML type.
 *
 * In other words, an `ownedAttribute` directly contained in a `UMLType`
 * whose `type` attribute has value `uml:Operation`.
 */
class UMLOperation extends UMLElement {
  UMLOperation() {
    this.getName() = "ownedOperation" and
    this.getAttribute("type").getValue() = "uml:Operation" and
    this.getParent() instanceof UMLType
  }

  /**
   * Gets the type that contains this operation.
   */
  UMLType getUMLType() { result.getUMLOperation() = this }

  /**
   * Gets the C function corresponding to this operation, if any.
   */
  Function getCFunction() {
    result.hasName(this.getUMLName()) and
    result.getDeclaringType() = this.getUMLType().getCType()
  }

  string toString() { result = "+ " + this.getUMLName() }
}

/**
 * A UML property that has an association.
 */
class UMLAssociation extends UMLProperty {
  UMLAssociation() { this.hasAttribute("association") }

  /**
   * Gets the property that this property is associated with.
   */
  UMLAssociation getConverse() {
    this.getAttribute("association").getValue() = result.getAttribute("association").getValue() and
    this != result
  }

  /**
   * Gets the name of this property.
   */
  string getLabel() { result = this.getAttribute("name").getValue() }

  /**
   * Gets the C field corresponding to this property, if any.
   */
  Field getCField() {
    result.hasName(this.getLabel()) and
    result.getDeclaringType() = this.getSource().getCType()
  }

  /**
   * Gets the class that this association is contained in.
   */
  UMLClass getSource() { result = this.getParent() }

  /**
   * Gets the class that this association is associated with.
   */
  UMLClass getDest() { result = this.getConverse().getParent() }
}

/**
 * A UML element representing inheritance.
 *
 * In other words, an `interfaceRealization` whose `type` attribute has
 * value `uml:InterfaceRealization`.
 */
class UMLInheritance extends UMLElement {
  UMLInheritance() {
    this.getName() = "interfaceRealization" and
    this.getAttributeValue("type") = "uml:InterfaceRealization"
  }

  /**
   * Gets the type that is being inherited from.
   */
  UMLType getUMLSupplier() {
    exists(UMLElement e |
      e.getName() = "supplier" and
      result.getUMLReference() = e and
      e = this.getAChild()
    )
  }

  /**
   * Gets the type that is inheriting.
   */
  UMLType getUMLClient() {
    exists(UMLElement e |
      e.getName() = "client" and
      result.getUMLReference() = e and
      e = this.getAChild()
    )
  }

  string toString() {
    result = this.getUMLClient().getUMLName() + " implements " + this.getUMLSupplier().getUMLName()
  }
}

/**
 * A UML element representing a package.
 */
class UMLPackage extends UMLElement {
  UMLPackage() { this.getName() = "Package" }

  /**
   * Gets a class in this package.
   */
  UMLClass getAClass() { result.getAChild().getAChild() = this.getUMLReference() }

  /**
   * Gets the parent package of this package, if any.
   */
  UMLPackage parentPackage() { result.getAChild().getAChild() = this }

  /**
   * Gets the qualified name of this package. If this package is in a
   * parent package then this is `parent.package`; otherwise it is just
   * `package`.
   */
  string getUMLQualifiedName() {
    if exists(this.parentPackage())
    then result = this.parentPackage().getUMLQualifiedName() + "." + this.getUMLName()
    else result = this.getUMLName()
  }

  string toString() { result = this.getUMLQualifiedName() }
}
