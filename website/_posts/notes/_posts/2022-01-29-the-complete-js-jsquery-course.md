---
layout: post
category: note
title: The Complete Javascript & Jquery Course
note_type: Udemy
---

# Complete Javascript & Jquery Course

Course notes for [this](https://www.udemy.com/course/learn-javascript-from-beginner-to-advanced/) Udemy course.

# Basics of Javascript

## Variables

Creating a variable:

```
var user_name = "guest user";
```

**Variable Names Can Have**

* Letters
* Numbers
* Underscore
* Dollar signs

They can contain numbers, but cannot start with a number.

Some keywords cannot be used as variable names like `var`, `if`, `function`, `new`, etc.

**Javascript programmers usually use lower camelCase for variable names**

`firstName`, `lastName`, `exchangeRate`

## Data Types: Strings

single & double quotes are both valid for strings.

identify variable types with `typeof` operator.

ex.)

```
var firstName = 'john'
typeof firstName
```

outputs: `"string"`

**Concatenating  Strings**

```
var concatinatedString = "one" + " " + "two"
```

**length & index**

```
var firstName = 'john';
firstName.length
```

outputs: `4`

```
firstName[0]
```

outputs `j`

**String replace**

```
var url = "https://www.udemy.com";
console.log(url.replace("https://", ""));
```

## Data Types: Numbers (Part 1 & 2)

```
var birthYear = 1990;
var price = 16.99;
var temperature = -5;
```

**math operations**

Consistent with common operators...

```
var num1 = 20;
var num2 = 3;
var sum = num1 + num2;
var subtraction = num1 - num;
var division = num1 / num2;
var multiplication = num1 * num2;

var average = (num1 + num2) / 2;
```

**math object**

```
var randomNumber = Math.random()

var roundUp = Math.ceil(4.3)


// etc
```

**incremental operator**

```
var myNum = 1;
myNum += 5;

// now it's 6
```

can also be used with strings

```
var name = "John";
name += "Sosoka";
```

**type conversion**

you can use `parseInt(number)` to convert sting to int.


## Booleans


Not going to note all operators, but this here are some interesting ones.

| operator | description |
 |-----------|--------------|
| `==`        | Equal to      |
| `===`     | Identical, same type & value |
| `!=`         | Not equal to |
| `!==`      | Not equal value or equal type |

## Null and Undefined

Both null & undefined represent a lack of value..

```
var noValue;
console.log(noValue); // undefined
```

Seems there is some debate on null versus undefined in the js community (according to instructor) he leans towards using null...It can indiciate if the variable may have once contained a value.

"Null is normally used to reset the value of a variable that had a value previously" (This seems a little misleading to me)

If you set a variable to null, the typeOf will still be the object.

```
var temp = 35

temp = null;

console.log(typeof temp); // will show object.
```

## Functions

No concrete reule but camel case for variables & snake case for functions.

**structure**
```
function sum_numbers() {
    var num1 = 5;
    var num2 = 2;
    var sum = num1 + num2;
    console.log(sum);
}

// call with:

sum_numbers()
```

**parameterized**

```
function sum_two(num1, num2) {
    sum = num1 + num2;
    console.log(sum);
}

// invoke with args:
sum_two(10,5);
```
No ex, but you can return with `return variable;`

## Arrays

Ordered in JS.

```
var students = ["John", "Mary", "Peter"];

// fetch elemnt
console.log(students[0]);

// length
console.log(students.length);
```
**Array Operations**

| operation | description |
|------------|--------------|
| push         | Add element to end of array |
| Pop           | Remove the last element of an array |
| Shift          | Remove the first element of an array |
| Unshift      | Add element to the beginning of an array |


## Objects

objects aren't ordered.. key value pairs.

```
var employee = {
    'name': 'james taylor',
    'yearOfBirth': 1948
};

// access
console.log(employee['name']);

// yields james taylor

// dot notation is possble as well (although there are cases were it isn't possible depending on key name)

employee.name
```

**update a field**

```
var employee = {
    'name': 'james taylor',
    'yearOfBirth': 1948,
    'role': 'IT Analyst'
};

employee.role = 'IT Analyst';

// add new field
employee.passport = 'MYNUM';
```

### object methods

```
var student = {
    'firstName': 'Marie',
    'lastName': 'Smith',
    'fullName': function() {
        return this.firstName + ' ' + this.lastName;
    }
}

console.log( student.fullName() ); // The console will show 'Marie Smith'
```
Access elements of the object from the function with the keyword `this`

Note that the property name serves as the function name. No need to add a function name.

Object methods can only be invoked via dot notation. If the field is named in such a way that dot notation is not possible, then it will result in the method not being callable.

# Diving Deeper into Javascript

## Events

Actions that happen in the browser. Some examples: on click, onchange, on mouseover, onmouseout, onkeydown.

Demonstrates a few different events with mouseover, etc.

Demonstrates passing an event in to identify which key is being pressed...

```
document.onkeydown = function(event) {
    console.log(event);
}
```

You can see a huge object detailing the keydown event. Can fetch specific key via

