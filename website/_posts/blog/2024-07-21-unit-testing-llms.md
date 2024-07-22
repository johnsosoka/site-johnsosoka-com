---
layout: post
title: "Unit Testing Large Language Models: Agent-Based Evaluation with LangChain4J"
category: blog
tags: java langchain4j testing unit-testing junit mockito large-language-models llm
---

Unit tests are a critical part of enterprise software development. Not only do unit tests help validate the expected
behavior of the code, but they also serve as a form of documentation and give developers the confidence to refactor
and contribute to the codebase. I have worked on software projects lacking unit tests, and have seen the negative
impact on developer confidence & productivity.

Testing Large Language Models (LLMs) is a unique challenge. Particularly because of the non-deterministic nature of 
these models. It isn't always as simple as asserting that the output of a function is equal to an expected value as 
there can be many ways for an LLM to potentially phrase a correct answer. In today's post, I will be walking through 
a handful of strategies for unit testing LLMs _with_ LLMs. We will start simple, and then build our way up to
an LLM-Driven QA Agent, which can generate its own test cases & use them to evaluate the target agent's performance.

## Setup

For this project, I will be recreating the Hotel Booking Agent example that I created with Spring AI. You can read
the original blog post [here](/blog/2024/03/24/Spring-AI.html). The project is a simple Hotel Booking Agent that can
check availability, book rooms, and look up reservations.

The first thing I've done is copied the existing dummy [HotelBookingService](https://github.com/johnsosoka/code-examples/blob/main/java/spring-ai-booking/src/main/java/com/johnsosoka/springaibooking/service/HotelBookingService.java) 
class from the Spring AI project. This class contains the logic for checking availability, booking rooms, and looking up 
reservations. Once copied, I needed to define the LangChain4J toolkit, which will be exposed to the booking agent. It 
simply wraps the HotelBookingService:

```java
@Component
@RequiredArgsConstructor
public class BookingTools {

    private final HotelBookingService hotelBookingService;


    @Tool("Check Availability -- Useful for seeing if a room is available for a given date.")
    public boolean checkAvailability(String date) {
        LocalDate parsedDate = LocalDate.parse(date);
        return hotelBookingService.isAvailable(parsedDate);
    }

    @Tool("Book Room -- Useful for booking a room for a given guest name, check-in date, and check-out date.")
    public String bookRoom(String guestName, String checkInDate, String checkOutDate) {
        LocalDate checkIn = LocalDate.parse(checkInDate);
        LocalDate checkOut = LocalDate.parse(checkOutDate);
        return hotelBookingService.bookRoom(guestName, checkIn, checkOut);
    }

    @Tool("Find Booking -- Useful for finding a booking by guest name.")
    public String findBooking(String guestName) {
        return hotelBookingService.findBookingByGuestNameStr(guestName);
    }

}
```
<br>
Next up, I'll define the LangChain4J agent. This class will define the role of the agent, as well as an entrypoint to
interface with the LLM.

```java
package com.johnsosoka.langchainbookingtests.agent;

import dev.langchain4j.service.SystemMessage;

public interface BookingAgent {

    @SystemMessage({
            "You are a booking agent for an online hotel. You are here to help customers book rooms and check ",
            "availability. Use the tools you have access to in order to help customers with their requests. You can ",
            "check availability, book rooms, and find bookings."
    })
    String chat(String message);
}

```
<br>
In a Spring configuration class, we will equip the agent with a toolkit, large language model (GPT-4o), and a ChatMemory.

```java
@Configuration
public class BookingAgentConfig {

    @Value("${openai.api-key}")
    String apiKey;

    @Bean
    public ChatLanguageModel chatLanguageModel() {
        return OpenAiChatModel.builder()
                .apiKey(apiKey)
                .build();
    }

    @Bean
    public BookingAgent bookingAgent(BookingTools bookingTools, ChatLanguageModel chatLanguageModel) {
        return AiServices.builder(BookingAgent.class)
                .chatLanguageModel(chatLanguageModel)
                .tools(bookingTools)
                .chatMemory(MessageWindowChatMemory.withMaxMessages(50))
                .build();
    }

}
```
<br>
Finally, I will create an additional service class that will be used to interact with the agent. Remember, we're just
setting up a dummy application so that we have something to test--This is not a production-ready application.

