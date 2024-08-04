---
layout: post
title: "LLM App Development: Prompting and Structured Replies"
category: blog
tags: LangChain AI chatGPT LangChain4J Java LLM App Patterns Strategy Strategies
---

---

**Edit 02/13/24:** Since writing this post the LangChain4J project has improved structured replies rendering the
`JSON_LIST_RESPONSE_CLAUSE` obsolete.

---

First things first, Happy Halloween! 🎃. This is my wife's favorite holiday, so I'm going to keep this post short and sweet
so that I can go back to being on call for her.

These past few months I have been exploring writing LLM applications. That is, software applications that are utilizing 
a Large Language Model in one capacity or another. Many people have restricted themselves to only viewing the potential of 
LLMs in terms of chatbots, which is severely limited and horribly unimaginative.

I have been finding that we can weave LLM capabilities into our legacy applications in interesting ways. We will be 
building a simple LLM application that helps us edit a technical blog post. Along the way, I'll demonstrate some of 
the patterns and strategies that I have uncovered.

**Note:** I'll be using LangChain4J in my examples, but the concepts here should be applicable to any LLM framework.

## Prompting

We'll start with the simplest & most obvious use case for LLMs: prompting. Prompting is the act of providing a model with
a prompt and having it generate a response. 

### Prompt Templates

Prompt templates are a strategy for creating a dynamic, reusable prompt. The basic idea is that you will create a prompt 
template for a specific use case that may have different variables. Consider the following example:

```java
import dev.langchain4j.model.input.structured.StructuredPrompt;
import lombok.Builder;

@Builder
@StructuredPrompt({"You are a world-class editor helping a friend edit their personal tech blog.",
        "Your goal is to carefully analyze the blog post and provide feedback to your friend.",
        "Notes from Author: {{authorNotes}}",
        "Blog Post Content: {{blogPost}}",
})
public class DynamicPrompt {

    private String authorNotes;
    private String blogPost;
    
}
```

With the above prompt template, I could pass in the contents of a variety of blog posts and author notes. I could
expand the code to generate a prompt in a for-each loop for all existing blog posts to generate a prompt for each one.

### Prompt Clauses

As your LLM Applications grow in complexity, you may find your prompts getting large & cumbersome. As I'll elaborate
in a later section, you may also have multiple prompts that share some common themes/clauses. In these cases, you may
want to use what I've been calling "Prompt Clauses." Prompt clauses are reusable, named sections of a prompt.

