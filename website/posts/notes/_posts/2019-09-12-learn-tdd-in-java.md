---
layout: post
category: note
title: Learn TDD in Java
note_type: Udemy
---

# TDD Overview/History/Why

TDD Really popularized in the agile manifesto (Follow Up)

Short development cycles, test first—Then write app.
Test code & Application code are developed together.

TDD Tests are generally towards the lower end of the spectrum, Unit test.. Not integration Tests

# The Test Driven Development Cycle

* Write test
    * Think about the feature you’re about to create. 
    * Think about how you will design the code to be accessible of the test

* Test Fails
  * Gain confidence here. Since no application code exists, we want it to fail!

* Write Code
   * Avoid temptation to dig into and build all of the application
   * Emphasis on just getting the test passing, doesn’t need to be perfect.

* Test passes!

* Refactor
    * Now you refactor, and tidy the code up (test & application code)
* REPEAT

Also sometimes called RED/GREEN/REFACTOR (test fails, test passes, refactor)

# Why TDD?

* Proactive approach to software quality
* Testing functionality as you go helps reduce the risk of defects
* Defects are easier to find
* TDD Forces you to take a more in-depth focus on the requirements.
* Rapid Feedback
* Collaboration, enables developers to work together (Forces incrementation/iteration over time)
* Places value on refactoring. Think red/green/refactor, half of that time can be spent on refactoring.
* Refactor early, refactor often helps prevent a major refactor.
* Design to test. TDD Drives good design practice.
* TESTS AS INFORMATION - This is big. Documents decisions & assumptions.

# TDD Demonstration 1 - 3
[General Notes on the Demonstration]

Reverse Polish Calculator
Operators follow operands, instead of 3+4 it’s 3 4 +

Keep in mind: As you write tests, IntelliJ should offer a “create method” or “create class” option when you get an error for something not existing while writing the test.

He did it, that crazy son of a ----- did it.

In the polish calculator, he literally coded the tests first
* Don’t be afraid to start REALLY Simple (Can I create this object Simple)
*  He separates classes more than I think I’d be inclined to
*  Several test classes acting on the same class
* Note: I suppose at a high level, it does help keep tests readable.

**Does not hesitate to create long test names.**

# Design Enabling Test

Real world apps are more difficult & complex than the simple demo.
Applications must be designed well

# SOLID Principles

**Single Responsibility**
* Every class should have a single responsibility and that responsibility to should be encapsulated by that class.
* Note: In Robert Martins book “Clean Architecture” He claims that this truly means a class should only change for one reason. Change agents being business users.

**Open/Closed Principle**
* A Class should be open for extension, but closed for modification.
  * New functionality should mean adding functionality to subclasses of the existing class.
  * If you need to change initial classes, you risk breaking old logic.

**Liskov Substition Principle**
* If you have class A and B, and A is a subtype of B. You should be able to switch either type with each other without altering any other part of the program.

**Interface Segregation**
* Smaller, more specific interfaces should be implemented into a larger interface.

**Dependency Inversion**
* Rather than having high level classes use low level classes directly, introduce a level of abstraction so that the low level classes utilize an abstraction layer.
* Typically, done with interfaces. High level classes would use the interface instead of the low level class directly.

# Test Doubles

Test doubles help us replace dependencies in a test environment.

Types of doubles:

**Stub**
* One which provides pre-determined answers to any questions that you might ask of that object. Not a lot of behavior.
* Could have information recording on the information called on that stub. Provides state based verification.

**Fakes**
* Fake object, more advanced than a stub. It would have “real’ behavior and emulate application behavior. IE, fake an in memory database.

**Mocks**
* Unlike stubs, mocks are about behavior verification (instead of state)
* Ex) Verify a method was called with the right parameters
* Before executing test code, you would need to set up the mock object with what is expected. The Assertions are made by the mock object

NOTE: Maybe rewatch clip 21 “Demonstrating Test Doubles”

# Mock Frameworks

Many mock frameworks exist for creating mock objects.

Mockito

Be careful using test frameworks, test code can become VERY convoluted (I’ve seen this happen)

If you’re new to TDD start off hand rolling your own stubs/mocks/fakes

You can MIX hand made mocks with framework mocks. Hand made mocks are definitely easier to read.

# Dealing with Legacy Code

How do you go about testing code with systems already in place OR have tons of dependencies that you have no control over?

Powermock allows us to mock objects that would otherwise be inaccessible.

Real emphasis on using mocking tools for big objects we don’t want to be called like a File handler.

# TDD Principles

Test Principles
FIRST Acronym

**Fast**
* Tests should be quick to run.
  * If they run slowly, developers wont run them as frequently.

**Independent**
* Tests should be independent of each other & run in different orders.
  * Test failures shouldn’t cause other tests to fail
  * Test successes shouldn’t be the cause of other test successes

**Repeatable**
* No matter the environment, your tests should perform the same way.
  * Special setup should not be required.

**Self Validating**
* Test should SIMPLY pass or fail. No other special output.
  * You should never be looking at logs to determine if a test passed.

**Timely**

# TDD Anti-patterns

**The Singleton**

* Not being in control of instantiation is bad for the test
* They are designed to retain state all of the time, which removes isolation from tests
* TESTS SHOULD BE SELF CONTAINED

**Create the World**

* If tests require a HUGE amount of setup it means your system may be
  * 2 tightly coupled OR
  * Your tests aren’t partitioned well enough, too big of tests.
*  Can also make tests slow to run, if the @Before method is huge, it gets called every time.
*  Too much setup likely means your application has too tight of coupling

**Completely Mocked**


* Don’t fall into the trap of just testing your mocks.
* Caused by not thinking about or understanding the boundaries you intend to test
* Before writing tests, spend time thinking about WHAT classes are inside of the scope of the test.

**The Exceptional Test**

* No assertions. Only validates that the code doesn’t throw an exception.
* Good coverage but poor validation. FALSE SENSE OF SECURITY

**Usually Passes**

* Tests that sometimes fail, usually pass—without changes, means that if you encounter a true failure, you’ll probably ignore it.
* Usually happen when tests depend on some external resource.

**One Big Test**

* Test doing too much.
* Easy to spot if there are multiple assertions or, more particularly, more method calls in a single test.

**The Slow Test**

* Violates FIRST.
  * Should be quick to pass/quick to fail

# Applying TDD

**When not to use TDD**

* Experimental or temporary projects, TDD may not be necessary
* Short lived code
* If design is fixed.

**How to introduce?**
* Practice!
  * Before using in a real world application, PRACTICE. Use TDD to write simple code/applications.
* Thinking about how to test can cause a massive cognitive shift

**TDD Kata**

1. Convert text from Arabic numeral to Roman numerals
2. Convert from Roman numerals to Arabic numerals
3. FizBuzz
4. Roman Calculator (I + III = IV)

Implement simple tennis game (scoring system)