```java
package com.johnsosoka.langchainbookingtests.service;

import com.johnsosoka.langchainbookingtests.agent.BookingAgent;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final BookingAgent bookingAgent;

    public String chat(String message) {
        return bookingAgent.chat(message);
    }

}
```
<br>
The SpringAI HotelBookingAgent has now been migrated to LangChain4J! We can now begin writing unit tests for the agent.

## Unit Testing

The HotelBookingService has two hardcoded dates: January 15, 2025 (available) and February 28, 2025 (unavailable). We can
use these dates to test the agent's ability to check availability, book rooms, and find bookings.

To begin, I'll set up an integration test for the ChatService, and evaluate the response using `contains` to assert that
the agent's response contains the expected output.

```java
@SpringBootTest
@Slf4j
class ChatServiceTestIT {

    @Autowired
    private ChatService chatService;

    @Test
    public void checkAvailability() {
        String response = chatService.chat("Is the hotel available on 2022-12-12?");
        log.info("Response: {}", response);
        assertTrue(response.contains("not available"));
    }
}
```
<br>
When this test executes, the agent will respond with a message indicating that the hotel is not available on the given date.
Here are sample outputs from three different execution runs of the test:

```commandline
Response: The hotel is not available on 2022-12-12. Would you like to check for other dates or make a 
booking for different dates?
```
<br>
```commandline
Response: The hotel is not available on 2022-12-12. Would you like to check for alternative dates or 
make a booking for a different date?
```
<br>
```commandline
Response: I'm sorry, but the hotel is not available on 2022-12-12. Is there another date you would 
like to check for availability?
```
<br>
You can see that the agent's response can vary slightly, due to the non-deterministic nature of the language model. While we 
could potentially assert that the response contains the words "not available," this would be a brittle test. Instead, we can
use a more robust approach by creating an LLM Evaluator agent.

### Simple Agent-Based Evaluation

We can use an agent-based approach to evaluate the agent's responses. This approach involves creating an agent that can 
be tasked with evaluating the responses of another agent. The evaluator agent will be provided with the conditions that
the response must meet as well as the response itself to evaluate.

Let's first define the `TestEvaluationAgent` interface:

```java
public interface TestEvaluationAgent {

    @SystemMessage({
            "You purpose is to evaluate the results of a test. You will be employed in a unit testing environment, ",
            "and must critically evaluate the provided conditions and results to determine if the test has passed or ",
            "failed. Consider a passing test True, and a failing test False."
    })
    @UserMessage({
            "Evaluate the following:\n",
            "Condition: {{condition}}\n",
            "-----\n",
            "Results: {{result}}",
    })
    public Boolean evaluate(@V("condition") String condition, @V("result") String result);
}
```
<br>
In the above, you can see how we're defining the "profile" or "role" of the `TestEvaluationAgent`. The `@SystemMessage`
annotation clearly explains to the LLM what its purpose is. The `@UserMessage` annotation provides a template for the
agent to use when evaluating the results.

For a quick test, let's wire up this agent to evaluate the response of the `ChatService` test we wrote earlier:

```java
...
    @Autowired
    private ChatLanguageModel chatLanguageModel;

    private TestEvaluationAgent testEvaluationAgent;

    @BeforeEach
    public void setUp(){
        testEvaluationAgent = provisionEvaluationAgent();
    }

    @Test
    public void checkAvailability_withTestEvaluationAgent() {
        String response = chatService.chat("Is the hotel available on 2025-02-28?");
        log.info("Response: {}", response);

        String condition = "It should be determined that there are no hotel rooms available on 2025-02-28";
        Boolean evaluationResult = testEvaluationAgent.evaluate(condition, response);
        assertTrue(evaluationResult);
    }


    private TestEvaluationAgent provisionEvaluationAgent() {
        return AiServices.builder(TestEvaluationAgent.class)
                .chatLanguageModel(chatLanguageModel)
                .chatMemory(MessageWindowChatMemory.withMaxMessages(10))
                .build();
    }
...
```
<br>
The above test will pass the response of the `BookingAgent` to the `TestEvaluationAgent` along with the conditions of 
satisfaction for evaluation. The `TestEvaluationAgent` will then evaluate the response and return a boolean value, True
if the response meets the conditions, and False if it does not.

You may have noticed that the `TestEvaluationAgent` is provisioned using the existing `ChatLanguageModel` defined in the
Spring configuration from earlier. It is worth noting that developers are not limited to re-using models. There are new
fine-tuned models being released frequently that may be better suited for specific tasks like hallucination detection or
critiquing.

### Multi-Pass Agent Evaluation

Our `TestEvaluationAgent` is also subject to the non-deterministic nature of the language model. To mitigate this, we can
use a multi-pass evaluation strategy. This strategy will involve evaluating the result multiple times and taking the
majority vote as the final result.

Below is a simple implementation of the multi-pass evaluation strategy:

```java
@Builder
@Slf4j
public class MultiPassEvaluator {

    private TestEvaluationAgent testEvaluationAgent;
    // The total number of times to evaluate the result
    private Integer passCount;

    public Boolean evaluate(String condition, String result) {
        Boolean evaluationResult = false;
        int successCount = 0;
        for (int i = 0; i < passCount; i++) {
            boolean evaluation = testEvaluationAgent.evaluate(condition, result);
            if (evaluation) {
                successCount++;
                log.info("Evaluation {} passed", i);
            } else {
                log.info("Evaluation {} failed", i);
            }
        }
        // If more than half of the evaluations are successful, then the test is considered successful
        return successCount >= passCount / 2;
    }

}
```
<br>
I'll wire this up to another test:

```java
...
@BeforeEach
public void setUp(){
    testEvaluationAgent = provisionEvaluationAgent();
    multiPassEvaluator = MultiPassEvaluator.builder()
            .testEvaluationAgent(testEvaluationAgent)
            .passCount(3)
            .build();
}

@Test
public void checkAvailability_withMultiPassEvaluator() {
    String response = chatService.chat("Is the hotel available on 2025-02-28?");
    log.info("Response: {}", response);

    String condition = "It should be determined that there are no hotel rooms available on 2025-02-28";
    Boolean evaluationResult = multiPassEvaluator.evaluate(condition, response);
    assertTrue(evaluationResult);
}
...
```
<br>
Here is the output from a test run:

```commandline
2024-07-21T17:05:35.367-06:00  INFO c.j.l.service.ChatServiceTestIT          : Response: The hotel is not available on 2025-02-28. If you would like to check availability for another date or have any other requests, please let me know!
2024-07-21T17:05:35.925-06:00  INFO c.j.l.helper.MultiPassEvaluator          : Evaluation 0 failed
2024-07-21T17:05:36.430-06:00  INFO c.j.l.helper.MultiPassEvaluator          : Evaluation 1 passed
2024-07-21T17:05:36.829-06:00  INFO c.j.l.helper.MultiPassEvaluator          : Evaluation 2 passed
```
<br>

Interestingly enough, the evaluation failed on the first pass, but passed on the subsequent two passes. This is largely 
why we use a multi-pass evaluation strategy. It helps to mitigate the non-deterministic nature of the LLM tasked with
evaluating the results.

### Agentic Evaluation (QA Simulation)

The final strategy that I'll cover in this article is Agentic Evaluation. In this scenario, we're going to build something
of a QA Engineer. We will continue utilizing an LLM to evaluate our `BookingAgent` LLM, which is exposed via the `ChatService`.
This Agent will be provided a description for the expected behavior of the system, and it will both generate a test plan
and execute on that plan.

