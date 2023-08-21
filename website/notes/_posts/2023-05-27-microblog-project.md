---
layout: post
title: Microblog python project using chatGPT as a co-pilot
category: note
tags: chatGPT python flask sqlite peewee blog microblog project jwt auth design orm flask-jwt-extended
---

**Note:** I originally had set out to make this a blog post, but I decided to keep it as a note. I'm not sure if I will ever finalize this post, but I wanted to keep this note around for future reference. The full project can be found [here](https://github.com/johnsosoka/jscom-microblog).

---

I have been tinkering with chatGPT lately, asking it programming questions and requesting that it write some simple functions. I've decided that to take on a test project and use chatGPT as a co-pilot throughout. I write Java code every day for my day job and want to explore using an ORM in python--so I will be writing this project in python.

### What is chatGPT?

I asked chatGPT to summarize what it is, in the context of this blog post:

>ChatGPT is a state-of-the-art language model developed by OpenAI. It's designed to generate human-like text based on the input it receives. The technology underlying ChatGPT, referred to as GPT (short for Generative Pretrained Transformer), utilizes machine learning algorithms to produce text that is impressively coherent and contextually relevant.
>
>Trained on a diverse range of internet text, chatGPT is capable of performing tasks spanning across various domains. It can write essays, answer questions, create conversational agents, tutor in a wide range of subjects, translate languages, simulate characters for video games, and much more.
>
>However, it's essential to note that ChatGPT doesn't actually understand text in the way humans do. It generates responses based on patterns and structures it learned during its training phase, and while it often provides impressively cogent and relevant responses, it can occasionally produce incorrect or nonsensical answers.
>
>One of the major applications of ChatGPT is in the realm of programming and code-writing. Developers, including our author here, are exploring its potential as a co-pilot in software development processes, to write code, answer programming questions, and generally assist in the coding process. The remainder of this post provides an interesting case study of using ChatGPT as a programming assistant for a Python project.

## Project Overview

I have some general ideas for my project, but I'm not attached to using any particular libraries (aside from Flask). In the spirit of keeping this project simple, I plan on using a sqlite database for the persistence layer.

The following is a rough outline of the project:

### Posts / Models

Given that this is a microblog with a database backend, we will need to define posts. Posts will contain the following:

id - integer
content - string
created - DateTime
visible - boolean
deleted - DateTime
Edited - DateTime

The boolean `visible` field will determine if non admin client request can retrieve them.

### Administration

I want to create a simple microblog service. This service will have a single user, the admin, who can publish & edit posts. The admin will need to authenticate to perform administrative actions. The `posts_controller_admin` controller will have methods that parallel the `posts_controller` , the key difference being that fetching posts via the admin end points _will_ return hidden posts.

### Clients

The client controller will allow for fetching posts in bulk as well as individual posts. The endpoints in the client controller will not require authentication and should not return posts that aren't marked visible.

## Breaking Ground

Now that I have a basic game-plan down for my project, I can start using chatGPT to research how I want to implement this.

### Exploring ORMS

I have very little exposure to ORMs available in python, so my first goal is to identify which technology to use before creating the models.

**Prompt:**
what are some popular ORM libraries in python?

**Response:**

--- 

There are several popular Object-Relational Mapping (ORM) libraries in Python. ORM is a technique that connects the rich objects of an application to tables in a relational database management system. Here are a few notable ones:

**SQLAlchemy**: This is arguably the most popular ORM for Python, and for good reason. It provides a full suite of well-known enterprise-level persistence patterns, designed for efficient and high-performing database access. It's highly flexible and offers both a high-level ORM and a low-level direct SQL access.

**Django ORM**: Django, a high-level Python Web framework, comes with its own ORM. It's used for manipulating relational databases and is integrated with Django's template and form handling. If you're building a Django application, its built-in ORM is a natural choice.

**Peewee**: A simple, expressive ORM that supports multiple databases (including MySQL, Postgres, and SQLite). It comes with a built-in query builder, and is lighter-weight than SQLAlchemy and the Django ORM.

**Pony ORM**: It allows you to work with databases using Pythonic and expressive syntax. Its unique feature is its ability to write queries to the database using Python generator expressions and lambdas.

**Tortoise ORM**: It's an easy-to-use asyncio ORM (Object Relational Mapper) inspired by Django. Tortoise ORM was built with relations in mind and admiration for the excellent and popular Django ORM. It's used for building asyncio applications.