We can adapt our earlier example to use prompt clauses. Instead of building a dynamic prompt, I'll be using a `LangChain4J`
Service (It's an interface defining an LLM Agent)

First, we can adapt to a service:

```java
import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;

public interface BlogEditor {

    @SystemMessage({"You are a world-class editor helping a friend edit their personal tech blog.",
            "Your goal is to carefully analyze the blog post and provide feedback to your friend.",
    })
    @UserMessage("Please provide feedback on the blog post: {{it}}")
    String provideFeedback(String blogPost);
}
```

Then we can then create some prompt clauses to demonstrate:

```java
public interface BlogEditor {

    String BLOG_AUDIENCE_CLAUSE = "Remember, this blog is meant for a technical audience.";
    String DETAIL_CLAUSE = "When providing feedback, be as detailed as possible. " + 
            "Consider industry best practices, and provide specific examples. " + 
            "Consider both the content and technical accuracy of the blog post.";
            

    @SystemMessage({"You are a world-class editor helping a friend edit their personal tech blog.",
            "Your goal is to carefully analyze the blog post and provide feedback to your friend.",
            BLOG_AUDIENCE_CLAUSE,
            DETAIL_CLAUSE
    })
    @UserMessage("Please provide feedback on the blog post: {{it}}")
    String provideFeedback(String blogPost);
}
```

With the above examples, we can see how we can use prompt clauses to create reusable, named sections of a prompt. These
are slightly different from variables in a prompt template, as they are not meant to be replaced by dynamic content. Instead,
these are building blocks for prompts that can be reused across multiple prompts.

Additionally, it makes it easier to A/B test slight variations on prompts. For example, you could write two different 
prompt clauses, and then compare the results of each.

### Structured Responses

Many LLM frameworks will attempt to get the LLM to form structured responses under the hood, but it may not always work. 
This is a reminder that you can always specify the structure of the response you want (although your mileage may vary depending 
on the LLM). For example, we can specify that we want feedback on our blog post to be formatted as a list of json objects.

With the existing prompt shown above, I'm getting an output like:

```text
Your blog post is well-written and provides valuable insights about using Large Language Models (LLMs) in application development. Here are some of my thoughts:

1. **Title and Introduction:** The title is catchy but it would be better if it was more specific about which aspect of LLM application development you are discussing. For instance, "Strategies & Patterns for LLM App Development: Prompting and Application Flow". In the introduction, the personal anecdote about Halloween is engaging but try to transition more smoothly into the main topic. 

2. **Content Structure and Depth:** You've explained the concept of prompting and its different strategies like 'Prompt Templates' and 'Prompt Clauses' effectively using Java examples. However, the section on 'Structured Responses' seems incomplete. Expand on this, providing code examples and explaining how it may not always work. 

3. **Technical Accuracy:** The code examples are clear and accurate. However, the part where you mention 'LLM Agent' could be expanded upon. Those not familiar with the term may not understand its function or significance. 

...
```

Continuing to build on the previous example...If we utilize a prompt clause `JSON_LIST_RESPONSE_CLAUSE` & specify the structure of the response, 
we can get a more structured response:

```java
public interface BlogEditor {

    String BLOG_AUDIENCE_CLAUSE = "Remember, this blog is meant for a technical audience.";
    String DETAIL_CLAUSE = "When providing feedback, be as detailed as possible. " +
            "Consider industry best practices, and provide specific examples. " +
            "Consider both the content and technical accuracy of the blog post.";

    String JSON_LIST_RESPONSE_CLAUSE = "Your feedback must adhere to the following format: " +
            "[{\n" +
            "  \"feedback_type\": \"CONTENT | STRUCTURE | TECHNICAL_ACCURACY | READABILITY | REFERENCES\",\n" +
            "  \"original_quote\": \"The original quote from the blog post.\",\n" +
            "  \"feedback\": \"The critical feedback provided to improve the blog post.\",\n" +
            "  \"explanation\": \"Explain your reasoning for providing this feedback.\",\n" +
            "  \"follow_up\": {\n" +
            "    \"actionRequired\": \"NONE | REVISE | CLARIFY | ADD_REFERENCE | VERIFY_TECHNICAL_VALIDITY\",\n" +
            "    \"additionalInfo\": \"Any extra information or resources required that will assist in carrying out the required action.\"\n" +
            "  }\n" +
            "}]";

    @SystemMessage({"You are a world-class editor helping a friend edit their personal tech blog.",
            "Your goal is to carefully analyze the blog post and provide feedback to your friend.",
            BLOG_AUDIENCE_CLAUSE,
            DETAIL_CLAUSE,
            JSON_LIST_RESPONSE_CLAUSE
    })
    @UserMessage("Please provide feedback on the blog post: {{it}}")
    String provideFeedback(String blogPost);
}
```

Now my results now follow the structure I specified:

```json
[{
  "feedback_type": "STRUCTURE",
  "original_quote": "First things first, Happy Halloween! 🎃. This is my wife's favorite holiday, so I'm going to keep this post short and sweet so that I can go back to being on call for her.",
  "feedback": "Consider removing or moving the personal anecdote to the end of the blog post.",
  "explanation": "While a personal touch can make a blog post more engaging, it's important to get to the main topic quickly, especially for technical readers. This will help keep the reader's attention and ensure they continue reading the post.",
  "follow_up": {
    "actionRequired": "REVISE",
    "additionalInfo": "You could possibly move this personal anecdote to the end of the blog post, thanking the readers for their time and wishing them a Happy Halloween."
  }
},
{
  "feedback_type": "TECHNICAL_ACCURACY",
  "original_quote": "Many people have restricted themselves to only viewing the potential of LLMs in terms of chatbots, which is severely limited and horribly unimaginative.",
  "feedback": "Consider rewording to avoid sounding dismissive.",
  "explanation": "The statement could be perceived as dismissive towards those who are primarily using LLMs for chatbots. It's important to acknowledge the validity of different use cases while promoting broader applications of the technology.",
  "follow_up": {
    "actionRequired": "REVISE",
    "additionalInfo": "You could say something like, 'While many have been utilizing LLMs primarily for chatbots—an incredibly powerful application—there is a vast potential for these models beyond this use case.'"
  }
},

...
```

This is wonderful! Now we can easily parse the results and weave them into our application. Toggling between "legacy" programming 
and LLM programming.

First, we'll encapsulate the response we just defined into a Java object:

```java
package com.johnsosoka.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

@Data
public class FeedbackItem {

    @JsonProperty("feedback_type")
    private String feedbackType;

    @JsonProperty("original_quote")
    private String originalQuote;

    @JsonProperty("feedback")
    private String feedback;

    @JsonProperty("explanation")
    private String explanation;

    @JsonProperty("follow_up")
    private FollowUp followUp;

    @Data
    public static class FollowUp {

        @JsonProperty("action_required")
        private String actionRequired;

        @JsonProperty("additional_info")
        private String additionalInfo;
    }
}
```

Really consider the above fields. Each of these is going to be populated _by the LLM_. We're asking the LLM to conform its responses
to the above model throughout our application. One of my goals for the above is to have actionable steps and insight into the LLMs reasoning.

Finally, we can map the structured response string to a Java object:

```java
        List<FeedbackItem> feedbackItems;

        try {
        feedbackItems = objectMapper.readValue(feedbackItemString, new TypeReference<List<FeedbackItem>>(){});
        System.out.println("Parsed Feedback Items: " + feedbackItems.size());
        } catch (JsonProcessingException e) {
        e.printStackTrace();
        }
```

Here is my entire main class as well as the output:

```java
package com.johnsosoka;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.johnsosoka.agent.BlogEditor;
import com.johnsosoka.model.FeedbackItem;
import dev.langchain4j.memory.chat.MessageWindowChatMemory;
import dev.langchain4j.model.openai.OpenAiChatModel;
import dev.langchain4j.service.AiServices;
import lombok.SneakyThrows;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.List;

public class Main {

    public static void main(String[] args) {
        String API_KEY = System.getenv("API_KEY");

        if (API_KEY == null || API_KEY.isEmpty()) {
            System.out.println("API_KEY not set. Exiting...");
            return;
        }

        BlogEditor requirementAssistant = AiServices.builder(BlogEditor.class)
                .chatLanguageModel(OpenAiChatModel.builder()
                        .apiKey(API_KEY)
                        .modelName("gpt-4")
                        .timeout(Duration.ofSeconds(380))
                        .maxRetries(1)
                        .build())
                .chatMemory(MessageWindowChatMemory.withMaxMessages(5))
                .build();

        String blogPost = readMarkdownFile("/Users/john/code/johnsosoka-com/jscom-blog/website/_posts/blog/2023-10-31-llm-app-patterns.md");

        String feedbackItemString = requirementAssistant.provideFeedback(blogPost);

        ObjectMapper objectMapper = new ObjectMapper();
        List<FeedbackItem> feedbackItems;

        try {
            feedbackItems = objectMapper.readValue(feedbackItemString, new TypeReference<List<FeedbackItem>>(){});
            System.out.println("Parsed Feedback Items: " + feedbackItems.size());
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }

    }



    @SneakyThrows
    public static String readMarkdownFile(String filePath)   {
        Path path = Paths.get(filePath);
        List<String> lines = Files.readAllLines(path);
        return String.join("\n", lines);
    }
}
```

```commandline
Connected to the target VM, address: '127.0.0.1:54877', transport: 'socket'
SLF4J: No SLF4J providers were found.
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See https://www.slf4j.org/codes.html#noProviders for further details.
Parsed Feedback Items: 5
```

Cool, we're able to parse the structured feedback response into a Java object. You can probably start to imagine ways that
we could weave this into our application. 

## Application Flow

With the LLM returning structured responses that we can parse into Java objects, we can start to discover new techniques and
patterns for building LLM applications. Along the way, we'll find abstractions from old patterns that work well in new ways.

## Simple Responsibility Principle
_An homage to the Single Responsibility Principle_

LLMs are a new technology, and at the moment they are good at **tasks** not **jobs**. This means that we should be designing
LLM applications where simple tasks are dispatched to the LLM. 

A Job might be "Verify the technical accuracy of this blog post." which really is a collection of tasks. Tasks might include
researching the technical accuracy of a claim, or verifying that a code sample is correct. Tasks might require multiple 
tools to be used in conjunction with each other.

I have found through different prompting & application flows that
you can get _better quality results_ from LLMs by giving them more focused tasks.

As this post is focusing on a blog editor application that leverages an LLM, I'll use that as an example. Instead of giving
the LLM a singular task of "editing a blog post", we can break down the act of editing a blog post into smaller, more focused
tasks.

Here, I'll break down editing into two tasks. One will act as a technical editor, and the other will act as a content editor.

**Define the Content Editor Task**

You can skim over the prompting. The idea here is that I'm expanding on the content editor's role.

```java
   @SystemMessage({
            // General Role
            GENERAL_ROLE,
            // Detailed Role - STRUCTURE, CLARITY, READABILITY
            "Your primary task is to meticulously scrutinize the blog post for overall structure, clarity, and readability.",
            "Hierarchy: Ensure that the headers and sub-headers create a coherent hierarchy that logically guides the reader through the content.",
            "Flow: Check the sequencing of paragraphs and sections for natural progression.",
            "Consistency: Verify that the formatting is consistently applied throughout.",
            "Transitions: Review the transitions between sections and paragraphs for seamlessness.",
            "Precision: Review each sentence for precision of language and eliminate ambiguous phrases or undefined jargon.",
            "Conciseness: Look for verbose or redundant expressions and suggest more concise alternatives.",
            "Purpose: Ensure each paragraph and section serves a clear purpose and contributes to the blog post's main objective or arguments.",
            "Technical Concepts: Validate that technical ideas are clearly introduced and easy to understand.",
            "Language Level: Gauge the language complexity to match the intended audience.",
            "Sentence Structure: Assess sentence structure for variety and rhythm.",
            "Punctuation: Verify the correct usage of all punctuation marks.",
            "Visual Aids: Confirm that visual elements like bullet points and block quotes are used appropriately to improve readability.",
            "Your goal is to provide actionable feedback, specifying what needs to be revised, removed, or added. Each feedback item should be accompanied by your reasoning for these changes.",
            "Your expertise will be instrumental in elevating this blog post to a level of excellence that sets it apart in the tech community.",
            // Clauses
            BLOG_AUDIENCE_CLAUSE,
            DETAIL_CLAUSE,
            JSON_LIST_RESPONSE_CLAUSE

    })
    @UserMessage("Please provide feedback on the blog post: {{it}}")
    String provideContentEditorFeedback(String blogPost);
```

Notice that we're tying it all together now. We're using the clauses we defined earlier to stitch our prompts together
with re-usable component parts.

**Define Technical Editor Task**

Similarly, we'll define the technical editors' role in more detail.

```java
    @SystemMessage({
            // General Role
            GENERAL_ROLE,
            // Detailed Role - TECHNICAL / ACCURACY
            "You are a world-class technical editor with a keen eye for detail, tasked with evaluating the technical aspects of this blog post.",
            "Your primary objective is to ensure that the blog post is not only factually accurate but also adheres to industry best practices.",
            "Accuracy: Verify the correctness of all technical statements, data, and code snippets. Make sure all claims are backed by reliable sources or empirical evidence.",
            "Best Practices: Check if the blog post follows current industry best practices. If newer or better approaches exist, suggest them as revisions.",
            "Libraries and Frameworks: Confirm that the correct versions of any libraries or frameworks are referenced. Make sure that deprecated or unsafe methods are not used.",
            "Security: Evaluate the post for any security red flags, such as insecure code samples, and suggest safer alternatives.",
            "Performance: Assess if performance best practices are followed in code samples and technical advice.",
            "Compatibility: Ensure that the solutions offered are compatible across different environments, such as various operating systems or browser versions.",
            "Up-to-Date Information: Determine whether the blog post refers to the most recent research, data, or technology. Suggest updates if necessary.",
            "Citations: Verify that all technical claims are properly cited and that the references are reliable and up-to-date.",
            "Potential Pitfalls: Point out any potential issues or common misunderstandings related to the topic that the reader should be aware of.",
            "Future Research: If applicable, propose follow-up questions that could lead to further exploration or clarify areas where the tech community has yet to reach a consensus.",
            "Your goal is to provide detailed, actionable feedback, specifying what needs to be revised, added, or removed. Each feedback item should include your reasoning, along with any necessary resources or citations.",
            "Your technical expertise will be crucial in ensuring that this blog post is both accurate and enlightening, standing out as a reliable resource in the tech community.",
            // Clauses
            BLOG_AUDIENCE_CLAUSE,
            DETAIL_CLAUSE,
            JSON_LIST_RESPONSE_CLAUSE
    })
    @UserMessage("Please provide technical feedback on the blog post: {{it}}")
    String provideTechnicalFeedback(String blogPost);
```

When we tie it all together and utilize both of the above prompts, we will be calling the LLM twice. We're ultimately
performing two content editing "sweeps" against my blog content. One is a more traditional content editor, focusing on
tone and structure. The other is a technical editor, focusing on technical accuracy and best practices.

Again, we can use the "Prompt Clauses" to remind the editor of the audience and the details of the task.

### Focused Operations, Aggregated Results

When we design an LLM application to have simple, well-defined tasks, we can start to mold a more well-rounded & dynamic
application. We have structured an agent to perform two specific blog editing tasks, and we have defined a structured output.

With focused operations _and_ structured output, we can start to aggregate the results of multiple operations.

Restructuring our application flow, we can create two methods that will call the LLM and return the structured output:

```java
    public static List<FeedbackItem> getTechnicalFeedback(String blogPost, BlogEditor assistant) {
        String technicalFeedback = assistant.provideTechnicalFeedback(blogPost);
        List<FeedbackItem> technicalFeedbackItems = null;
        try {
        technicalFeedbackItems = new ObjectMapper().readValue(technicalFeedback, new TypeReference<List<FeedbackItem>>(){});
        } catch (JsonProcessingException e) {
        e.printStackTrace();
        }
        System.out.println("Technical Feedback Items: " + technicalFeedbackItems.size());
        return technicalFeedbackItems;
        }

public static List<FeedbackItem> getContentEditorFeedback(String blogPost, BlogEditor assistant) {
        String contentEditorFeedback = assistant.provideContentEditorFeedback(blogPost);
        List<FeedbackItem> contentEditorFeedbackItems = null;
        try {
        contentEditorFeedbackItems = new ObjectMapper().readValue(contentEditorFeedback, new TypeReference<List<FeedbackItem>>(){});
        } catch (JsonProcessingException e) {
        e.printStackTrace();
        }
        System.out.println("Content Editor Feedback Items: " + contentEditorFeedbackItems.size());
        return contentEditorFeedbackItems;
        }
```

The restructured main method now looks like:

```java
 public static void main(String[] args) {
        String API_KEY = System.getenv("API_KEY");

        if (API_KEY == null || API_KEY.isEmpty()) {
        System.out.println("API_KEY not set. Exiting...");
        return;
        }

        BlogEditor requirementAssistant = AiServices.builder(BlogEditor.class)
        .chatLanguageModel(OpenAiChatModel.builder()
        .apiKey(API_KEY)
        .modelName("gpt-4")
        .timeout(Duration.ofSeconds(380))
        .maxRetries(1)
        .build())
        //.chatMemory(MessageWindowChatMemory.withMaxMessages(5))
        .build();

        String blogPost = readMarkdownFile("/Users/john/code/johnsosoka-com/jscom-blog/website/_posts/blog/2023-10-31-llm-app-patterns.md");

        List<FeedbackItem> technicalFeedback = getTechnicalFeedback(blogPost, requirementAssistant);
        List<FeedbackItem> contentFeedback = getContentEditorFeedback(blogPost, requirementAssistant);

        printFeedback(technicalFeedback);
        printFeedback(contentFeedback);

        System.out.println("done.");
        }
```

Resulting in:

```commandline
Technical Feedback Items: 7
Content Editor Feedback Items: 5

Feedback Type: TECHNICAL_ACCURACY
Feedback: Revise the usage of LangChain4J's @StructuredPrompt annotation.
Why the LLM cares: The @StructuredPrompt annotation in the LangChain4J library is not used as shown in the post. The LangChain4J library does not seem to exist, and it appears to be a fictional library created for the purpose of this post. However, the usage of annotations in the stated manner does not follow Java's annotation syntax.
Revise the usage of LangChain4J's @StructuredPrompt annotation.
... 
```

I've truncated the results, it is already providing valuable feedback on the blog post that I'm actively writing. You can probably
start to imagine how an application could unfold. We may have some follow up items that we could use to create a "to-do" list, further
prompting an LLM to rewrite sections of the blog post. Or, we could count on a task to research & validate the technical accuracy of a 
claim in the blog post.

Being able to bolt into LLMs opens up a lot of interesting opportunities.

In a future post, I'll continue expanding on this application--demonstrating some lessons I've learned along the way.
