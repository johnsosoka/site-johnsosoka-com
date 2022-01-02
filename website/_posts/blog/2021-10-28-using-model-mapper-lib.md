---
layout: post
title: Intelligent Object Mapping in Java with the Model Mapper Library
category: blog
tags: programming java ModelMapper dto entity form bean encapsulation
---

So much of working in software is repackaging, massaging & remapping data. There are many cases where you
may find yourself in need of mapping data one object to another. A popular use case in web development would 
be to accept form data encapsulated in something like a form bean or DTO and then map that to a database entity
for persistence and vice versa. 

Traditionally, we would set up a mechanism to create a new object for our target 
type & then proceed to populate its fields by fetching each related field on the source object; It's not terrible 
amount of overhead, but now with the [ModelMapper library](http://modelmapper.org/) that work can often be avoided.

Starting with this post, I will have accompanying source code available on GitHub. You can find related code for this
article [on github](https://github.com/johnsosoka/code-examples/tree/main/java/object-mapping). You may notice these 
examples look pretty light--this is because I'm using the Lombok library to handle the creation of getters/setters. The 
annotations should be clear but if you need more clarification on Lombok, follow the project [lombok](https://projectlombok.org/) 
link for additional details.

**Pom Dependencies Snippet**
```xml
    <dependencies>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>1.18.22</version>
    </dependency>
    <!-- https://mvnrepository.com/artifact/org.modelmapper/modelmapper -->
    <dependency>
        <groupId>org.modelmapper</groupId>
        <artifactId>modelmapper</artifactId>
        <version>2.4.4</version>
    </dependency>

</dependencies>
```

# Simple Object Mapping

In our first example, we will between two nearly identical objects. We will be mapping a BookFormBean to a Book entity. 
To keep the example simple, I'm not providing any extra annotations. In a real world scenario the Entity might have 
JPA Annotations and the FormBean could have Jackson annotations an/or Swagger documentation .

Our source object will be the FormBean, the `@Getter` and `@Setter` annotations will create getters & setters for us, 
the `@Data` annotation will do this in fewer lines but was not used in the spirit of readability.

**BookFormBean.java**
```java
package com.johnsosoka.tutorial.model.bean;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class BookFormBean {

    private String title;
    private String isbn;

}
```

The Destination object will be a Book our Entity package, this may be the object we use for dealing with 
the database; It has an ID field not present on the form bean, this could serve as field for the unique ID in a real 
world scenario.

**Book.java**
```java
package com.johnsosoka.tutorial.model.entity;

import lombok.Getter;
import lombok.Setter;

import java.io.Serializable;

@Getter
@Setter
public class Book implements Serializable {

    private String id;
    private String title;
    private String isbn;

}
```

You may be starting to see how this is the Simple example, both objects have several fields with the exact same name.
Before using the model mapper, I'd like to show how this may have been done traditionally. Check the following method:

```java

public Book oldObjectMappingStrategy(BookFormBean bookFormBean) {
        Book book = new Book();

        book.setTitle(bookFormBean.getTitle());
        book.setIsbn(bookFormBean.getIsbn());

        return book;
        }

```

Using our traditional method, we would initialize a new empty destination object & then painstakingly map each field by
getting from the source object & setting on the destination object. I say that jokingly, but with larger objects that
contain many fields it can become fairly tedious.

Now lets build a method showcasing the new strategy, before tying it all together. Note the following: 

```java
    public Book newObjectMappingStrategy(BookFormBean sourceObject) {
        ModelMapper modelMapper = new ModelMapper();
        Book destinationObject = modelMapper.map(sourceObject, Book.class);
        return destinationObject;
    }
```

Inside the newObjectMappingStrategy we are creating a new instance of the ModelMapper to use and then calling the map function on it.
When we call the map function, we're providing our source object and the destination class--the ModelMapper will then
return our destination Object with all mappable fields populated. 

We can reduce the newWay method to the following:

```java
    public Book newWayReduced(BookFormBean bookFormBean) {
        return new ModelMapper().map(bookFormBean, Book.class);
    }
```

### Tying it All Together

Now that we have all of our models to map, let's plug some data in and test out the model mapping. 

**SimpleExample.java**
```java
    public void executeSimpleExample() {
        // Create source Object...
        BookFormBean sourceBean = new BookFormBean();
        sourceBean.setTitle("Clean Code");
        sourceBean.setIsbn("9780132350884");

        // Map to new object
        Book destinationObject = this.newMappingStrategyReduced(sourceBean);

        // Validate
        System.out.println(destinationObject.getTitle());
        System.out.println(destinationObject.getIsbn());

    }
```

Here we create a BookFormBean named sourceBean and populate a handful of fields on it. Remember, we are expecting to be
able to easily map these fields to a different object type (Book) by using the object mapper. This is why we are printing
the fields on the destination object to validate. If the destinationObject was able to have the title & isbn properly set, 
then the model mapper has done its job.

When I run this, the console output is as follows:

```shell
Clean Code
9780132350884
```

Success! We have successfully mapped common fields between two objects! The bulk of this task was preparing our data
objects and demonstrating the old way of transforming objects. The actual core of the lesson here was ultimately a single
line, the ModelMapper library is a really handy tool.

Full Example [Code Here](https://github.com/johnsosoka/code-examples/tree/main/java/object-mapping)