**SQLObject**: Another ORM that provides a simple and intuitive API for mapping Python classes to database tables, and instances of those classes (rows in the tables) to Python instances.

Each ORM has its own strengths and trade-offs, and the best one to use depends on the specific needs and constraints of your project.

---

The PeeWee description includes a key word relevant to the task at hand today, _simple_. I'm going to check out PeeWee in depth now.

**Prompt:**

Please create a database entity using PeeWee given the following definition:

```text
id - integer
content - string
created - DateTime
visible - boolean
deleted - DateTime
Edited - DateTime
```

**Response**

---

Sure, you can define a model using Peewee as follows:

```python
from peewee import Model, CharField, DateTimeField, BooleanField, IntegerField
from peewee import SqliteDatabase

db = SqliteDatabase('my_database.db')

class BlogPost(Model):
    id = IntegerField(primary_key=True)
    content = CharField()
    created = DateTimeField()
    visible = BooleanField()
    deleted = DateTimeField(null=True)
    edited = DateTimeField()

    class Meta:
        database = db
```

In this code, the `BlogPost` class is a subclass of Peewee's `Model` class. Each class attribute represents a field in the database table, and each instance of `BlogPost` will represent a row in the database table.

You will need to call `db.connect()` before you can interact with the database, and `db.close()` when you are done.

You also need to create the table itself before you can start using it. This is done using the `create_table()` method, like this:

```python
db.connect()
db.create_tables([BlogPost])
db.close()
```

This will create a table named `blogpost` (the lowercase name of the class) with the specified fields.

Note that the `deleted` field is nullable, which means it can have no value. This is typical for fields that represent an event that may not have occurred yet (like the deletion of a post).

---

Fantastic! I think I'll run with PeeWee as my ORM.

### Building out Administrative API Methods

chatGPT keeps track of the ongoing conversation; As such, I can reference models, services & controllers that we have discussed earlier in the conversation. Since I have already requested chatGPT define a model for blog posts I can now request that it utilize that model in a new service and controller.

**Prompt:**

Given the above model, using flask create an admin controller & service which have the following actions:

create_post
update_post
fetch_post
fetch_posts

**Response:**

---

Here's an example of how you might do this using Flask and Peewee:

First, let's create a `blog_service.py` that contains all the actions related to the `BlogPost`:

```python
from peewee import DoesNotExist
from models import BlogPost

def create_post(content, visible=True):
    post = BlogPost(content=content, visible=visible)
    post.save()
    return post

def update_post(post_id, content=None, visible=None):
    try:
        post = BlogPost.get(BlogPost.id == post_id)
        if content is not None:
            post.content = content
        if visible is not None:
            post.visible = visible
        post.save()
        return post
    except DoesNotExist:
        return None

def fetch_post(post_id):
    try:
        return BlogPost.get(BlogPost.id == post_id)
    except DoesNotExist:
        return None

def fetch_posts():
    return BlogPost.select()
```

Then, we can create `admin_controller.py` that exposes these actions via Flask routes:

```python
from flask import Flask, request, jsonify
from blog_service import create_post, update_post, fetch_post, fetch_posts

app = Flask(__name__)

@app.route('/admin/posts', methods=['POST'])
def create():
    content = request.json.get('content')
    visible = request.json.get('visible', True)
    post = create_post(content, visible)
    return jsonify(post.__data__), 201

@app.route('/admin/posts/<int:post_id>', methods=['PUT'])
def update(post_id):
    content = request.json.get('content')
    visible = request.json.get('visible')
    post = update_post(post_id, content, visible)
    if post is None:
        return jsonify({'error': 'Post not found'}), 404
    else:
        return jsonify(post.__data__)

@app.route('/admin/posts/<int:post_id>', methods=['GET'])
def fetch(post_id):
    post = fetch_post(post_id)
    if post is None:
        return jsonify({'error': 'Post not found'}), 404
    else:
        return jsonify(post.__data__)

@app.route('/admin/posts', methods=['GET'])
def fetch_all():
    posts = fetch_posts()
    return jsonify([post.__data__ for post in posts])

if __name__ == "__main__":
    app.run(debug=True)
```

This will create a Flask application with the specified routes that handle creating, updating, and fetching posts. We're also using Flask's built-in request object to handle incoming JSON data, and returning JSON responses using jsonify.

