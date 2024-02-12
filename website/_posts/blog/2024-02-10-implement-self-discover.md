---
layout: post
title: "Implementing the SELF-DISCOVER Algorithm in Java Spring with LangChain4J"
category: blog
tags: LLM LangChain LangChain4J java spring research SELF-DISCOVER algorithm google deepmind orchestration agent ai
---

Google's DeepMind project recently published ["SELF-DISCOVER: Large Language Models Self-Compose Reasoning Structures"](https://arxiv.org/pdf/2402.03620.pdf) 
The paper proposes "a general framework for LLMs to self-discover the task-intrinsic reasoning structures to tackle complex 
reasoning problems." After reading the paper it was clear that the algorithm would be pretty easy to implement, especially 
with the help of [LangChain4J](https://github.com/langchain4j/langchain4j), which is an LLM Integration framework that I've
been heavily working with.

## Understanding the Algorithm

The algorithm is broken into two phases: Composition and Solving. The composition phase is further broken into three steps:

1. **Select:** The LLM is provided a `task` and a list of `reasoning modules` and is asked to select the most appropriate 
reasoning modules to solve the task.
2. **Adapt:** The LLM is provided the _selected_ `reasoning modules` and the task. It is asked to adapt the selected reasoning
modules to the task.
3. **Implement:** The LLM is provided the _adapted_ `reasoning modules` The adapted reasoning modules are transformed into 
a step-by-step task specific reasoning structure.

![SELF-DISCOVER](https://media.johnsosoka.com/blog/2024-02-11/self-discover.png)

_(image from [SELF-DISCOVER](https://arxiv.org/pdf/2402.03620.pdf) paper)_

Pictured above is a visualization of the composition phase of SELF-DISCOVER. The second phase is rather straightforward, 
the LLM is simply handed the reasoning structure from the output of the composition phase and asked to solve the task.

You may have noticed from the graphic that the SELECT phase appears to require "Seed Modules." Luckily, the authors of the
paper have provided a bank of pre-existing reasoning modules that the LLM can select from, you can find them on Page 13, Table 2.

## Implementation

Now that we have established how the algorithm works (and where to find a starter-bank of reasoning modules), we are ready to
implement! You can find the full implementation on my [GitHub](https://github.com/johnsosoka/self-discover). I'm going to
cover the highlights here.

### Dependencies, LangChain4J

The LangChain4J library has proven to be a valuable tool for integrating LLMs into Java applications. This library is far
more stable than the official Python LangChain4J. Below are the 3 LangChain4J dependencies that I used for this project:

**pom.xml**
```xml
       <!-- LLM Integration -->
        <dependency>
            <groupId>dev.langchain4j</groupId>
            <artifactId>langchain4j</artifactId>
            <version>${langchain4j.version}</version>
        </dependency>

        <dependency>
            <groupId>dev.langchain4j</groupId>
            <artifactId>langchain4j-open-ai-spring-boot-starter</artifactId>
            <version>${langchain4j.version}</version>
        </dependency>

        <dependency>
            <groupId>dev.langchain4j</groupId>
            <artifactId>langchain4j-embeddings-all-minilm-l6-v2</artifactId>
            <version>${langchain4j.version}</version>
        </dependency>
```

### Reasoning Modules

The paper provides a bank of "reasoning modules" which are really just a list of adapted strategies for solving problems.
As the reasoning bank is just a list of strings, I opted to configure them in the `application.yml` and create a 
corresponding spring `@ConfigurationProperties` class to load them into the application.

Below is a _snippet_ of the `application.yml`. Reviewing some of the entries in the reasoning bank may provide a clearer 
view into how the algorithm works.

**application.yml**
```yaml
openai:
  api-key: ${OPENAI_API_KEY}

reasoning:
  modules:
    - How could I devise an experiment to help solve that problem?
    - Make a list of ideas for solving this problem, and apply them one by one to the problem to see if any progress can be made.
    - How could I measure progress on this problem?
    - How can I simplify the problem so that it is easier to solve?
    - What are the key assumptions underlying this problem?
    - What are the potential risks and drawbacks of each solution?
```

As promised, the corresponding Configuration class:

```java
@Configuration
@ConfigurationProperties(prefix = "reasoning")
public class ReasoningModuleConfig {

    private List<String> modules;

    public List<String> getReasoningModules() {
        return modules;
    }

    public void setModules(List<String> modules) {
        this.modules = modules;
    }

}
```

When the application starts, the `ReasoningModuleConfig` class will be populated with the reasoning modules from the
`application.yml` file that we defined. This also makes it easy to extend the reasoning bank in the future.

### LangChain AIService SELF-DISCOVERY Interface

What a mouthful! The `AIService` is a LangChain4J construct. We can define an interface, utilize some special LangChain4J
annotations to help guide behavior, and then via the AIService.builder() method, we can pass a LanguageModel (openAI in this case)
and create an `AIService`. These `AIServices` can also be equipped with tools, chat memory, and other features.

I define a method for each step in the SELF-DISCOVER algorithm.

#### Select

Below is a snippet of the `SelfDiscovery` interface. The `@UserMessage` annotation guides the LLM on how to respond to the 
prompt. The `@V` annotations are used by LangChain4J to map the variables in the prompt to the method parameters. As 
described by the paper, the 1st step is to select reasoning modules that will help solve a given task.

```java
public interface SelfDiscovery {

    /**
     * Selects reasoning modules that will help solve a task.
     * @param task
     * @param allReasoningModules
     * @return
     */
    @UserMessage({
            "Select several reasoning modules that are crucial to utilize in order to solve the given task.",
            "Do not explain your reasoning, simply list the reasoning modules that you select.",

            "GIVEN TASK:",
            "{{task}}",
            "---",
            "AVAILABLE REASONING MODULES:",
            "{{allReasoningModules}}",
    })
    public String selectModules(@V("task") String task,
                                      @V("allReasoningModules") List<String> allReasoningModules);
...
```

It is worth noting as this time that `@UserMessage` appears to be the only annotation in the LangChain4J frameowrk capable 
of handling multiple variables. 

#### Adapt

The next step is to adapt the selected reasoning modules to the given task. This is done by providing the LLM with the selected
modules and requesting that it adapt them to the task.

```java
...
    /**
     * Adapts each reasoning module to better help solve the task.
     * @return
     */
    @UserMessage({
            "Rephrase and specify each reasoning module so that it better helps solving the task:",
            "Do not explain your reasoning or solve the task, simply adapt each selected reasoning module to better help solve the task.",

            "GIVEN TASK:",
            "{{task}}",
            "---",
            "SELECTED REASONING MODULES:",
            "{{selectedReasoningModules}}",
    })
    public String adaptModules(@V("task") String task,
                                     @V("selectedReasoningModules") String selectedReasoningModules);
...
```
The output of this method will be a list of adapted reasoning modules that are better suited to solving the task.

#### Implement

The final step in the compoisition phase is to implement the adapted reasoning modules into a step-by-step reasoning structure.
The paper provided some hints at the prompt for this step,

```java
...
    /**
     * Implement a reasoning structure for solvers to follow step-by-step to arrive at a correct solution.
     * @return
     */
    @UserMessage({
            "Transform the reasoning modules into a step-by-step reasoning plan in JSON format.",
            "Do not explain your reasoning or solve the task, simply create an actionable reasoning plan",
            "for solvers solve using these adapted reasoning modules..",

            "GIVEN TASK:",
            "{{task}}",
            "---",
            "ADAPTED REASONING MODULES:",
            "{{adaptedReasoningModules}}",
    })
    public String implement(@V("task") String task,
                            @V("adaptedReasoningModules") String adaptedReasoningModules);
...
```

When this final method escapes, there should be a JSON formatted reasoning plan that can be used to solve the task. This
reasoning plan can be passed to other LLMs along with the task to solve the problem. It is worth noting that the authors
of the SELF-DISCOVER method experimented with the portability of these derived reasoning structures. That is, they could 
have one LLM compose the reasoning structure and then pass it to another LLM to solve the task and still achieve an 
improvement in performance.

### All Together Now

Now that we have defined the essential components of the SELF-DISCOVER algorithm, we can put them all together and take 
this for a spin. I'll create a `ReasoningService` class that will orchestrate the composition and solving of tasks.

**ReasoningService.java**

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class ReasoningService {

    private final ReasoningModuleConfig reasoningModuleConfig;
    private final SelfDiscovery selfDiscovery;
    private final Solving solving;

...
```

The reasoning service is a Spring `@Service` that is injected with the `ReasoningModuleConfig`,`SelfDiscovery` and `Solving` AIServices.
The `SelfDiscovery` and `Solving` AIServices are interfaces that we defined earlier, together they represent both phases of the SELF-DISCOVER algorithm.
By the way, if you're curious about how these are initialized check out [this snippet](https://github.com/johnsosoka/self-discover/blob/main/src/main/java/com/johnsosoka/selfdiscover/config/SelfDiscoveryAgentConfig.java)

Here is the snippet that demonstrates the composition of the reasoning structure:

```java
    /**
     * Orchestrates the SelfDiscover AIService, which contains prompts that implement the SELF-DISCOVER algorithm.
     * The `SelfDiscover` AIService composes task-specific reasoning structures for solvers to follow step-by-step to arrive at a solution.
     * @param task
     * @return Reasoning structure composed by the SelfDiscover AIService
     */
    public String composeReasoningStructure(String task) {
        log.info("Composing reasoning structure for task: {}", task);
        String selectedReasoningModules = selfDiscovery.selectModules(task, reasoningModuleConfig.getReasoningModules());
        log.info("Selected reasoning modules: {}", selectedReasoningModules);
        String adaptedReasoningModules = selfDiscovery.adaptModules(task, selectedReasoningModules);
        log.info("Adapted reasoning modules: {}", adaptedReasoningModules);
    
        // Operationalize the reasoning modules into a step-by-step reasoning plan
        String reasoningPlan = selfDiscovery.implement(task, adaptedReasoningModules);
        log.info("Reasoning plan: {}", reasoningPlan);
    
        return reasoningPlan;
    }
```

And finally, here is the snippet that demonstrates the solving of the task using the reasoning structure:

```java
    ...
    /**
     * Using the self-composed reasoning structure, solve the given task.
     * @param task
     * @param composedReasoningStructure
     * @return
     */
    public String solveTask(String task, String composedReasoningStructure) {
        // This response contains the answer and likely some other information
        String reasonedAnswer = solving.solveTask(task, composedReasoningStructure);
        // Extract the answer from the reasoned solution
        return solving.extractAnswer(reasonedAnswer);
    }
...
```

If you want to see the full implementation, you can find it on my [GitHub](https://github.com/johnsosoka/self-discover)
To easily see the algorithm in action, I've created a set of tests that demonstrate the algorithm in action. You can find 
them [here](https://github.com/johnsosoka/self-discover/blob/main/src/test/java/com/johnsosoka/selfdiscover/service/ReasoningServiceTests.java)

## The Bigger Picture

Anecdotally, one of the patterns emerging in LLM dev & agent design world is that specialization and focused operations 
are key to achieving high performance. 

It is a common pattern to have a delegator or orchestrator Agent in the system that is responsible for breaking down a 
problem into smaller tasks that are then delegated to specialized worker agents to execute.

Having a new algorithm like SELF-DISCOVER available may be a game changer for the `Planning` module orchestration agents.

To read more about modules and agent design, check out [this paper](https://arxiv.org/pdf/2308.11432.pdf )

## Conclusion

I hope that this blog has helped make the SELF-DISCOVER algorithm more accessible. I'm excited to refine this implementation
and then try it out in a real-world application. More than likely, I'll be using it as part of a  `Planning` module for 
orchestration agent.

If you have any questions or comments, feel free to reach out to me on [Linkedin](https://www.linkedin.com/in/john-sosoka-4528b970/)

