---
layout: post
title: Using your data in chatGPT without LangChain or LlamaIndex
category: blog
tags: ai chatGPT vector datanbase vectors embeddings custom data
---

Recently I have been spending some time exploring new libraries for using custom data with chatGPT, particularly 
LangChain which is a phenomenal library that is growing rapidly. I'll probably use LangChain or LlamaIndex in the future,
but I did want to take some time and explore how to use custom data with chatGPT without using either of those libraries.

## Key Concepts

There are some basic concepts that we need to understand before we can use custom data with chatGPT.

### Embeddings & Vectors

In the context of machine learning, particularly with natural language processing, an embedding is a vector representation
of the meaning & relationships of a word or phrase. For example, the word "cat" and the word "dog" are similar in meaning while
being entirely different words; These words represented as vectors would be close together in vector space.

Vectors can be used in a variety of contexts, but in the context of AI & machine learning we are using them to represent 
the meaning of a word or phrase.

### Vector Database

A vector database is a database that stores vectors. Vectors can be stored in any type of database, but a vector database
will have some additional features that make it easier to work with vectors. Similarity search is a common feature of vector
databases and critical for using custom data with chatGPT. With similarity search, we can take a users question and convert
it to a vector. We can then performa similarity search with the vector against our database to see if we have any vectors stored
with similar linguistic meaning.

## Overview

Today's project will be broken down into two fundamental parts: Data Ingestion & Data Retrieval. It is important that we
organize our data in a way that makes it easy to ingest and retrieve. 

### Data Ingestion

For this project, we will be using a simple text file broken into chunks of 200 characters. We will then use the vector 
representation of each chunk to build a vector database.

![gdpr](/assets/img/blog/custom-gpt-data/data-ingest.png)

### Data Retrieval