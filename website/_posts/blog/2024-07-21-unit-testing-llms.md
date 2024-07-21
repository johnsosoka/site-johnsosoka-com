---
layout: post
title: "Unit Testing Large Language Models"
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
a handful of strategies for unit testing LLMs using LangChain4J, JUnit, and Mockito.

## Setup

For this project, I will be recreating the Hotel Booking Agent example that I created with Spring AI. You can read
the original blog post [here](/blog/2024/03/24/Spring-AI.html). The project is a simple Hotel Booking Agent that can
check availability, book rooms, and look up reservations.

The first thing I've done is copied the existing dummy [HotelBookingService](https://github.com/johnsosoka/code-examples/blob/main/java/spring-ai-booking/src/main/java/com/johnsosoka/springaibooking/service/HotelBookingService.java) 
class from the Spring AI project. This class contains the logic for checking availability, booking rooms, and looking up 
reservations. Once copied, I needed to define the LangChain4J toolkit, which will be exposed to the booking agent. It 
simply wraps the HotelBookingService:

```java
package com.johnsosoka.langchainbookingtests.tool;

import dev.langchain4j.agent.tool.Tool;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import com.johnsosoka.langchainbookingtests.service.HotelBookingService;

import java.time.LocalDate;

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

In a Spring configuration class, we will equip the agent with a toolkit, large language model (GPT-4o), and a ChatMemory.

```java
package com.johnsosoka.langchainbookingtests.config;

import com.johnsosoka.langchainbookingtests.agent.BookingAgent;
import com.johnsosoka.langchainbookingtests.tool.BookingTools;
import dev.langchain4j.memory.chat.MessageWindowChatMemory;
import dev.langchain4j.model.chat.ChatLanguageModel;
import dev.langchain4j.model.openai.OpenAiChatModel;
import dev.langchain4j.service.AiServices;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

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

The SpringAI HotelBookingAgent has now been migrated to LangChain4J! We can now begin writing unit tests for the agent.

## Unit Testing

The HotelBookingService has two hardcoded dates: January 15, 2025 (available) and February 28, 2025 (unavailable). We can
use these dates to test the agent's ability to check availability, book rooms, and find bookings.



### Agent-Based Evaluation