```
document.onkeydown = function(event) {
    console.log(event.keyCode);
}
```

Instead of registering an event, you can set up an onClick property to point to a function.

```
<html>
    <button onclick="show_alert" = id="click-me">click here</button>
</html>

<script>
    function show_alert(){
        alert('you clicked a button);
    }
</script>
```

**SKIPPED A BIT**

## Forms

### Select Box

how to know which option was selected

```
document.getElementById("show_option").onclick = function() {
    var selectField = document.getElementById("options");
    var selectedOption = seletedField.options.selectedIndex;
    var selectedValue = selectedField.options[selectedOption.value];
};
```

`selectedOption.value` for value or `selectedOptions.innerHTML` for the display text.

less code to fetch only value (no option for innerHTML with this method):

```
var selectedOption = document.getElementById("options").value;
console.log(selectedOption);
```

### Radio Buttons

html
```
<form>
    <input type="radio" name="gender" value="Male" checked>" Male"<br>
    <input type="radio" name="gender" value="Female" checked>" Female"<br>
</form>
```
Note that each have the same name.

```
document.getElementById("show_option").onclick = function() {

    // returns array of our radio buttons.
    var radio = document.getElementsByName("gender");
    var radio_selected;
    // loop through array & identify checked radio button.
    for (var a = 0; a < radio.legth; a++) {
        if(radio[a].checked) {
            radio_selected = radio[a].value;
        }
    }    
};
```

### Check Boxes

```
<form>
    <input type="checkbox" name="interest" value="Front-End" checked>" Front-End Development"<br>
    <input type="checkbox" name="interest" value="Back-End" checked>" Back-End Development"<br>
</form>
```

Again, fetch array of checkboxes & iterate

```
document.getElementById("show_check").onclick = function() {

    // returns array of our radio buttons.
    var radio = document.getElementsByName("interest");

    // start building a list
    document.getElementById("selected_check").innterHTML = "<ul>";

    // loop through array & identify checked radio button.
    for (var a = 0; a < check.legth; a++) {
        if(check[a].checked) {
            // append checked value to list form above
            document.getElementById("selected_check").innterHTML += "<li>" + check[a].value + "</li>";
        }
    }    
};
```

### onchange event

Instead of using click action, you can use an onchange event when a select box changes.

```
document.getElementById("education_level").onchange = function () {

    var selectField = document.getElementById("education_level");
    var selectedOption = selectField.options.selectedIndex;
    var selectedValue = selectField.options[selectedOption].innerHTML;
    document.getElementById("selected_level").innerHTML = selectedValue;

};
```

# JQuery

## Intro

jQuery is a javascript library that simplifies the language. Recommends including jQuery include in the head element. We want jquery to load ahead of everything else on the page, so that other components can utilize it.


## Syntax

Almost everything in jquery starts with a `$`

```
$("selector").action();
```

selects using selectors that are very similar to css
```
$(".example") // selects all elements with a class of example
$("p") // selects all p elements
$("#hamburger-icon") // selects the element with the id of hamburger-icon
```

Tying it all together. The following will hide all elements of the class 'example" when clicking the element with the id of "hide"

```
$( "#hide" ).click(function() {
    $(".example").css("display", "none");
});
```

## DOM Manipulation

jquery select inner html + change

```
// select element and print to demo
var content = $("#sample_text").html();
console.log(content)

// update & print again
$("sample_text").html("new content");

content = $("#sample_text").html();
console.log(content)
```

JQuery can also select text ony, or attributes on objects in the dom as with `attr`

```
var url_link = $("#link-element").attr("href");
console.log(url_link);
```

## Forms

**val** method is used to get the value of form fields.

```javasascript
var contentInput = $("#name_field").val();
console.log(contentInput);
```

You can also use val to update a field


```javascript
$("name_field").val("Peter Green"); // Updates the name field
```

Works for many types of objects on the DOM--can be used to get the selected value on a dropdown.

**Jquery to fetch value of a radiobutton**
```javascript
var radioSelected = $("input[name='gender']:checked").val();
console.log(radioSelected);
```

Detect on change

```javascript
$("input[name='gender']").change(function() {
    var radioSelected = $(input[name='gender']:checked").val();
    console.log("radio button changed to " + radioSelected);
});
```

**Check Boxes**

```javascript

// detect checkbox on change
$("input[name='interest']".change(function () {
    // selectedCheckboxes becomes an array
    var selectedCheckBoxes = $("input[name='interest']:checked");
    
    //jquery loop
    $.each(selectedCheckboxes, function(index, value) {
        console.log(value)
    });
});
```

## Events

```
// bind function to event

$("#example").click(function() {
    // execute.
});
```

**ready event**

Lots of problems pop up by way of scripts attempting to interact with elements that haven't loaded yet.

```javascript
$(document).ready(function() {
    // put all code here
});
```

Placing all code inside of the document reay event block is a common pattern to avoid the problems stated above.

It is so common that jquery provides a shorthand mechanism for it

```javascript
$(function() {
    // put all code here.
});
```