The QA Agent will be able to interact with the `BookingAgent` by exposing it as a `@Tool` to the QA agent. The QA Agent
will then be able to chat with the `BookingAgent` like a customer would.

First, we'll wrap the `ChatService` in a `BookingAgentTool`:

```java
@Component
@RequiredArgsConstructor
@Slf4j
public class BookingAgentTool {

    private final ChatService chatService;

    @Tool("Interact with the Booking Agent -- Useful for testing the Booking Agent system")
    public String interactWithBookingAgent(String message) {
        log.info("QA Agent Message: {}", message);
        String response = chatService.chat(message);
        log.info("Booking Agent Response: {}", response);
        return response;
    }

}
```
<br>

Next, we will construct an `AiService` definition with several methods. We will define:

- A method to generate a test plan
- A method to execute the test plan
- A method to evaluate the test results

```java
public interface QATesterAgent {

    @SystemMessage({
            "You are a world class QA engineer, your job is to test the system and ensure that it is working as expected.",
            "You will be provided with a test plan, and it is your job to execute each test case individually and determine",
            "if the system is working as expected.",
            "You will act as a customer interacting with a chatbot system to test the system's behavior.",
    })
    public String test(String testCases);

    @SystemMessage({
            "You are a world class QA engineer, your job is to test the system and ensure that it is working as expected.",
            "You will be provided with an explanation of the System's behavior and you must carefully write test cases to",
            "ensure that the system meets the expected behavior. Your test cases should be a detailed description for usage",
            "by a different language model.",
            "The System being tested is another Large Language Model, so the inputs and expected outputs can be in natural language.",
            "Account for this possible variability in the rigidity of evaluation criteria."
    })
    @UserMessage({
            "Write test cases for the following system behavior:\n",
            "System Behavior: {{systemBehavior}}\n"
    })
    public String writeTestCases(@V("systemBehavior") String systemBehavior);

    @SystemMessage({
            "You must carefully evaluate the results of the test plan to determine if the system is working as expected.",
            "In the event of any failures, the result should be false. Otherwise, the result should be true."
    })
    @UserMessage("Evaluate the following test execution results: {{it}}")
    public Boolean evaluateResults(String testResults);

}
```
<br>

Finally, we will create an `AgenticQA` class which will handle the flow-control of the QA Agent:

```java
@RequiredArgsConstructor
@Slf4j
public class AgenticQA {

    private final QATesterAgent qaTesterAgent;

    /**
     * Generate and execute a test plan for a given System Description.
     * If the QATesterAgent supplied is equipped with the appropriate tools, it will generate a test plan,
     * execute the test plan, and evaluate the results. It is intended for usage against an LLM-Driven Agent.
     * @param systemDescription
     * @return
     */
    public TestPlanResult generateAndExecuteTestPlan(String systemDescription) {
        String testCases = qaTesterAgent.writeTestCases(systemDescription);
        String testPlanResults = qaTesterAgent.test(testCases);
        Boolean testPlanResult = qaTesterAgent.evaluateResults(testPlanResults);
        return TestPlanResult.builder()
                .testPlan(testCases)
                .testPlanResults(testPlanResults)
                .allTestsPassed(testPlanResult)
                .build();
    }
}
```
<br>

I've created helper methods to provision the `QATesterAgent` and `AgenticQA` class, you can view this in the complete example
on my GitHub. The important part is seeing this added to the test:

```java
    @Test
    public void testPlanCreationTest() {
        String systemDescription = """
                The system is a simple hotel booking agent. The agent should have the ability to:
                - Check the availability of a hotel room for a given date
                - Book a hotel room for a guest (check in & check out date required)
                - Lookup a booking by guest name
                
                The system has the following preconditions:
                - The system has a hotel with 1 room available on 2025-01-15
                - The system has a hotel with 0 rooms available on 2025-02-28
                - All other dates should be considered unavailable
                """;

        TestPlanResult testPlanResult = agenticQA.generateAndExecuteTestPlan(systemDescription);
        log.info("Test Plan: \n{}", testPlanResult.getTestPlan());
        log.info("Test Plan Results: \n{}", testPlanResult.getTestPlanResults());
        assertTrue(testPlanResult.getAllTestsPassed());
    }
```
<br>
You can see that we're describing the capabilities of the system that's going to be evaluated. Remember, we're equipping
the `QATesterAgent` with a tool that allows it to interact with the `BookingAgent` via the `ChatService`. Below is the 
conversation between the QA Agent and the Booking Agent:

```commandline
QA Agent Message - Check availability for 2025-01-15
Booking Agent Response - There is availability for a room on January 15, 2025. Would you like to proceed with a booking? If so, please provide the guest name, check-in date, and check-out date.
QA Agent Message - Check availability for 2025-02-28
Booking Agent Response - Unfortunately, there is no availability for a room on February 28, 2025. Would you like me to check another date or assist you with anything else?
QA Agent Message - Check availability for 2025-03-10
Booking Agent Response - There is no availability for a room on March 10, 2025. Would you like me to check another date or help with something else?
QA Agent Message - Book a room for John Doe from 2025-01-15 to 2025-01-16
Booking Agent Response - The room has been successfully booked for John Doe from January 15, 2025, to January 16, 2025. If there's anything else you need assistance with, please let me know!
QA Agent Message - Book a room for Jane Smith from 2025-02-28 to 2025-03-01
Booking Agent Response - There is no availability on February 28, 2025, so I'm unable to book a room for Jane Smith on those dates. Would you like me to check dates around that period or assist you with something else?
QA Agent Message - Book a room for Alice Brown from 2025-03-10 to 2025-03-11
Booking Agent Response - There is no availability on March 10, 2025, so I'm unable to book a room for Alice Brown on those dates. Would you like me to check dates around that period or assist you with something else?
QA Agent Message - Lookup booking for John Doe
Booking Agent Response - I found a booking for John Doe with the following details:
- **Check-in Date:** January 15, 2025
- **Check-out Date:** January 16, 2025

Is there anything else you need assistance with?
QA Agent Message - Lookup booking for Jane Smith
Booking Agent Response - There is no booking found for Jane Smith. If you need help with something else or would like to make a new booking, please let me know!
QA Agent Message - Book a room for Mark Taylor from 2025-01-16 to 2025-01-15
Booking Agent Response - It looks like the check-out date is before the check-in date. Please provide the correct check-in and check-out dates so I can proceed with the booking for Mark Taylor.
QA Agent Message - Book a room for Emily Davis on 2025-01-15
Booking Agent Response - Could you please provide the check-out date for Emily Davis's booking on January 15, 2025, so I can proceed with the reservation?
```
<br>

This is pretty interesting stuff, the QA Agent is able to generate a test plan & interact with the booking agent to execute
on that plan. The abridged version of the plan generated for the above execution run was:
Certainly! Here are the test case titles extracted into a list:

1. Check availability for a date with available rooms
2. Check availability for a date with no available rooms
3. Check availability for a date not listed in preconditions
4. Book a room for a guest with available dates
5. Book a room for a guest with no available rooms
6. Book a room for a guest with dates not listed in preconditions
7. Lookup a booking by guest name that exists
8. Lookup a booking by guest name that does not exist
9. Book a room for a guest with check-out date before check-in date
10. Book a room for a guest with check-in and check-out date being the same

## Conclusion

Testing Large Language Models is a new and unique challenge. I'm really excited to see what other ideas the industry comes 
up with in the future. We covered quite a bit of ground today, starting with a simple unit test using `contains` and working 
our way to a fully functional QA Agent capable of generating test plans and executing on them. Hopefully this article has
given you some ideas on how to test your own LLM applications. This was a very interesting  project to work on, and I hope you 
found it as interesting as I did. Watching the two agents interact with each other was thrilling, and being able to use a junit 
assertion to evaluate the results was the cherry on top.

Happy coding!