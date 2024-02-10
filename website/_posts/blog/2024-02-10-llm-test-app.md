---
layout: post
title: "Implementing a Model Agnostic Java LLM Test Suite"
category: blog
tags: LLM LangChain LangChain4J 
---

**Context:** The types of LLM Applications I have been building rely on a few key abilities like being able to invoke tools,
parse structured input, generate structured output, and break down complex tasks into smaller, more manageable tasks.

**Problem:** I find myself regularly performing the same types of tests when evaluating new LLM models. I want to automate
these tests and make them available to the public.

## Hallucination Tests


### Test Cases

#### Populate a model from incomplete source data

A common pattern in LLM application is to request that an LLM populate a model from some source data. An example might be 
to read a biography and populate a person object with the information found in the biography.

This is a very hallucination prone task. The Model might see that it needs to populate fields `notable_achievements` and
`education` and the source data might not contain the required information which often yields hallucinations so that the
model can complete the task. 

**Test Case 1: Incomplete source data and no instructions**

**Test Case 2: Incomplete source data and instructions (null is acceptable if the source information is missing)**

#### Delegate Tasks with Incomplete Tools

Similar to the previous test case, this test case will evaluate the model's ability to generate a plan where the tools
provided are incomplete or insufficient.

**Test Case 1: Incomplete tools and no instructions**

**Test Case 2: Incomplete tools and instructions (You may clarify or break the operation if you are unable to complete 
the task with the given toolset)**



## Confidence Tests

One important behavior to evaluate is the confidence of the Agent. This is critically important, because we may have
scenarios where the agent must reach out to a human or tool for help if it is not confident in its own abilities. 

We want to gauge our own confidence in the agent's self assessment.

### Test Cases