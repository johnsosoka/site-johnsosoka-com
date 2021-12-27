---
layout: note
title: AutoHotKey Notes, Recipes & Examples
note_type: AHK Scripting
---

AutoHotkey (AHK) is a niche scripting language build around keyboard & mouse IO. The official [AHK Documentation](https://www.autohotkey.com/docs/AutoHotkey.htm) 
is enormously helpful & provides many wonderful examples. Unfortunately, at the time of this writing it only runs on Windows.

What follows are some quick recipes to get up and running in AHK quickly--I find myself writing AHK scripts just infrequently 
enough to forget everything. Examples demonstrated here can be found [on github](https://github.com/johnsosoka/code-examples/tree/main/ahk/ahk-recipes-examples)
If you have any interest in seeing some "real world" AHK scripts, check out my [AutoHotKey Scripts](https://github.com/johnsosoka/ahk-scripts) 
Repository.

# Index

### Examples

Note: In most of these examples, I bind the script to `F1` function key.

1. [Bind Script to Function Key](#bind-script-to-function-key)
2. [Expanding Variables](#expanding-variables)
3. [Increment Global Value](#increment-global-value)
4. [Evaluate Boolean](#evaluate-boolean-variables)
5. [Function Call & Return Value](#function-call--return-value)
6. [Parameterized Function Call](#parameterized-function-call)
7. [Type Text Press Enter](#type-text-press-enter)

### Recipes
1. [Sleep for a Variable Duration (Parameterized)](#sleep-for-variable-duration-parameterized)
2. [Execute Task Based on Time of Day](#execute-task-based-on-time-of-day)
3. [Execute Task With Percent Chance of Execution](#execute-task-with-percent-chance-of-execution)

## Bind Script to Function Key
[bind script example](https://github.com/johnsosoka/code-examples/blob/main/ahk/ahk-recipes-examples/001-bind-script-to-key.ahk)

**with brackets**
```
F1::
{
    Msgbox, hello world
    return
}
```

**without brackets**
```
F2::
Msgbox, hello world 2
return
```

## Expanding Variables
[variable expansion example](https://github.com/johnsosoka/code-examples/blob/main/ahk/ahk-recipes-examples/002-expand-variable.ahk)

**inline**
```
F1::
{
    name_variable := "john"
    Msgbox, hello there %name_variable%
    return
}
```

**using format**
``` 
F2::
{
    name_variable := "john3"
    MsgBox, % Format("hello there {}", name_variable)
}
```

## Increment Global Value
[value increment example](https://github.com/johnsosoka/code-examples/blob/main/ahk/ahk-recipes-examples/003-increment-global-value.ahk)

```
global counter := 0

F1::
{
    counter++
    MsgBox, counter value: %counter%
}
```

# Evaluate Boolean Variables
[evaluate boolean example](https://github.com/johnsosoka/code-examples/blob/main/ahk/ahk-recipes-examples/004-evaluate-boolean-values.ahk)

```
global say_hello := true

F1::
{
    if (say_hello)
    {
        Msgbox, hello
    }
}
```

# Function Call & Return Value
[function call return value example](https://github.com/johnsosoka/code-examples/blob/main/ahk/ahk-recipes-examples/005-function-call-return-value.ahk)

``` 
F1::
{
    Msgbox, % get_hello_message_function()
    return
}

get_hello_message_function()
{
    message := "hello world"
    return message
}
```

# Parameterized Function Call
[function call with parameter example](https://github.com/johnsosoka/code-examples/blob/main/ahk/ahk-recipes-examples/006-function-call-with-parameter.ahk)

```
F1::
{
    Msgbox, % get_hello_message_function("john")
    return
}

get_hello_message_function(name)
{
    message := Format("hello {}", name)
    return message
}
```

# Type Text Press Enter
[type & press enter example](https://github.com/johnsosoka/code-examples/blob/main/ahk/ahk-recipes-examples/007-type-some-text-hit-enter.ahk)

``` 
F1::
{
    Send, "This is a test message"
    SendInput {Enter}
}
```

# Sleep For Variable Duration Parameterized
[sleep variable duration parameterized example](https://github.com/johnsosoka/code-examples/blob/main/ahk/ahk-recipes-examples/recipes/sleep-for-variable-duration-paramaterized.ahk)

The following script calls a function & provides a range in milliseconds. The function will then sleep for a duratino
within the limits provided.

```
F1::
{
    sleep_duration(2000, 5000)
    Msgbox "finished sleeping"
}

sleep_duration(min_milliseconds, max_milliseconds)
{
    Random, sleepDurationAmount, %min_milliseconds%, %max_milliseconds%
    sleep sleepDurationAmount
}
```

# Execute Task Based on Time of Day
[time of day task example](https://github.com/johnsosoka/code-examples/blob/main/ahk/ahk-recipes-examples/recipes/execute-task-based-on-time-of-day.ahk)

This will need to be adjusted depending on the goal. The following script only checks which hour it is every hour. If
this checked more frequently, it would execute multiple times per hour.

``` 
global executeHour = 8

global OneMinuteMilliseconds := 60000
F1::
    loop {

        if (shouldExecuteBasedOnTime())
        {
            Msgbox, "Executing Script at Execution Hour"
        }
        Sleep OneMinuteMilliseconds*60
    }


shouldExecuteBasedOnTime() {
    shouldExecute := false
    if (A_Hour = executeHour) {
        shouldExecute := true
    }

    return shouldExecute
}
```

# Execute Task With Percent Chance of Execution
[percent chance execution example](https://github.com/johnsosoka/code-examples/blob/main/ahk/ahk-recipes-examples/recipes/execute-task-percent-execution-chance.ahk)

``` 
global percentChanceOfExecution := 50

F1::
{
    if (shouldExecuteBasedOnChance()) {
        Msgbox, % Format("I executed with {}% of execution", percentChanceOfExecution)
    }
}

shouldExecuteBasedOnChance() {
    shouldExecute := false
    Random, randomNumber, 1, 100

    if (randomNumber <= percentChanceOfExecution) {
        shouldExecute := true
    }

    return shouldExecute
}
```