**the on() method**

```
$("element").on("click", function() {

});
```

Using the same method to bind multiple events in a single block.. Note, we pass an object {} with each event & function mapping.

```javascript
$("element").on({
    click: function() {
        // on click
    },
    mouseenter: function() {
        // code to be executed.
    }
}
```

# Advanced Javascript

## Callback Functions

> Callback functions are passed as arguments of other functions and they are normally exeucted at the end of the parent function.


```javascript
function get_user() {
    var u = {
        ‘name’: ‘john’
    }
    return u;
}

function greet_user(user) {
    console.log("hello " + user.name);
}

var user = get_user();
greet_user(user)
```


In the example above, we can assign the user variable rapidly--but in a real world scenario this would likely be a call to an API and have a delay, which could cause a problem. The function greet_user might be invoked prior to the user variable being populated.

**with simulated delay**

```javascript 
function get_user() {
    var u = {
        'name': 'john'
    }

    window.setTimeout(function() {
        return u;
    }, 1000);
}

function greet_user(user) {
    console.log("hello " + user.name);
}

var user = get_user();
greet_user(user)
```

The above yields a TypeError -- Name undefined (as expected)

**Callback Example**

```javascript
// add a parameter to pass the function, this doesn't need to be named callback
function get_user(callback) {

    var u = {
        'name': 'john'
    }

    window.setTimeout(function() {
        callback(u);
    }, 1000);
}

function greet_user(user) {
    console.log("hello " + user.name);
}

// pass the function which should be called after processing as a param.
get_user(greet_user);

//alternative method would create the callback function when get_user is invoked:

get_user(function(user) {
    console.log("Hello " + user.name);
});
```

callback functions are everywhere

```javascript
window.setTimeout(function() {}, 1000);
```

## Error Handling
Provides an example—Whenever there is an error, it stops executing.

Try/Catch similar to java—looks like:

```javascript
try {
	var user = get_user();
	greet_user(user);
} catch(err) {
	console.log("how are you?"); // response with no name
}
```

The exception can be caught as any var, but `err` is the conventional name.

**Throw**

```javascript
try {
	var user = get_user();

	if (!user.name) {
		throw 'Name is empty'; // Throw exception
	}
	greet_user(user);
} catch(err) {
	console.log("how are you?"); // response with no name
}
```

## Namespaces
Javascript doesn’t have namespaces?

```javascript
// these variables might need to be used again elsewhere
var products = ['product 1', 'product 2', 'product 3'];
var sliderInterval = 3000;
```

To get around the lack of namespaces, one pattern is to create an object to house

```javascript
// create an object to stash them in
var bestSellersSlider = {};

bestSellersSlider.products = ['product 1', 'product 2', 'product 3'];

bestSellerSlider.interval = 3000
```

Alternatively:

```javascript
var bestSellersSlider = {
	products: ['product 1', 'product 2', 'product 3'],
	interval: 3000,
	get_products: function () {
		console.log(this.products)
	}
};
```


## Json

```javascript
var employee = {
	'name': 'Maria Silva',
	'birth_date': '1988-10-01'
}

// Convert to json

var employee_json = JSON.stringify(employee);

// Convert string to json (JSON.parse)
```

## Local & Session Storage
Local storage is a property of the window object (although window object doesn’t need to be explicitly called)…Should not be used for sensitive info. Local storage will persist if the browser closes / reopens.


```javascript
// setting
localStorage.setItem("name", "john");

// Fetching  
console.log(localStorage["name"]);

// Removing
localStorage.removeItme("name");
```

**Session Storage**
Works just like localStorage:

```javascript
sessionStorage.setItem("name", "john")
```



_local & session storage both only support string values being stored_

If you need to store an object use the `JSON.stringify` method to convert to a string & then store.

# Ajax
## Introduction

AJAX stands for Asynchronous Javascript and XML. Makes HTTP requests to send & receive data from external sources.


## Request

Walks through some status codes. The request objects state will change various times from preparing request to sending to server & relaying response. We need to inspect the state to know when to read the response.


Need to create an XML HttpRequest object..

```javascript
//xhttp var name is a convention.
var xhttp = new XMLHttpRequest();

// Track changes of state in our request

xhttp.onreadystatechange = function() {
	// to view state changes:
	console.log(this.readyState);
	// verify successful request:
	if (this.readyState == 4 && this.status = 200) {
		console.log(this.responseText);
	}
}

xhttp.open("GET", "https://opentdb.com/api.php?amount=1");

xhttp.send();
```


## Response

Just works through parsing the json response. Nothing jquery specific.

## Ajax with Jquery

This will handle the same task outlined in the `request` section above, except we will use jquery to drive the GET request of the public trivia db.

```javascript

// pass object ajax method on jquery
$.ajax({
	url: "https://opentdb.com/api.php?amount=1",
	type: "GET",
	dataType: "json", // jquery will automatically parse response as json
	success: function(data) { // data is the response object passed to function on success
		console.log(data);
	},
	error: function() {
		console.log("error...")
	}
});

```