You will need to modify this code to fit your specific needs, especially around error handling and validation.

Please note that, in a real application, you should also add authentication and authorization checks to make sure that only authorized users can access these admin endpoints.

---

The above isn't perfect, but it's a really wonderful start. Eventually, I can request that chatGPT add request validation to some of the methods. But, right now I'm more concerned with requiring authorization to utilize the admin endpoints.

**Prompt:**

secure the above endpoints and require jwt validation. Add a new endpoint for login to fetch a token. Create a user entity as well so that a username & password can be validated before returning a token

**Response:**

---

To achieve this, you need to add a few things to your application:

1. **User Model:** To store usernames and password hashes.
2. **Login Endpoint:** To authenticate users and provide JWTs.
3. **JWT Required Decorator:** To secure the endpoints.

Firstly, we need to install flask_jwt_extended:

```shell
pip install flask_jwt_extended
```

Now, let's create a User model in `models.py`:

```python
from peewee import Model, CharField
from werkzeug.security import generate_password_hash
from peewee import SqliteDatabase

db = SqliteDatabase('my_database.db')

class User(Model):
    username = CharField(unique=True)
    password_hash = CharField()

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    class Meta:
        database = db
`

Here's the `blog_service.py` with user related services:

`python
from peewee import DoesNotExist
from werkzeug.security import check_password_hash
from models import BlogPost, User

# Previous code ...

def create_user(username, password):
    user = User(username=username)
    user.set_password(password)
    user.save()
    return user

def check_user(username, password):
    try:
        user = User.get(User.username == username)
        if check_password_hash(user.password_hash, password):
            return user
        return None
    except DoesNotExist:
        return None
```

Now, we'll update `admin_controller.py`:

```python
from flask import Flask, request, jsonify
from flask_jwt_extended import JWTManager, jwt_required, create_access_token
from blog_service import create_post, update_post, fetch_post, fetch_posts, create_user, check_user

app = Flask(__name__)

app.config["JWT_SECRET_KEY"] = "super-secret"  # Change this in production!
jwt = JWTManager(app)

@app.route('/admin/register', methods=['POST'])
def register():
    username = request.json.get('username')
    password = request.json.get('password')
    if not username or not password:
        return jsonify({"error": "Username and password required"}), 400
    user = create_user(username, password)
    return jsonify(user.__data__), 201

@app.route('/admin/login', methods=['POST'])
def login():
    username = request.json.get('username')
    password = request.json.get('password')
    user = check_user(username, password)
    if user is None:
        return jsonify({"error": "Invalid credentials"}), 401
    token = create_access_token(identity=username)
    return jsonify(access_token=token), 200

# Secure your endpoints
@app.route('/admin/posts', methods=['POST'])
@jwt_required()
def create():
    # Previous code ...

@app.route('/admin/posts/<int:post_id>', methods=['PUT'])
@jwt_required()
def update(post_id):
    # Previous code ...

@app.route('/admin/posts/<int:post_id>', methods=['GET'])
@jwt_required()
def fetch(post_id):
    # Previous code ...

@app.route('/admin/posts', methods=['GET'])
@jwt_required()
def fetch_all():
    # Previous code ...

if __name__ == "__main__":
    db.connect()
    db.create_tables([BlogPost, User])
    db.close()
    app.run(debug=True)
```

You will need to send the access token in the Authorization header with the Bearer prefix for the protected routes.

Please note: You should not use this code exactly as is in a production environment. It lacks appropriate error handling, the secret key should not be hard-coded, and you should use secure password hashing in conjunction with salts. Also, depending on the use case and deployment environment, you may

---

I was able to continue like this for the remainder of the project. Sometimes I would write an example method & then I would
request that chatGPT write similar methods. Throughout the development of the project, I was creating postman scripts to query
the api methods. I was able to copy/paste the json from the postman collection into chatGPT and have it produce (most of) the API Methods
section of the readme. You can view how the project turned out [here](https://github.com/johnsosoka/jscom-microblog).

## Conclusion

This has been a fascinating project, next up I'll need to explore building a project using Github co-pilot, which is powered
by chatGPT, but would save me time copy/pasting from the web browser. Using AI to write code dramatically speeds up the rate
of development. The code that chatGPT produces is not perfect, but it's a great starting point. I'm excited to see what
the future holds.